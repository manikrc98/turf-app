import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';

class CompassManager {
  StreamSubscription<CompassEvent>? _subscription;

  /// Start listening to the compass sensor for heading updates (in degrees, 0 to 360)
  void start(void Function(double heading) onHeadingUpdate) {
    _subscription = FlutterCompass.events?.listen(
      (CompassEvent event) {
        final double? heading = event.heading;
        if (heading != null) {
          // Normalize heading to [0, 360] degrees
          double normalizedHeading = heading;
          if (normalizedHeading < 0) {
            normalizedHeading += 360.0;
          }
          onHeadingUpdate(normalizedHeading);
        }
      },
      onError: (error) {
        print("Compass sensor error: $error");
      },
    );
  }

  /// Stop listening to the compass
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
