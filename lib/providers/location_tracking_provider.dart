import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/session_status.dart';
import '../models/turf_loop.dart';
import '../models/claimed_loop.dart';
import '../models/walk_session_summary.dart';
import '../models/local_walk_session.dart';
import '../models/local_claimed_loop.dart';
import '../repositories/claimed_loop_repository.dart';
import '../repositories/history_repository.dart';
import '../repositories/isar_service.dart';
import '../location/loop_detector.dart';
import 'tracking_metrics_provider.dart';

class LocationTrackingProvider extends ChangeNotifier {
  final TrackingMetricsProvider metricsProvider;
  
  final ClaimedLoopRepository _claimedLoopRepo = ClaimedLoopRepository();
  final HistoryRepository _historyRepo = HistoryRepository();

  // Active session tracking variables
  List<LatLng> _trailPoints = [];
  List<TurfLoop> _capturedLoops = [];
  bool _gpsSignalWeak = false;
  double _bearing = 0.0;
  Color? _activeTrailColor;

  List<LatLng> get trailPoints => _trailPoints;
  List<TurfLoop> get capturedLoops => _capturedLoops;
  bool get gpsSignalWeak => _gpsSignalWeak;
  double get bearing => _bearing;
  Color? get activeTrailColor => _activeTrailColor;

  // Local lists for quick checks
  List<ClaimedLoop> _cachedClaimedLoops = [];
  List<ClaimedLoop> get cachedClaimedLoops => _cachedClaimedLoops;

  // Stream controllers for Loop captured events to prompt name entry in UI
  final StreamController<TurfLoop> _loopCapturedEventController = StreamController<TurfLoop>.broadcast();
  Stream<TurfLoop> get loopCapturedEvents => _loopCapturedEventController.stream;

  final StreamController<ClaimedLoop> _claimedLoopCoveredEventController = StreamController<ClaimedLoop>.broadcast();
  Stream<ClaimedLoop> get claimedLoopCoveredEvents => _claimedLoopCoveredEventController.stream;

  // Service event subscriptions
  StreamSubscription? _serviceSubscription;
  StreamSubscription? _loopCapturedSub;
  StreamSubscription? _loopCoveredSub;
  StreamSubscription? _gpsStatusSub;
  StreamSubscription? _spoofSub;
  StreamSubscription? _isarClaimsSubscription;

  LocationTrackingProvider({required this.metricsProvider}) {
    _loadClaimedLoops();
    _checkActiveSessionRecovery();
    _listenToIsarClaims();
  }

  Future<void> _listenToIsarClaims() async {
    try {
      final isar = await IsarService.getDB();
      _isarClaimsSubscription = isar.localClaimedLoops.watchLazy().listen((_) {
        _loadClaimedLoops();
      });
    } catch (e) {
      print("Failed to start Isar claims watcher: $e");
    }
  }

  Future<void> _loadClaimedLoops() async {
    _cachedClaimedLoops = await _claimedLoopRepo.getClaimedLoops();
    notifyListeners();
  }

  /// Check Isar DB for any crashed or ongoing walk sessions to restore state
  Future<void> _checkActiveSessionRecovery() async {
    try {
      final isar = await IsarService.getDB();
      final activeWalk = await isar.localWalkSessions.get(99999);

      if (activeWalk != null) {
        _trailPoints = [];
        for (int i = 0; i < activeWalk.trailLatList.length; i++) {
          _trailPoints.add(LatLng(activeWalk.trailLatList[i], activeWalk.trailLngList[i]));
        }

        if (activeWalk.loopsJson.isNotEmpty) {
          try {
            final List<dynamic> decoded = jsonDecode(activeWalk.loopsJson);
            _capturedLoops = decoded.map((l) => TurfLoop.fromJson(l as Map<String, dynamic>)).toList();
          } catch (e) {
            print("Failed to restore captured loops: $e");
          }
        }

        metricsProvider.reset();
        metricsProvider.updateSteps(activeWalk.steps, activeWalk.distanceKm, activeWalk.isStepEstimated);
        metricsProvider.setLoopCount(activeWalk.loopCount);
        metricsProvider.updateTimer(activeWalk.durationSeconds, activeWalk.cadence);
        metricsProvider.updateElevationGain(activeWalk.elevationGainMetres);

        final isRunning = await FlutterBackgroundService().isRunning();
        if (isRunning) {
          metricsProvider.setSessionStatus(SessionStatus.active);
          _connectToBackgroundService();
        } else {
          metricsProvider.setSessionStatus(SessionStatus.paused);
        }
        notifyListeners();
      }
    } catch (e) {
      print("Active session recovery failed: $e");
    }
  }

