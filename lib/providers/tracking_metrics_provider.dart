import 'package:flutter/foundation.dart';
import '../models/session_status.dart';

class TrackingMetricsProvider extends ChangeNotifier {
  int _steps = 0;
  bool _isStepEstimated = false;
  double _distanceKm = 0.0;
  int _loopCount = 0;
  int _durationSeconds = 0;
  int _cadence = 0;
  double _elevationGainMetres = 0.0;
  SessionStatus _sessionStatus = SessionStatus.idle;

  // Getters
  int get steps => _steps;
  bool get isStepEstimated => _isStepEstimated;
  double get distanceKm => _distanceKm;
  int get loopCount => _loopCount;
  int get durationSeconds => _durationSeconds;
  int get cadence => _cadence;
  double get elevationGainMetres => _elevationGainMetres;
  SessionStatus get sessionStatus => _sessionStatus;

  /// Update active session status
  void setSessionStatus(SessionStatus status) {
    _sessionStatus = status;
    notifyListeners();
  }

  /// Reset all metrics to zero for a new session
  void reset() {
    _steps = 0;
    _isStepEstimated = false;
    _distanceKm = 0.0;
    _loopCount = 0;
    _durationSeconds = 0;
    _cadence = 0;
    _elevationGainMetres = 0.0;
    notifyListeners();
  }

  /// Update pedometer step count and calculate distance
  void updateSteps(int steps, double distanceKm, bool isEstimated) {
    _steps = steps;
    _distanceKm = distanceKm;
    _isStepEstimated = isEstimated;
    notifyListeners();
  }

  /// Increment loop count
  void incrementLoopCount() {
    _loopCount++;
    notifyListeners();
  }

  /// Set exact loop count
  void setLoopCount(int count) {
    _loopCount = count;
    notifyListeners();
  }

  /// Update duration timer and steps-per-minute cadence
  void updateTimer(int durationSeconds, int cadence) {
    _durationSeconds = durationSeconds;
    _cadence = cadence;
    notifyListeners();
  }

  /// Update elevation gain
  void updateElevationGain(double elevationGain) {
    _elevationGainMetres = elevationGain;
    notifyListeners();
  }
}
