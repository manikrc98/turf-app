import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/session_status.dart';
import '../models/turf_loop.dart';
import '../models/claimed_loop.dart';
import '../models/walk_session_summary.dart';
import '../models/turf_session_state.dart';
import '../repositories/claimed_loop_repository.dart';
import '../repositories/history_repository.dart';
import '../sensors/step_counter_manager.dart';
import '../sensors/compass_manager.dart';
import '../location/loop_detector.dart';

class TurfSessionProvider extends ChangeNotifier {
  final ClaimedLoopRepository _claimedLoopRepo = ClaimedLoopRepository();
  final HistoryRepository _historyRepo = HistoryRepository();
  final StepCounterManager _stepCounterManager = StepCounterManager();
  final CompassManager _compassManager = CompassManager();

  TurfSessionState _state = TurfSessionState();
  TurfSessionState get state => _state;

  // Stream subscriptions
  StreamSubscription<Position>? _locationSubscription;
  Timer? _stopwatchTimer;

  // Tracking duration & time calculations
  int _startTimeMillis = 0;
  int _accumulatedTimeSeconds = 0;

  // Fallback GPS calculation variables
  Position? _lastPositionForDistance;
  double _totalGpsDistanceMetres = 0.0;

  // Elevation Gain variables
  double? _lastAltitude;
  double _totalElevationGainMetres = 0.0;

  // Local lists for quick checks
  List<ClaimedLoop> _cachedClaimedLoops = [];
  List<ClaimedLoop> get cachedClaimedLoops => _cachedClaimedLoops;

  // Stream controllers for Loop captured events to prompt name entry in UI
  final StreamController<TurfLoop> _loopCapturedEventController = StreamController<TurfLoop>.broadcast();
  Stream<TurfLoop> get loopCapturedEvents => _loopCapturedEventController.stream;

  final StreamController<ClaimedLoop> _claimedLoopCoveredEventController = StreamController<ClaimedLoop>.broadcast();
  Stream<ClaimedLoop> get claimedLoopCoveredEvents => _claimedLoopCoveredEventController.stream;

  TurfSessionProvider() {
    _loadClaimedLoops();
  }

  Future<void> _loadClaimedLoops() async {
    _cachedClaimedLoops = await _claimedLoopRepo.getClaimedLoops();
    notifyListeners();
  }

  /// Start a new tracking walk session
  Future<void> startWalk() async {
    if (_state.sessionStatus != SessionStatus.idle) return;

    // Reset session variables
    _state = TurfSessionState(sessionStatus: SessionStatus.active);
    _startTimeMillis = DateTime.now().millisecondsSinceEpoch;
    _accumulatedTimeSeconds = 0;
    _lastPositionForDistance = null;
    _totalGpsDistanceMetres = 0.0;
    _lastAltitude = null;
    _totalElevationGainMetres = 0.0;

    await _loadClaimedLoops();
    _startTracking();
    _startTimer();
    notifyListeners();
  }

  /// Pause current walk session
  void pauseWalk() {
    if (_state.sessionStatus != SessionStatus.active) return;

    _accumulatedTimeSeconds += _getSessionDurationSeconds();
    _state = _state.copyWith(sessionStatus: SessionStatus.paused);
    
    _stopTracking();
    _stopTimer();
    notifyListeners();
  }

  /// Resume paused walk session
  void resumeWalk() {
    if (_state.sessionStatus != SessionStatus.paused) return;

    _startTimeMillis = DateTime.now().millisecondsSinceEpoch;
    _state = _state.copyWith(sessionStatus: SessionStatus.active);

    _startTracking();
    _startTimer();
    notifyListeners();
  }

  /// End the walk session and return the final summary to be saved in history
  Future<WalkSessionSummary?> endWalk() async {
    if (_state.sessionStatus == SessionStatus.idle) return null;

    final int durationSeconds = _accumulatedTimeSeconds + _getSessionDurationSeconds();
    
    _stopTracking();
    _stopTimer();

    // Create session summary object
    final String formattedDate = _formatCurrentDateTime();
    final summary = WalkSessionSummary(
      id: const Uuid().v4(),
      dateTime: formattedDate,
      steps: _state.steps,
      isStepEstimated: _state.isStepEstimated,
      distanceKm: _state.distanceKm,
      loopCount: _state.loopCount,
      durationSeconds: durationSeconds,
      loops: _state.capturedLoops,
      cadence: _state.cadence,
      elevationGainMetres: _state.elevationGainMetres,
    );

    // Save walk summary to local repository
    await _historyRepo.addSession(summary);

    // Clear session state
    _state = TurfSessionState(sessionStatus: SessionStatus.idle);
    notifyListeners();

    return summary;
  }

