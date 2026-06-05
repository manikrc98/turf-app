import 'dart:async';
import 'package:pedometer/pedometer.dart';

class StepCounterManager {
  static const double strideMetres = 0.762;

  bool _isSensorAvailable = true;
  int _stepBaseline = -1;
  StreamSubscription<StepCount>? _subscription;
  
  bool get isSensorAvailable => _isSensorAvailable;

  /// Start listening to physical step counter sensor
  void start(void Function(int steps) onStepUpdate, void Function(Object error) onError) {
    _stepBaseline = -1;
    _isSensorAvailable = true;

    _subscription = Pedometer.stepCountStream.listen(
      (StepCount event) {
        final int totalSteps = event.steps;
        if (_stepBaseline == -1) {
          _stepBaseline = totalSteps;
        }
        final int liveSteps = totalSteps - _stepBaseline;
        onStepUpdate(liveSteps);
      },
      onError: (error) {
        print("Step counter sensor error/unavailable: $error");
        _isSensorAvailable = false;
        onError(error);
      },
      cancelOnError: false,
    );
  }

  /// Stop listening to the sensor
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Helper to estimate steps from distance in kilometers
  static int estimateSteps(double distanceKm) {
    final double distanceMetres = distanceKm * 1000.0;
    return (distanceMetres / strideMetres).toInt();
  }

  /// Helper to calculate distance in kilometers from steps
  static double calculateDistanceKm(int steps) {
    return (steps * strideMetres) / 1000.0;
  }
}
