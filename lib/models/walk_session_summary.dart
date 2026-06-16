import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'turf_loop.dart';

class WalkSessionSummary {
  final String id;
  final String dateTime;
  final int steps;
  final bool isStepEstimated;
  final double distanceKm;
  final int loopCount;
  final int durationSeconds;
  final List<TurfLoop> loops;
  final int cadence;
  final double elevationGainMetres;
  final List<LatLng> trailPoints;

  WalkSessionSummary({
    required this.id,
    required this.dateTime,
    required this.steps,
    required this.isStepEstimated,
    required this.distanceKm,
    required this.loopCount,
    required this.durationSeconds,
    this.loops = const [],
    this.cadence = 0,
    this.elevationGainMetres = 0.0,
    this.trailPoints = const [],
  });

  /// Create from JSON Map
  factory WalkSessionSummary.fromJson(Map<String, dynamic> json) {
    var loopsJson = json['loops'] as List?;
    List<TurfLoop> sessionLoops = [];
    if (loopsJson != null) {
      sessionLoops = loopsJson.map((l) => TurfLoop.fromJson(l)).toList();
    } else {
      // Fallback check for old data schema containing "polygons"
      var polysJson = json['polygons'] as List?;
      if (polysJson != null) {
        sessionLoops = polysJson.map((p) {
          var ptArray = p as List;
          var points = ptArray.map((pt) {
            return LatLng(pt['lat'] as double, pt['lng'] as double);
          }).toList();
          return TurfLoop(points: points);
        }).toList();
      }
    }

    var trailJson = json['trailPoints'] as List?;
    List<LatLng> trailPts = [];
    if (trailJson != null) {
      trailPts = trailJson.map((pt) {
        return LatLng(pt['lat'] as double, pt['lng'] as double);
      }).toList();
    }

    return WalkSessionSummary(
      id: json['id'] as String,
      dateTime: json['dateTime'] as String,
      steps: json['steps'] as int,
      isStepEstimated: json['isStepEstimated'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      loopCount: json['loopCount'] as int,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      loops: sessionLoops,
      cadence: json['cadence'] as int? ?? 0,
      elevationGainMetres: (json['elevationGainMetres'] as num? ?? 0.0).toDouble(),
      trailPoints: trailPts,
    );
  }

  /// Convert to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime,
      'steps': steps,
      'isStepEstimated': isStepEstimated,
      'distanceKm': distanceKm,
      'loopCount': loopCount,
      'durationSeconds': durationSeconds,
      'loops': loops.map((l) => l.toJson()).toList(),
      'cadence': cadence,
      'elevationGainMetres': elevationGainMetres,
      'trailPoints': trailPoints.map((pt) => {'lat': pt.latitude, 'lng': pt.longitude}).toList(),
    };
  }
}
