import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'session_status.dart';
import 'turf_loop.dart';

class TurfSessionState {
  final int steps;
  final bool isStepEstimated;
  final double distanceKm;
  final int loopCount;
  final List<LatLng> trailPoints;
  final List<TurfLoop> capturedLoops;
  final SessionStatus sessionStatus;
  final bool gpsSignalWeak;
  final double bearing;
  final int cadence;
  final double elevationGainMetres;
  final int durationSeconds;
  final Color? activeTrailColor;

  TurfSessionState({
    this.steps = 0,
    this.isStepEstimated = false,
    this.distanceKm = 0.0,
    this.loopCount = 0,
    this.trailPoints = const [],
    this.capturedLoops = const [],
    this.sessionStatus = SessionStatus.idle,
    this.gpsSignalWeak = false,
    this.bearing = 0.0,
    this.cadence = 0,
    this.elevationGainMetres = 0.0,
    this.durationSeconds = 0,
    this.activeTrailColor,
  });

  /// Copy constructor to safely generate modified states
  TurfSessionState copyWith({
    int? steps,
    bool? isStepEstimated,
    double? distanceKm,
    int? loopCount,
    List<LatLng>? trailPoints,
    List<TurfLoop>? capturedLoops,
    SessionStatus? sessionStatus,
    bool? gpsSignalWeak,
    double? bearing,
    int? cadence,
    double? elevationGainMetres,
    int? durationSeconds,
    Color? activeTrailColor,
  }) {
    return TurfSessionState(
      steps: steps ?? this.steps,
      isStepEstimated: isStepEstimated ?? this.isStepEstimated,
      distanceKm: distanceKm ?? this.distanceKm,
      loopCount: loopCount ?? this.loopCount,
      trailPoints: trailPoints ?? this.trailPoints,
      capturedLoops: capturedLoops ?? this.capturedLoops,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      gpsSignalWeak: gpsSignalWeak ?? this.gpsSignalWeak,
      bearing: bearing ?? this.bearing,
      cadence: cadence ?? this.cadence,
      elevationGainMetres: elevationGainMetres ?? this.elevationGainMetres,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      activeTrailColor: activeTrailColor ?? this.activeTrailColor,
    );
  }
}
