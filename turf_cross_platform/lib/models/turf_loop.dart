import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class TurfLoop {
  final String id;
  final String? name;
  final List<LatLng> points;

  TurfLoop({
    String? id,
    this.name,
    required this.points,
  }) : id = id ?? const Uuid().v4();

  /// Create a copy of TurfLoop with modified fields
  TurfLoop copyWith({
    String? id,
    String? name,
    List<LatLng>? points,
  }) {
    return TurfLoop(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
    );
  }

  /// Create from JSON Map
  factory TurfLoop.fromJson(Map<String, dynamic> json) {
    var ptsJson = json['points'] as List;
    List<LatLng> pts = ptsJson.map((pt) {
      return LatLng(pt['lat'] as double, pt['lng'] as double);
    }).toList();

    return TurfLoop(
      id: json['id'] as String,
      name: json['name'] as String?,
      points: pts,
    );
  }

  /// Convert to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points.map((pt) => {'lat': pt.latitude, 'lng': pt.longitude}).toList(),
    };
  }
}
