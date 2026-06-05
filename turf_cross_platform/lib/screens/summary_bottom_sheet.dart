import 'dart:typed_data';
import 'package:flutter/material.dart';

class SummaryBottomSheet extends StatelessWidget {
  final Uint8List? mapSnapshot;
  final int steps;
  final bool isStepEstimated;
  final double distanceKm;
  final int loops;
  final int durationSeconds;
  final int cadence;
  final double elevationGainMetres;
  final VoidCallback onDone;

  const SummaryBottomSheet({
    super.key,
    this.mapSnapshot,
    required this.steps,
    required this.isStepEstimated,
    required this.distanceKm,
    required this.loops,
    required this.durationSeconds,
    required this.cadence,
    required this.elevationGainMetres,
    required this.onDone,
  });

  static void show({
    required BuildContext context,
    Uint8List? mapSnapshot,
    required int steps,
    required bool isStepEstimated,
    required double distanceKm,
    required int loops,
    required int durationSeconds,
    required int cadence,
    required double elevationGainMetres,
    required VoidCallback onDone,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => SummaryBottomSheet(
        mapSnapshot: mapSnapshot,
        steps: steps,
        isStepEstimated: isStepEstimated,
        distanceKm: distanceKm,
        loops: loops,
        durationSeconds: durationSeconds,
        cadence: cadence,
        elevationGainMetres: elevationGainMetres,
        onDone: onDone,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Premium Slate Dark
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              "Walk Summary 🏁",
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Map Snapshot Container
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF334155), // Slate Medium
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: mapSnapshot != null
                ? Image.memory(
                    mapSnapshot!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  )
                : const Center(
                    child: Text(
                      "Snapshot unavailable",
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          // Summary Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildMetricCard(
                Icons.directions_walk_rounded,
                "Steps",
                "$steps${isStepEstimated ? ' (est)' : ''}",
                const Color(0xFF2196F3),
              ),
              _buildMetricCard(
                Icons.map_rounded,
                "Distance",
                "${distanceKm.toStringAsFixed(2)} km",
                const Color(0xFF4CAF50),
              ),
              _buildMetricCard(
                Icons.restore_rounded,
                "Duration",
                _formatDuration(durationSeconds),
                const Color(0xFFFF9800),
              ),
              _buildMetricCard(
                Icons.donut_large_rounded,
                "Loops Captured",
                "$loops",
                const Color(0xFFE91E63),
              ),
              _buildMetricCard(
                Icons.speed_rounded,
                "Avg Cadence",
                "$cadence SPM",
                const Color(0xFF9C27B0),
              ),
              _buildMetricCard(
                Icons.filter_hdr_rounded,
                "Elevation Gain",
                "${elevationGainMetres.toStringAsFixed(1)} m",
                const Color(0xFF00BCD4),
              ),
            ],
          ),
          if (loops == 0) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Try completing a loop next time!",
                style: TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              onDone();
            },
            child: const Text(
              "Awesome, Done",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155), // Slate Medium
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
