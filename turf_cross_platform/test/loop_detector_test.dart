import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

    test('testIsLoopClosed_straightLine_returnsFalse', () {
      final List<LatLng> trail = [];
      // Generate a straight line of 25 points
      for (int i = 0; i <= 25; i++) {
        trail.add(LatLng(37.7749 + (i * 0.0001), -122.4194));
      }
      expect(LoopDetector.isLoopClosed(trail), isFalse);
      expect(LoopDetector.findLoopClosureIndex(trail), -1);
    });

    test('testIsLoopClosed_insufficientPoints_returnsFalse', () {
      final List<LatLng> trail = [];
      // Close loop but with only 10 points
      for (int i = 0; i < 10; i++) {
        trail.add(LatLng(37.7749 + (i * 0.00001), -122.4194));
      }
      trail.add(const LatLng(37.7749, -122.4194)); // closes back to start
      expect(LoopDetector.isLoopClosed(trail), isFalse);
      expect(LoopDetector.findLoopClosureIndex(trail), -1);
    });

    test('testIsLoopClosed_loopAtStart_returnsTrue', () {
      final List<LatLng> trail = [];
      const startLat = 37.7749;
      const startLon = -122.4194;
      // Add 21 points going away
      for (int i = 0; i <= 20; i++) {
        trail.add(LatLng(startLat + (i * 0.00001), startLon));
      }
      // Add 5 points coming back to start
      for (int i = 4; i >= 0; i--) {
        trail.add(LatLng(startLat + (i * 0.00001), startLon));
      }
      expect(LoopDetector.isLoopClosed(trail), isTrue);
      expect(LoopDetector.findLoopClosureIndex(trail), 0);
    });

    test('testIsLoopClosed_loopWithPrefixTail_returnsTrue', () {
      final List<LatLng> trail = [];
      // User walks 50m to loop (approx 10 points of tail)
      for (int i = 0; i < 10; i++) {
        trail.add(LatLng(37.7749 + (i * 0.0002), -122.4194));
      }
      
      // Loop starts at index 9: LatLng(37.7767, -122.4194)
      const loopStartLat = 37.7767;
      const loopStartLon = -122.4194;
      
      // Add 21 points for the loop going away
      for (int i = 0; i <= 20; i++) {
        trail.add(LatLng(loopStartLat, loopStartLon + (i * 0.00005)));
      }
      
      // Add points coming back to index 9
      for (int i = 19; i >= 0; i--) {
        trail.add(LatLng(loopStartLat, loopStartLon + (i * 0.00005)));
      }
      
      expect(LoopDetector.isLoopClosed(trail), isTrue);
      expect(LoopDetector.findLoopClosureIndex(trail), 9);
    });
  });
}
