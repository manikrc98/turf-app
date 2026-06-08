import 'package:flutter/material.dart';
import '../models/walk_session_summary.dart';
import '../repositories/history_repository.dart';

class HistoryBottomSheet extends StatefulWidget {
  const HistoryBottomSheet({super.key});

  static void show(BuildContext context, VoidCallback onDismiss) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HistoryBottomSheet(),
    ).then((_) => onDismiss());
  }

  @override
  State<HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends State<HistoryBottomSheet> {
  final HistoryRepository _historyRepo = HistoryRepository();
  List<WalkSessionSummary> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final historyList = await _historyRepo.getHistory();
    setState(() {
      _history = historyList;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Clear Walk History", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to permanently delete all your walk session records?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyRepo.clearHistory();
      _loadHistory();
    }
  }

  Future<void> _deleteSession(WalkSessionSummary session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Walk Record", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete this walk record from '${session.dateTime}'?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyRepo.deleteSession(session.id);
      _loadHistory();
    }
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Premium Slate Dark
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12.0),
              width: 40.0,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Walk History",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_history.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    tooltip: "Clear History",
                    onPressed: _clearHistory,
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // History items list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
                : _history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final session = _history[index];
                          return _buildSessionCard(session);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_walk_rounded, size: 72, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            "No walks recorded yet",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start a walk session on the map to track loops!",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(WalkSessionSummary session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      color: const Color(0xFF334155), // Slate Medium
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 3.0,
      child: ExpansionTile(
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white54,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              onPressed: () => _deleteSession(session),
            ),
            const Icon(Icons.expand_more_rounded, color: Colors.white54),
          ],
        ),
        title: Text(
          session.dateTime,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            "${session.steps} steps · ${session.distanceKm.toStringAsFixed(2)} km · ${session.loopCount} loops",
            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
        ),
        childrenPadding: const EdgeInsets.all(16.0),
        children: [
          // Expandable detailed grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildMetricDetail("Steps", "${session.steps}${session.isStepEstimated ? ' (est)' : ''}"),
              _buildMetricDetail("Distance", "${session.distanceKm.toStringAsFixed(2)} km"),
              _buildMetricDetail("Duration", _formatDuration(session.durationSeconds)),
              _buildMetricDetail("Loops Captured", "${session.loopCount}"),
              _buildMetricDetail("Avg Cadence", "${session.cadence} SPM"),
              _buildMetricDetail("Elevation Climb", "${session.elevationGainMetres.toStringAsFixed(1)} m"),
            ],
          ),
          if (session.loops.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Captured Loops in Session:",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13.0),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: session.loops.map((loop) {
                return Chip(
                  backgroundColor: const Color(0x204CAF50),
                  label: Text(
                    loop.name ?? "Unclaimed Loop",
                    style: const TextStyle(color: Color(0xFF81C784), fontSize: 12.0),
                  ),
                  side: const BorderSide(color: Color(0x404CAF50)),
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMetricDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
