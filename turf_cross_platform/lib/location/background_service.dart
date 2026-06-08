import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:uuid/uuid.dart';

import '../models/local_walk_session.dart';
import '../models/local_claimed_loop.dart';
import '../models/session_status.dart';
import '../models/turf_loop.dart';
import '../models/claimed_loop.dart';
import '../repositories/isar_service.dart';
import '../repositories/claimed_loop_repository.dart';
import 'loop_detector.dart';
import '../sensors/step_counter_manager.dart';

const String notificationChannelId = 'turf_tracking_channel';
const int notificationId = 888;

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'TURF Active Tracking',
    description: 'Displays active walk tracking metrics and notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'TURF Walk Tracker',
      initialNotificationContent: 'Initializing tracker...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final isar = await IsarService.getDB();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Internal Session Variables
  String sessionId = "active_session";
  int steps = 0;
  bool isStepEstimated = false;
  double distanceKm = 0.0;
  int loopCount = 0;
  int durationSeconds = 0;
  int cadence = 0;
  double elevationGainMetres = 0.0;

  List<LatLng> trailPoints = [];
  List<TurfLoop> capturedLoops = [];

  // Sensor & Tracking Control variables
  bool isTracking = true;
  int startTimeMillis = DateTime.now().millisecondsSinceEpoch;
  int accumulatedTimeSeconds = 0;
  
  Position? lastPositionForDistance;
  double totalGpsDistanceMetres = 0.0;
  double? lastAltitude;
  
  // Anti-Spoofing Metrics
  int speedViolationCount = 0;
  bool spoofFlagged = false;

  // Stream Subscriptions
  StreamSubscription<Position>? locationSubscription;
  StreamSubscription<StepCount>? stepSubscription;
  Timer? timer;

  int stepBaseline = -1;

  // Notification helper
  Future<void> updateNotification(String content) async {
    if (service is AndroidServiceInstance) {
      if (await (service as AndroidServiceInstance).isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'TURF Live Tracking',
          content,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'TURF Active Tracking',
              channelDescription: 'Displays active walk tracking metrics.',
              ongoing: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    }
  }

  // Load or create active session record in Isar
  Future<void> saveToIsar() async {
    try {
      final sessionJson = jsonEncode(capturedLoops.map((l) => l.toJson()).toList());
      
      final activeWalk = LocalWalkSession()
        ..id = 99999 // Hardcode ID for active session record
        ..sessionId = sessionId
        ..dateTime = DateTime.now().toIso8601String()
        ..steps = steps
        ..isStepEstimated = isStepEstimated
        ..distanceKm = distanceKm
        ..loopCount = loopCount
        ..durationSeconds = durationSeconds + accumulatedTimeSeconds
        ..cadence = cadence
        ..elevationGainMetres = elevationGainMetres
        ..trailLatList = trailPoints.map((p) => p.latitude).toList()
        ..trailLngList = trailPoints.map((p) => p.longitude).toList()
        ..loopsJson = sessionJson
        ..isSynced = false;

      await isar.writeTxn(() async {
        await isar.localWalkSessions.put(activeWalk);
      });
    } catch (e) {
      print("Background Isar Save Error: $e");
    }
  }

  void stopSubscriptions() {
    locationSubscription?.cancel();
    locationSubscription = null;
    stepSubscription?.cancel();
    stepSubscription = null;
    timer?.cancel();
    timer = null;
  }

  // Process coordinates logic (distance, altitude, loops)
  void processPosition(Position position) async {
    // 1. Anti-Spoofing: Mock Location check
    if (position.isMocked) {
      spoofFlagged = true;
      service.invoke('spoof_detected', {'reason': 'Mock location detected'});
      updateNotification('⚠️ tracking paused: mock location');
      return;
    }

    // 2. Anti-Spoofing: Speed limits validation (>30 km/h is 8.33 m/s)
    if (position.speed > 8.33) {
      speedViolationCount++;
      if (speedViolationCount >= 3) {
        spoofFlagged = true;
        service.invoke('spoof_detected', {'reason': 'Excessive speed detected (Vehicle)'});
        updateNotification('⚠️ tracking paused: high speed');
        return;
      }
    } else {
      if (speedViolationCount > 0) speedViolationCount--;
    }

    final bool isWeak = position.accuracy > 20.0;
    service.invoke('gps_status', {'weak': isWeak});

    if (isWeak) {
      return; // Skip drawing weak signals
    }

    final LatLng newLatLng = LatLng(position.latitude, position.longitude);

    // Track Altitude / Elevation Gain
    if (position.altitude != 0.0) {
      final double currentAltitude = position.altitude;
      if (lastAltitude != null) {
        final double diff = currentAltitude - lastAltitude!;
        if (diff > 1.5) { // Filter minor variations (< 1.5m)
          elevationGainMetres += diff;
        }
      }
      lastAltitude = currentAltitude;
    }

    // GPS Step & Distance Fallback
    if (stepBaseline == -1) {
      // Step sensor not available yet or fallback active
      if (lastPositionForDistance != null) {
        final double distanceDelta = Geolocator.distanceBetween(
          lastPositionForDistance!.latitude,
          lastPositionForDistance!.longitude,
          position.latitude,
          position.longitude,
        );
        totalGpsDistanceMetres += distanceDelta;
        distanceKm = totalGpsDistanceMetres / 1000.0;
        steps = StepCounterManager.estimateSteps(distanceKm);
        isStepEstimated = true;
      }
      lastPositionForDistance = position;
    }

    // Append to active trail
    trailPoints.add(newLatLng);

    // 3. Anti-Spoofing: Step to distance correlation check
    // If we have traveled >500m but steps are extremely low, flag it
    if (distanceKm > 0.5 && steps < 100 && !isStepEstimated) {
      spoofFlagged = true;
      service.invoke('spoof_detected', {'reason': 'Distance and step count mismatch'});
      updateNotification('⚠️ tracking paused: step count mismatch');
      return;
    }

    // Check loop closure mathematics
    final int closureIndex = LoopDetector.findLoopClosureIndex(trailPoints);
    if (closureIndex != -1) {
      final loopPoints = trailPoints.sublist(closureIndex);
      final newLoop = TurfLoop(id: const Uuid().v4(), points: List<LatLng>.from(loopPoints));

      // Get claim matches
      final localClaims = await isar.localClaimedLoops.where().findAll();
      ClaimedLoop? matchingClaim;
      const double thresholdMetres = 25.0 * 0.3048; // 25 feet

      for (var localClaim in localClaims) {
        List<LatLng> pts = [];
        for (int i = 0; i < localClaim.latList.length; i++) {
          pts.add(LatLng(localClaim.latList[i], localClaim.lngList[i]));
        }

        bool isClose = false;
        for (var newPt in loopPoints) {
          for (var claimedPt in pts) {
            final double dist = LoopDetector.calculateDistanceMetres(
              newPt.latitude, newPt.longitude,
              claimedPt.latitude, claimedPt.longitude,
            );
            if (dist <= thresholdMetres) {
              isClose = true;
              break;
            }
          }
          if (isClose) break;
        }

        if (isClose) {
          matchingClaim = ClaimedLoop(
            id: localClaim.loopId,
            name: localClaim.name,
            points: pts,
            streakCount: localClaim.streakCount,
            lastCoveredDate: localClaim.lastCoveredDate,
            coveredCountToday: localClaim.coveredCountToday,
          );
          break;
        }
      }

      if (matchingClaim != null) {
        final today = ClaimedLoopRepository.getTodayDateString();
        final yesterday = ClaimedLoopRepository.getYesterdayDateString();

        final int newStreak = (matchingClaim.lastCoveredDate == yesterday)
            ? matchingClaim.streakCount + 1
            : (matchingClaim.lastCoveredDate == today)
                ? matchingClaim.streakCount
                : 1;

        final int updatedCovered = matchingClaim.coveredCountToday + 1;
        
        // Update LocalClaimedLoop in Isar
        final localClaimUpdate = await isar.localClaimedLoops
            .filter()
            .loopIdEqualTo(matchingClaim.id)
            .findFirst();

        if (localClaimUpdate != null) {
          localClaimUpdate.streakCount = newStreak;
          localClaimUpdate.lastCoveredDate = today;
          localClaimUpdate.coveredCountToday = updatedCovered;

          await isar.writeTxn(() async {
            await isar.localClaimedLoops.put(localClaimUpdate);
          });
        }

        final loopToSave = newLoop.copyWith(id: matchingClaim.id, name: matchingClaim.name);
        capturedLoops.add(loopToSave);
        loopCount++;

        // Notify main app that a claimed loop was covered
        final updatedClaimModel = matchingClaim.copyWith(
          streakCount: newStreak,
          lastCoveredDate: today,
          coveredCountToday: updatedCovered,
        );
        service.invoke('claimed_loop_covered', updatedClaimModel.toJson());
      } else {
        capturedLoops.add(newLoop);
        loopCount++;

        // Notify main app that a new loop was captured
        service.invoke('loop_captured', newLoop.toJson());
      }

      trailPoints = [newLatLng]; // Reset trail starting from current closing point
    }

    await saveToIsar();
    
    // Invoke update event to UI
    service.invoke('update', {
      'steps': steps,
      'isStepEstimated': isStepEstimated,
      'distanceKm': distanceKm,
      'loopCount': loopCount,
      'durationSeconds': durationSeconds + accumulatedTimeSeconds,
      'cadence': cadence,
      'elevationGainMetres': elevationGainMetres,
      'trailPoints': trailPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'capturedLoops': capturedLoops.map((l) => l.toJson()).toList(),
      'gpsSignalWeak': isWeak,
      'bearing': position.heading,
    });

    updateNotification(
        'Steps: $steps | Distance: ${distanceKm.toStringAsFixed(2)} km | Loops: $loopCount');
  }

  void startTracking() {
    stopSubscriptions();
    isTracking = true;
    startTimeMillis = DateTime.now().millisecondsSinceEpoch;

    // 1. Geolocator stream
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
      locationSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          if (!isTracking || spoofFlagged) return;
          processPosition(position);
        },
        onError: (err) {
          print("Background Geolocator stream error: $err");
        },
      );
    } catch (e) {
      print("Failed to start Geolocator position stream: $e");
    }

    // 2. Step Counter stream
    try {
      stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (!isTracking || spoofFlagged) return;
          if (stepBaseline == -1) {
            stepBaseline = event.steps;
            isStepEstimated = false;
          }
          steps = event.steps - stepBaseline;
          distanceKm = StepCounterManager.calculateDistanceKm(steps);
        },
        onError: (err) {
          print("Pedometer Sensor error: $err");
        },
      );
    } catch (e) {
      print("Failed to start Pedometer stream: $e");
    }

    // 3. Periodic timer for stopwatch & cadence
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isTracking || spoofFlagged) return;
      final currentMillis = DateTime.now().millisecondsSinceEpoch;
      durationSeconds = ((currentMillis - startTimeMillis) / 1000).toInt();

      final int totalElapsed = durationSeconds + accumulatedTimeSeconds;
      if (totalElapsed > 10 && steps > 0) {
        cadence = ((steps.toDouble() / totalElapsed.toDouble()) * 60.0).toInt();
      }

      // Throttle DB write to every 10 seconds of elapsed duration to prevent blocking the event loop
      if (totalElapsed % 10 == 0) {
        saveToIsar();
      }

      service.invoke('update', {
        'steps': steps,
        'isStepEstimated': isStepEstimated,
        'distanceKm': distanceKm,
        'loopCount': loopCount,
        'durationSeconds': totalElapsed,
        'cadence': cadence,
        'elevationGainMetres': elevationGainMetres,
        // Do NOT send trailPoints and capturedLoops every second to save CPU/serialization time.
        // They are already broadcasted inside processPosition whenever the location changes.
        'gpsSignalWeak': false,
        'bearing': 0.0,
      });

      updateNotification(
          'Steps: $steps | Distance: ${distanceKm.toStringAsFixed(2)} km | Loops: $loopCount');
    });
  }

  // Handle messages from the main UI isolate
  service.on('pause').listen((event) {
    if (!isTracking) return;
    isTracking = false;
    accumulatedTimeSeconds += durationSeconds;
    durationSeconds = 0;
    stopSubscriptions();
    saveToIsar();
    updateNotification('Walk Paused');
    service.invoke('paused');
  });

  service.on('resume').listen((event) {
    if (isTracking || spoofFlagged) return;
    startTracking();
    updateNotification('Walk Resumed');
    service.invoke('resumed');
  });

  service.on('stop').listen((event) async {
    isTracking = false;
    stopSubscriptions();
    
    // Delete active session record
    await isar.writeTxn(() async {
      await isar.localWalkSessions.delete(99999);
    });

    service.stopSelf();
  });

  service.on('start').listen((event) {
    sessionId = event?['sessionId'] ?? "active_session";
    steps = 0;
    isStepEstimated = false;
    distanceKm = 0.0;
    loopCount = 0;
    durationSeconds = 0;
    cadence = 0;
    elevationGainMetres = 0.0;
    accumulatedTimeSeconds = 0;
    trailPoints = [];
    capturedLoops = [];
    isTracking = true;
    startTimeMillis = DateTime.now().millisecondsSinceEpoch;
    
    lastPositionForDistance = null;
    totalGpsDistanceMetres = 0.0;
    lastAltitude = null;
    speedViolationCount = 0;
    spoofFlagged = false;
    stepBaseline = -1;

    startTracking();
    updateNotification('Tracking your walk...');
  });

  // Notify UI that service is initialized and listening
  service.invoke('service_ready');

  // Start tracking automatically on launch
  startTracking();
  updateNotification('Tracking your walk...');
}