  /// Assign a name to a recently captured loop and claim/rename it
  Future<void> nameLoop(String loopId, String name) async {
    // 1. Update in active session captured loops list if still ongoing
    final updatedCaptured = _state.capturedLoops.map((loop) {
      if (loop.id == loopId) {
        return loop.copyWith(name: name);
      }
      return loop;
    }).toList();
    _state = _state.copyWith(capturedLoops: updatedCaptured);
    notifyListeners();

    // 2. Fetch or create dynamic claim representation
    final existingClaimIndex = _cachedClaimedLoops.indexWhere((l) => l.id == loopId);
    final today = ClaimedLoopRepository.getTodayDateString();

    if (existingClaimIndex != -1) {
      final updatedClaim = _cachedClaimedLoops[existingClaimIndex].copyWith(name: name);
      await _claimedLoopRepo.addOrUpdateClaimedLoop(updatedClaim);
    } else {
      // Find loop geometry coordinates
      final loop = updatedCaptured.firstWhere((l) => l.id == loopId);
      final newClaim = ClaimedLoop(
        id: loopId,
        name: name,
        points: loop.points,
        streakCount: 1,
        lastCoveredDate: today,
        coveredCountToday: 1,
      );
      await _claimedLoopRepo.addOrUpdateClaimedLoop(newClaim);
    }

    await _loadClaimedLoops();
  }

  /// Abandon a claimed loop
  Future<void> abandonClaim(String loopId) async {
    await _claimedLoopRepo.deleteClaim(loopId);
    await _loadClaimedLoops();
  }