  void _connectToBackgroundService() {
    _serviceSubscription?.cancel();
    _loopCapturedSub?.cancel();
    _loopCoveredSub?.cancel();
    _gpsStatusSub?.cancel();
    _spoofSub?.cancel();

    final service = FlutterBackgroundService();

    _serviceSubscription = service.on('update').listen((data) {
      if (data == null) return;

      final int stepsVal = data['steps'] ?? 0;
      final bool est = data['isStepEstimated'] ?? false;
      final double dist = (data['distanceKm'] as num?)?.toDouble() ?? 0.0;
      final int loopsVal = data['loopCount'] ?? 0;
      final int dur = data['durationSeconds'] ?? 0;
      final int cad = data['cadence'] ?? 0;
      final double elev = (data['elevationGainMetres'] as num?)?.toDouble() ?? 0.0;
      final double b = (data['bearing'] as num?)?.toDouble() ?? 0.0;
      final bool weak = data['gpsSignalWeak'] ?? false;

      metricsProvider.updateSteps(stepsVal, dist, est);
      metricsProvider.setLoopCount(loopsVal);
      metricsProvider.updateTimer(dur, cad);
      metricsProvider.updateElevationGain(elev);

      _gpsSignalWeak = weak;
      _bearing = b;

      final ptsList = data['trailPoints'] as List<dynamic>?;
      if (ptsList != null) {
        _trailPoints = ptsList.map((p) => LatLng(p['lat'] as double, p['lng'] as double)).toList();
      }

      final capLoopsList = data['capturedLoops'] as List<dynamic>?;
      if (capLoopsList != null) {
        _capturedLoops = capLoopsList.map((l) => TurfLoop.fromJson(l as Map<String, dynamic>)).toList();
      }

      if (_trailPoints.isNotEmpty) {
        final nearestClaimed = _getMatchingClaimedLoopForLocation(_trailPoints.last);
        _activeTrailColor = nearestClaimed?.getDynamicColor();
      }

      notifyListeners();
    });

    _loopCapturedSub = service.on('loop_captured').listen((data) {
      if (data == null) return;
      final loop = TurfLoop.fromJson(data);
      _loopCapturedEventController.add(loop);
      _triggerHapticFeedback();
    });

    _loopCoveredSub = service.on('claimed_loop_covered').listen((data) {
      if (data == null) return;
      final claim = ClaimedLoop.fromJson(data);
      _claimedLoopCoveredEventController.add(claim);
      _triggerHapticFeedback();
    });

    _gpsStatusSub = service.on('gps_status').listen((data) {
      if (data == null) return;
      _gpsSignalWeak = data['weak'] ?? false;
      notifyListeners();
    });

    _spoofSub = service.on('spoof_detected').listen((data) {
      if (data == null) return;
      final reason = data['reason'] ?? 'Spoofing detected';
      pauseWalk();
      print("Anti-Spoofing Suspended Session: $reason");
    });
  }

  /// Start a new tracking walk session
  Future<void> startWalk() async {
    if (metricsProvider.sessionStatus != SessionStatus.idle) return;

    // Reset session variables
    _trailPoints = [];
    _capturedLoops = [];
    _gpsSignalWeak = false;
    _bearing = 0.0;
    _activeTrailColor = null;

    metricsProvider.reset();
    metricsProvider.setSessionStatus(SessionStatus.active);

    await _loadClaimedLoops();

    // Create the initial active session record in Isar DB
    final isar = await IsarService.getDB();
    final activeWalk = LocalWalkSession()
      ..id = 99999
      ..sessionId = "active_session"
      ..dateTime = DateTime.now().toIso8601String()
      ..steps = 0
      ..isStepEstimated = false
      ..distanceKm = 0.0
      ..loopCount = 0
      ..durationSeconds = 0
      ..cadence = 0
      ..elevationGainMetres = 0.0
      ..trailLatList = const []
      ..trailLngList = const []
      ..loopsJson = ""
      ..isSynced = false;

    await isar.writeTxn(() async {
      await isar.localWalkSessions.put(activeWalk);
    });

    // Start background tracking service
    final service = FlutterBackgroundService();
    final isAlreadyRunning = await service.isRunning();

    if (isAlreadyRunning) {
      service.invoke('start', {'sessionId': 'active_session'});
      _connectToBackgroundService();
      notifyListeners();
    } else {
      StreamSubscription? readySubscription;
      readySubscription = service.on('service_ready').listen((_) {
        service.invoke('start', {'sessionId': 'active_session'});
        readySubscription?.cancel();
      });
      await service.startService();
      _connectToBackgroundService();
      notifyListeners();
    }
  }

  /// Pause current walk session
  void pauseWalk() {
    if (metricsProvider.sessionStatus != SessionStatus.active) return;

    metricsProvider.setSessionStatus(SessionStatus.paused);
    FlutterBackgroundService().invoke('pause');
    notifyListeners();
  }

  /// Resume paused walk session
  void resumeWalk() {
    if (metricsProvider.sessionStatus != SessionStatus.paused) return;

    metricsProvider.setSessionStatus(SessionStatus.active);
    FlutterBackgroundService().invoke('resume');
    notifyListeners();
  }

