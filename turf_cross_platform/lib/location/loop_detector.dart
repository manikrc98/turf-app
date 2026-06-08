import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LoopDetector {
  static const double loopThresholdMetres = 15.0;
  static const int minTrailPoints = 20;

  /// Checks if the last point in [trailPoints] closes a loop.
  static bool isLoopClosed(List<LatLng> trailPoints) {
    return findLoopClosureIndex(trailPoints) != -1;
  }

  /// Finds the index of the point where the loop closes (i.e. the last point is close to a historical point).
  /// Only checks points up to `trailPoints.length - minTrailPoints` to avoid false closures on consecutive points.
  /// Returns -1 if no loop is detected.
  static int findLoopClosureIndex(List<LatLng> trailPoints) {
    if (trailPoints.length <= minTrailPoints) return -1;

    final newPoint = trailPoints.last;
    final int searchLimit = trailPoints.length - minTrailPoints;

    for (int i = 0; i <= searchLimit; i++) {
      final historicalPoint = trailPoints[i];

      // Fast Cartesian box filtering (0.00015 degrees ~= 16.7m latitude, 0.0002 degrees ~= 15-22m longitude)
      final double latDiff = (historicalPoint.latitude - newPoint.latitude).abs();
      if (latDiff > 0.00015) continue;

      final double lonDiff = (historicalPoint.longitude - newPoint.longitude).abs();
      if (lonDiff > 0.0002) continue;

      final distance = calculateDistanceMetres(
        historicalPoint.latitude, historicalPoint.longitude,
        newPoint.latitude, newPoint.longitude
      );
      if (distance < loopThresholdMetres) {
        return i;
      }
    }
    return -1;
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
