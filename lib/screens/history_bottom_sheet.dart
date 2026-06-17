import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/walk_session_summary.dart';
import '../models/local_walk_session.dart';
import '../repositories/history_repository.dart';
import '../repositories/isar_service.dart';
import '../location/sound_manager.dart'; // Import SoundManager
import '../providers/supabase_sync_provider.dart';

class HistoryBottomSheet extends StatefulWidget {
  final VoidCallback? onStartWalking;

  const HistoryBottomSheet({super.key, this.onStartWalking});

  // Keep static show for backward compatibility/reference if needed, but not used in tabs
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
  StreamSubscription? _historySubscription;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _subscribeToHistoryChanges();
  }

  void _subscribeToHistoryChanges() async {
    try {
      final isar = await IsarService.getDB();
      _historySubscription = isar.localWalkSessions.watchLazy().listen((_) {
        if (mounted) {
          _loadHistory();
        }
      });
    } catch (e) {
      print("Failed to subscribe to history changes: $e");
    }
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);
    final uid = syncProvider.currentUserId ?? "guest_user";
    final historyList = await _historyRepo.getHistory(uid);
    setState(() {
      _history = historyList;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    HapticFeedback.heavyImpact();
    SoundManager.playDeleteHistory(); // Play delete history sound
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          "CLEAR WALK HISTORY?",
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "ARE YOU SURE YOU WANT TO PERMANENTLY DELETE ALL WALK SESSIONS?",
          style: GoogleFonts.jetBrainsMono(color: const Color(0xFF888888), fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              SoundManager.playButtonClick();
              Navigator.pop(context, false);
            },
            child: Text("CANCEL", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFFFF3B3B),
              side: const BorderSide(color: Color(0xFFFF3B3B)),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              SoundManager.playDeleteHistory();
              Navigator.pop(context, true);
            },
            child: Text("CLEAR ALL", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final syncProvider = Provider.of<SupabaseSyncProvider>(context, listen: false);
      final uid = syncProvider.currentUserId ?? "guest_user";
      await _historyRepo.clearHistory(uid);
      _loadHistory();
    }
  }

  Future<void> _deleteSession(WalkSessionSummary session) async {
    await _historyRepo.deleteSession(session.id);
    // Remove from local list without reloading database to prevent disrupting animations
    setState(() {
      _history.removeWhere((s) => s.id == session.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A), // Styleguide dark bg
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "// WALK_HISTORY",
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF444444),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 11 * 0.06,
                ),
              ),
              if (_history.isNotEmpty)
                GestureDetector(
                  onTap: _clearHistory,
                  child: Text(
                    "DELETE_ALL",
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFFF3B3B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 11 * 0.06,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // History Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFB8FF00))) // Lime green #B8FF00
                : _history.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final session = _history[index];
                          return HistoryRowWidget(
                            key: ValueKey(session.id),
                            session: session,
                            onDelete: () => _deleteSession(session),
                          );
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
          Text(
            "NO WALKS YET",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 20 * 0.04,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "GET OUT THERE. WALK A BLOCK. OWN IT.",
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFF888888),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 11 * 0.06,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              SoundManager.playButtonClick();
              if (widget.onStartWalking != null) {
                widget.onStartWalking!();
              }
            },
            child: Text(
              "START WALKING →",
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFB8FF00), // Lime green #B8FF00
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 12 * 0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryRowWidget extends StatefulWidget {
  final WalkSessionSummary session;
  final VoidCallback onDelete;

  const HistoryRowWidget({
    super.key,
    required this.session,
    required this.onDelete,
  });

  @override
  State<HistoryRowWidget> createState() => _HistoryRowWidgetState();
}

class _HistoryRowWidgetState extends State<HistoryRowWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heightFactorAnimation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Slide left (x from 0.0 to -1.1) over 250ms (0.0 to 0.55 interval)
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.1, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );

    // Fade out (opacity from 1.0 to 0.0) over 250ms (0.0 to 0.55 interval)
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );

    // Height collapse (factor from 1.0 to 0.0) over 200ms (0.55 to 1.0 interval)
    _heightFactorAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.linear),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDeleteAnimation() {
    setState(() {
      _isDeleting = true;
    });
    HapticFeedback.heavyImpact();
    SoundManager.playDeleteHistory(); // playDeleteHistory instead of playRetroClick
    _controller.forward().then((_) {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the name of the zone
    final String zoneName;
    if (widget.session.loops.isNotEmpty) {
      zoneName = widget.session.loops.first.name ?? "GHOST_ZONE";
    } else {
      zoneName = "GHOST_ZONE";
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _heightFactorAnimation,
          axis: Axis.vertical,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          border: Border(
            bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
          ),
        ),
        child: Row(
          children: [
            // Left Accent Bar (3px width)
            Container(
              width: 3,
              height: 72,
              color: widget.session.loopCount > 0
                  ? const Color(0xFFB8FF00) // HELD lime green #B8FF00
                  : const Color(0xFF4A4A4A), // Ghost grey
            ),
            const SizedBox(width: 16),
            
            // Text Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Date & Time (JetBrains Mono 11px #888888 uppercase)
                    Text(
                      widget.session.dateTime.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF888888),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 11 * 0.06,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Zone name (Space Grotesk 700 16px uppercase)
                    Text(
                      zoneName.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFEBEBEB),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 16 * 0.04,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Stats line (JetBrains Mono 11px #888888)
                    Row(
                      children: [
                        Text(
                          "${widget.session.steps} STEPS · ${widget.session.distanceKm.toStringAsFixed(2)} KM · ${widget.session.loopCount} LOOPS",
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF888888),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 11 * 0.06,
                          ),
                        ),
                        if (widget.session.loopCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            "✦",
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFFB8FF00), // Lime green #B8FF00
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Delete Action Trigger
            IconButton(
              icon: const Icon(Icons.delete_outline_outlined, color: Color(0xFFFF3B3B), size: 22),
              onPressed: _isDeleting ? null : _startDeleteAnimation,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