  /// End the walk session and return the final summary to be saved in history
  Future<WalkSessionSummary?> endWalk() async {
    if (metricsProvider.sessionStatus == SessionStatus.idle) return null;

    final summary = WalkSessionSummary(
      id: const Uuid().v4(),
      dateTime: _formatCurrentDateTime(),
      steps: metricsProvider.steps,
      isStepEstimated: metricsProvider.isStepEstimated,
      distanceKm: metricsProvider.distanceKm,
      loopCount: metricsProvider.loopCount,
      durationSeconds: metricsProvider.durationSeconds,
      loops: List<TurfLoop>.from(_capturedLoops),
      cadence: metricsProvider.cadence,
      elevationGainMetres: metricsProvider.elevationGainMetres,
      trailPoints: List<LatLng>.from(_trailPoints),
    );

    // Save walk summary to local repository
    await _historyRepo.addSession(summary);

    // Clean up active session record from Isar
    try {
      final isar = await IsarService.getDB();
      await isar.writeTxn(() async {
        await isar.localWalkSessions.delete(99999);
      });
    } catch (e) {
      print("Failed to delete active session record: $e");
    }

    // Stop background service
    FlutterBackgroundService().invoke('stop');

    // Cancel UI-isolate subscriptions
    _serviceSubscription?.cancel();
    _loopCapturedSub?.cancel();
    _loopCoveredSub?.cancel();
    _gpsStatusSub?.cancel();
    _spoofSub?.cancel();

    // Clear session state
    _trailPoints = [];
    _capturedLoops = [];
    _gpsSignalWeak = false;
    _bearing = 0.0;
    _activeTrailColor = null;

    metricsProvider.reset();
    metricsProvider.setSessionStatus(SessionStatus.idle);
    notifyListeners();

    return summary;
  }

  /// Assign a name to a recently captured loop and claim/rename it
  Future<void> nameLoop(String loopId, String name, {String? newLoopId}) async {
    // 1. Notify background service to update loop details in memory
    FlutterBackgroundService().invoke('name_loop', {
      'id': loopId,
      'name': name,
      if (newLoopId != null) 'newId': newLoopId,
    });

    // Update in active session captured loops list if still ongoing
    _capturedLoops = _capturedLoops.map((loop) {
      if (loop.id == loopId) {
        return loop.copyWith(
          id: newLoopId ?? loop.id,
          name: name,
        );
      }
      return loop;
    }).toList();
    notifyListeners();

    // 2. Fetch or create dynamic claim representation
    final targetId = newLoopId ?? loopId;
    final existingClaimIndex = _cachedClaimedLoops.indexWhere((l) => l.id == targetId);
    final today = ClaimedLoopRepository.getTodayDateString();

    if (existingClaimIndex != -1) {
      final updatedClaim = _cachedClaimedLoops[existingClaimIndex].copyWith(name: name);
      await _claimedLoopRepo.addOrUpdateClaimedLoop(updatedClaim);
    } else {
      final loop = _capturedLoops.firstWhere((l) => l.id == targetId);
      final newClaim = ClaimedLoop(
        id: targetId,
        name: name,
        points: loop.points,
        streakCount: 1,
        lastCoveredDate: today,
        coveredCountToday: 1,
      );
      await _claimedLoopRepo.addOrUpdateClaimedLoop(newClaim);
    }

    // Sync name change to Supabase if online
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        await client.from('loops').update({'name': name}).eq('id', targetId);
      }
    } catch (e) {
      print("Failed to sync loop rename to Supabase: $e");
    }

    await _loadClaimedLoops();
  }

  /// Abandon a claimed loop
  Future<void> abandonClaim(String loopId) async {
    await _claimedLoopRepo.deleteClaim(loopId);

    // Sync claim deletion to Supabase if online
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        await client.from('claims').delete().eq('loop_id', loopId);
      }
    } catch (e) {
      print("Failed to delete claim from Supabase: $e");
    }

    await _loadClaimedLoops();
  }

  /// Public method to manually trigger a reload of claimed loops from cache
  Future<void> loadClaimedLoops() async {
    await _loadClaimedLoops();
  }

  ClaimedLoop? _getMatchingClaimedLoopForLocation(LatLng latLng) {
    const double thresholdMetres = 25.0 * 0.3048; // 25 feet threshold = 7.62m
    for (var loop in _cachedClaimedLoops) {
      for (var point in loop.points) {
        final double dist = LoopDetector.calculateDistanceMetres(
          latLng.latitude, latLng.longitude,
          point.latitude, point.longitude,
        );
        if (dist <= thresholdMetres) {
          return loop;
        }
      }
    }
    return null;
  }

  void _triggerHapticFeedback() {
    HapticFeedback.vibrate();
  }

  String _formatCurrentDateTime() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final mStr = months[now.month - 1];
    final dStr = now.day.toString().padLeft(2, '0');
    final yStr = now.year.toString();
    final hStr = now.hour.toString().padLeft(2, '0');
    final minStr = now.minute.toString().padLeft(2, '0');
    return '$mStr $dStr, $yStr $hStr:$minStr';
  }

  @override
  void dispose() {
    _isarClaimsSubscription?.cancel();
    _serviceSubscription?.cancel();
    _loopCapturedSub?.cancel();
    _loopCoveredSub?.cancel();
    _gpsStatusSub?.cancel();
    _spoofSub?.cancel();
    _loopCapturedEventController.close();
    _claimedLoopCoveredEventController.close();
    super.dispose();
  }
}