  void _startTracking() {
    // 1. Start Step Counter Sensor
    _stepCounterManager.start(
      (steps) {
        if (_state.sessionStatus == SessionStatus.active) {
          final double distance = StepCounterManager.calculateDistanceKm(steps);
          _state = _state.copyWith(
            steps: steps,
            isStepEstimated: false,
            distanceKm: distance,
          );
          notifyListeners();
        }
      },
      (error) {
        // Step sensor unavailable fallback is handled on location updates
        _state = _state.copyWith(isStepEstimated: true);
        notifyListeners();
      },
    );

    // 2. Start Compass Sensor for heading/bearing rotation
    _compassManager.start((heading) {
      _state = _state.copyWith(bearing: heading);
      notifyListeners();
    });

    // 3. Start Geolocator location updates
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 5 metres displacement triggers callback
    );
    _locationSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _handleLocationUpdate(position);
      },
      onError: (err) {
        print("Geolocator stream error: $err");
      },
    );
  }

  void _stopTracking() {
    _stepCounterManager.stop();
    _compassManager.stop();
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _handleLocationUpdate(Position position) {
    final bool isWeak = position.accuracy > 20.0;
    _state = _state.copyWith(gpsSignalWeak: isWeak);
    notifyListeners();

    if (isWeak) {
      // Weak GPS - pause trail collection to avoid drawing erratic points
      return;
    }

    final newLatLng = LatLng(position.latitude, position.longitude);
    final double currentBearing = position.heading;

    // Track Altitude / Elevation Gain
    if (position.altitude != 0.0) {
      final double currentAltitude = position.altitude;
      if (_lastAltitude != null) {
        final double diff = currentAltitude - _lastAltitude!;
        if (diff > 1.5) { // Filter minor variations (< 1.5m)
          _totalElevationGainMetres += diff;
        }
      }
      _lastAltitude = currentAltitude;
    }

    // Step/distance fallback estimation if sensor is not available
    int steps = _state.steps;
    double distanceKm = _state.distanceKm;
    bool isStepEstimated = _state.isStepEstimated;

    if (!_stepCounterManager.isSensorAvailable) {
      if (_lastPositionForDistance != null) {
        final double distanceDelta = Geolocator.distanceBetween(
          _lastPositionForDistance!.latitude, _lastPositionForDistance!.longitude,
          position.latitude, position.longitude,
        );
        _totalGpsDistanceMetres += distanceDelta;
        distanceKm = _totalGpsDistanceMetres / 1000.0;
        steps = StepCounterManager.estimateSteps(distanceKm);
        isStepEstimated = true;
      }
      _lastPositionForDistance = position;
    }

    // Calculate active trail color based on proximity to any claimed loop
    final nearestClaimed = _getMatchingClaimedLoopForLocation(newLatLng);
    final Color? trailColor = nearestClaimed?.getDynamicColor();

    // Add point to trail path
    final List<LatLng> updatedTrail = List<LatLng>.from(_state.trailPoints)..add(newLatLng);

    // Check loop closure mathematical logic
    if (LoopDetector.isLoopClosed(updatedTrail)) {
      _triggerHapticFeedback();
      final newLoop = TurfLoop(points: updatedTrail);

      // Check if closing loop matches any claimed loops to trigger streak increment
      final matchingClaimed = _getMatchingClaimedLoopForNewLoop(updatedTrail);
      
      if (matchingClaimed != null) {
        final today = ClaimedLoopRepository.getTodayDateString();
        final yesterday = ClaimedLoopRepository.getYesterdayDateString();
        
        final int newStreak = (matchingClaimed.lastCoveredDate == yesterday)
            ? matchingClaimed.streakCount + 1
            : (matchingClaimed.lastCoveredDate == today)
                ? matchingClaimed.streakCount
                : 1;

        final int updatedCovered = matchingClaimed.coveredCountToday + 1;
        final updatedClaim = matchingClaimed.copyWith(
          streakCount: newStreak,
          lastCoveredDate: today,
          coveredCountToday: updatedCovered,
        );

        _claimedLoopRepo.addOrUpdateClaimedLoop(updatedClaim).then((_) {
          _loadClaimedLoops();
          _claimedLoopCoveredEventController.add(updatedClaim);
        });

        // Set name matching the claim details
        final loopToSave = newLoop.copyWith(id: matchingClaimed.id, name: matchingClaimed.name);
        _state = _state.copyWith(
          loopCount: _state.loopCount + 1,
          trailPoints: [newLatLng], // Reset trail starting from current closing point
          capturedLoops: List<TurfLoop>.from(_state.capturedLoops)..add(loopToSave),
          bearing: currentBearing,
          elevationGainMetres: _totalElevationGainMetres,
          steps: steps,
          distanceKm: distanceKm,
          isStepEstimated: isStepEstimated,
          activeTrailColor: trailColor,
        );
      } else {
        // Trigger Event so UI can prompt user to claim and name the loop
        _loopCapturedEventController.add(newLoop);

        _state = _state.copyWith(
          loopCount: _state.loopCount + 1,
          trailPoints: [newLatLng],
          capturedLoops: List<TurfLoop>.from(_state.capturedLoops)..add(newLoop),
          bearing: currentBearing,
          elevationGainMetres: _totalElevationGainMetres,
          steps: steps,
          distanceKm: distanceKm,
          isStepEstimated: isStepEstimated,
          activeTrailColor: trailColor,
        );
      }
    } else {
      _state = _state.copyWith(
        trailPoints: updatedTrail,
        bearing: currentBearing,
        elevationGainMetres: _totalElevationGainMetres,
        steps: steps,
        distanceKm: distanceKm,
        isStepEstimated: isStepEstimated,
        activeTrailColor: trailColor,
      );
    }

    notifyListeners();
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

  ClaimedLoop? _getMatchingClaimedLoopForNewLoop(List<LatLng> newLoopPoints) {
    const double thresholdMetres = 25.0 * 0.3048; // 25 feet
    for (var claimedLoop in _cachedClaimedLoops) {
      for (var newPt in newLoopPoints) {
        for (var claimedPt in claimedLoop.points) {
          final double dist = LoopDetector.calculateDistanceMetres(
            newPt.latitude, newPt.longitude,
            claimedPt.latitude, claimedPt.longitude,
          );
          if (dist <= thresholdMetres) {
            return claimedLoop;
          }
        }
      }
    }
    return null;
  }

  void _triggerHapticFeedback() {
    HapticFeedback.vibrate();
  }

  int _getSessionDurationSeconds() {
    if (_state.sessionStatus != SessionStatus.active) return 0;
    final currentMillis = DateTime.now().millisecondsSinceEpoch;
    return ((currentMillis - _startTimeMillis) / 1000).toInt();
  }

  void _startTimer() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.sessionStatus == SessionStatus.active) {
        final int elapsedSeconds = _accumulatedTimeSeconds + _getSessionDurationSeconds();
        
        // Compute Cadence: steps per minute (SPM)
        int currentCadence = 0;
        if (elapsedSeconds > 10) {
          currentCadence = ((_state.steps.toDouble() / elapsedSeconds.toDouble()) * 60.0).toInt();
        }

        _state = _state.copyWith(
          durationSeconds: elapsedSeconds,
          cadence: currentCadence,
        );
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
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
    _stopTracking();
    _stopTimer();
    _loopCapturedEventController.close();
    _claimedLoopCoveredEventController.close();
    super.dispose();
  }
}
