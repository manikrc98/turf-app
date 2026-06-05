import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LoopDetector {
  static const double loopThresholdMetres = 10.0;
  static const int minTrailPoints = 20;

  /// Checks if the last point in [trailPoints] closes a loop back to the first point of the trail.
  static bool isLoopClosed(List<LatLng> trailPoints) {
    if (trailPoints.length <= minTrailPoints) return false;

    final startPoint = trailPoints.first;
    final newPoint = trailPoints.last;

    final distance = calculateDistanceMetres(
      startPoint.latitude, startPoint.longitude,
      newPoint.latitude, newPoint.longitude
    );

    return distance < loopThresholdMetres;
  }

  /// Haversine formula to compute distance between two coordinates in metres
  static double calculateDistanceMetres(
    double lat1, double lon1,
    double lat2, double lon2
  ) {
    const double r = 6371000.0; // Earth radius in metres
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double sinDLatHalf = sin(dLat / 2.0);
    final double sinDLonHalf = sin(dLon / 2.0);

    final double a = sinDLatHalf * sinDLatHalf +
                     cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
                     sinDLonHalf * sinDLonHalf;
                     
    final double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
    return r * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}
