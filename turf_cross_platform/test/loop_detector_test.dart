import 'package:flutter_test/flutter_test.dart';
import 'package:turf_cross_platform/location/loop_detector.dart';

void main() {
  group('LoopDetector Tests', () {
    test('testCalculateDistanceMetres_sameCoordinate_returnsZero', () {
      final dist = LoopDetector.calculateDistanceMetres(37.7749, -122.4194, 37.7749, -122.4194);
      expect(dist, closeTo(0.0, 0.01));
    });

    test('testCalculateDistanceMetres_knownDistance_returnsCorrectValue', () {
      // San Francisco to Los Angeles is approx 559 km (559000 metres)
      const sfLat = 37.7749;
      const sfLon = -122.4194;
      const laLat = 34.0522;
      const laLon = -118.2437;
      
      final dist = LoopDetector.calculateDistanceMetres(sfLat, sfLon, laLat, laLon);
      // Check within 5% tolerance (30000.0 metres)
      expect(dist, closeTo(559000.0, 30000.0));
    });

    test('testCalculateDistanceMetres_smallDistance_returnsCorrectValue', () {
      // Points approx 10 metres apart
      const lat1 = 37.7749;
      const lon1 = -122.4194;
      const lat2 = 37.77499; // offset slightly north
      const lon2 = -122.4194;
      
      final dist = LoopDetector.calculateDistanceMetres(lat1, lon1, lat2, lon2);
      expect(dist, greaterThan(0.0));
      expect(dist, lessThan(15.0));
    });
  });
}
