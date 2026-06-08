import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClaimedLoop {
  final String id;
  final String name;
  final List<LatLng> points;
  final int streakCount;
  final String lastCoveredDate; // "yyyy-MM-dd"
  final int coveredCountToday;
  
  final String ownerId;
  final String ownerName;
  final bool isMyClaim;

  ClaimedLoop({
    required this.id,
    required this.name,
    required this.points,
    required this.streakCount,
    required this.lastCoveredDate,
    required this.coveredCountToday,
    this.ownerId = "",
    this.ownerName = "",
    this.isMyClaim = true,
  });

  bool get isActive {
    if (lastCoveredDate.isEmpty) return false;
    final now = DateTime.now();
    final todayStr = _formatDate(now);
    final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));
    return lastCoveredDate == todayStr || lastCoveredDate == yesterdayStr;
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Get the dynamic color for this claimed loop
  Color getDynamicColor() {
    if (ownerId.isEmpty) {
      // Unclaimed loop color: Premium soft slate grey
      return const Color(0xFF94A3B8);
    }
    if (!isActive) {
      // Expired loop color: Slate grey
      return const Color(0xFF94A3B8);
    }
    if (!isMyClaim) {
      // Enemy territory color: Sleek competitive purple/magenta
      return const Color(0xFF9C27B0);
    }
    return getDynamicColorForCompletions(coveredCountToday);
  }

  /// Copy constructor
  ClaimedLoop copyWith({
    String? id,
    String? name,
    List<LatLng>? points,
    int? streakCount,
    String? lastCoveredDate,
    int? coveredCountToday,
    String? ownerId,
    String? ownerName,
    bool? isMyClaim,
  }) {
    return ClaimedLoop(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      streakCount: streakCount ?? this.streakCount,
      lastCoveredDate: lastCoveredDate ?? this.lastCoveredDate,
      coveredCountToday: coveredCountToday ?? this.coveredCountToday,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      isMyClaim: isMyClaim ?? this.isMyClaim,
    );
  }

  /// Create from JSON Map
  factory ClaimedLoop.fromJson(Map<String, dynamic> json) {
    var ptsJson = json['points'] as List;
    List<LatLng> pts = ptsJson.map((pt) {
      return LatLng(pt['lat'] as double, pt['lng'] as double);
    }).toList();

    return ClaimedLoop(
      id: json['id'] as String,
      name: json['name'] as String,
      points: pts,
      streakCount: json['streakCount'] as int,
      lastCoveredDate: json['lastCoveredDate'] as String,
      coveredCountToday: json['coveredCountToday'] as int,
      ownerId: (json['ownerId'] as String?) ?? "",
      ownerName: (json['ownerName'] as String?) ?? "",
      isMyClaim: (json['isMyClaim'] as bool?) ?? true,
    );
  }

  /// Convert to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points.map((pt) => {'lat': pt.latitude, 'lng': pt.longitude}).toList(),
      'streakCount': streakCount,
      'lastCoveredDate': lastCoveredDate,
      'coveredCountToday': coveredCountToday,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'isMyClaim': isMyClaim,
    };
  }

  /// Static method to compute dynamic colors based on completions count
  static Color getDynamicColorForCompletions(int completions) {
    const int maxCompletions = 50;
    final double c = completions.clamp(1, maxCompletions).toDouble();
    final double t = (c - 1) / (maxCompletions - 1); // 0.0 to 1.0

    double r;
    double g;
    double b;

    if (t < 0.4) {
      final double segmentT = t / 0.4;
      // Blue (33, 150, 243) to Yellow (255, 235, 59)
      r = 33.0 + (255.0 - 33.0) * segmentT;
      g = 150.0 + (235.0 - 150.0) * segmentT;
      b = 243.0 + (59.0 - 243.0) * segmentT;
    } else if (t < 0.7) {
      final double segmentT = (t - 0.4) / 0.3;
      // Yellow (255, 235, 59) to Dark Yellow (190, 145, 0)
      r = 255.0 + (190.0 - 255.0) * segmentT;
      g = 235.0 + (145.0 - 235.0) * segmentT;
      b = 59.0 + (0.0 - 59.0) * segmentT;
    } else {
      final double segmentT = (t - 0.7) / 0.3;
      // Dark Yellow (190, 145, 0) to Dark Red (150, 0, 0)
      r = 190.0 + (150.0 - 190.0) * segmentT;
      g = 145.0 + (0.0 - 145.0) * segmentT;
      b = 0.0 + (0.0 - 0.0) * segmentT;
    }

    final double darkenFactor = 1.0 - (t * 0.3);

    final int finalR = (r * darkenFactor).round().clamp(0, 255);
    final int finalG = (g * darkenFactor).round().clamp(0, 255);
    final int finalB = (b * darkenFactor).round().clamp(0, 255);

    return Color.fromARGB(255, finalR, finalG, finalB);
  }
}
