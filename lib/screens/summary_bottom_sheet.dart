import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';
import '../location/sound_manager.dart';

class SummaryBottomSheet extends StatefulWidget {
  final String zoneName;
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
    required this.zoneName,
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
    required String zoneName,
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
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0A),
      builder: (context) => SummaryBottomSheet(
        zoneName: zoneName,
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

  @override
  State<SummaryBottomSheet> createState() => _SummaryBottomSheetState();
}

class _SummaryBottomSheetState extends State<SummaryBottomSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bgFade;
  late Animation<double> _statusFade;
  late Animation<double> _statusSlide;
  late Animation<double> _zoneScale;
  late Animation<double> _zoneFade;
  late Animation<double> _claimedFade;
  late Animation<double> _row1Fade;
  late Animation<double> _row2Fade;
  late Animation<double> _footerFade;
  
  // Signature moments
  late Animation<double> _flashPulse;
  late Animation<double> _starScale;
  late Animation<double> _countUpProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 1. Background fades in first at 200ms (0.1 to 0.2 progress)
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.2, curve: Curves.easeIn),
      ),
    );

    // 2. Status label slides up and fades in at 100ms delay (0.05 to 0.15 progress)
    _statusFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.15, curve: Curves.easeOut),
      ),
    );
    _statusSlide = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.15, curve: Curves.easeOut),
      ),
    );

    // 3. Zone name snaps in with a scale from 0.92 to 1.0 at 200ms delay (0.1 to 0.2 progress)
    _zoneScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.2, curve: Curves.easeOutBack),
      ),
    );
    _zoneFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.2, curve: Curves.easeOut),
      ),
    );

    // 4. CLAIMED label follows at 350ms (0.175 to 0.275 progress)
    _claimedFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.175, 0.275, curve: Curves.easeOut),
      ),
    );

    // 5. Stat grid rows fade in one row at a time starting at 650ms with 150ms between rows (0.325 to 0.50 progress)
    _row1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.325, 0.425, curve: Curves.easeOut),
      ),
    );
    _row2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.50, curve: Curves.easeOut),
      ),
    );

    // 6. Map and button follow last (0.475 to 0.575 progress)
    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.475, 0.575, curve: Curves.easeOut),
      ),
    );

    // Flash background: 0.60 to 0.80 progress (1200ms to 1600ms)
    _flashPulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 20.0,
      ),
    ]).animate(_controller);

    // ✦ scale: 0.60 to 0.80 progress (1200ms to 1600ms)
    _starScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 20.0,
      ),
    ]).animate(_controller);

    // Count up loop count: 0.60 to 0.90 progress (1200ms to 1800ms)
    _countUpProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.90, curve: Curves.easeOut),
      ),
    );

    // Haptics cues
    if (widget.loops > 0) {
      HapticFeedback.heavyImpact(); // Heavy impact on entrance
      Future.delayed(const Duration(milliseconds: 350), () {
        _triggerSuccessHaptic(); // Success feedback when CLAIMED animates
      });
    } else {
      HapticFeedback.heavyImpact(); // Heavy impact on entrance if no claim
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerSuccessHaptic() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final bool claimed = widget.loops > 0;
    final minutes = widget.durationSeconds ~/ 60;
    final seconds = widget.durationSeconds % 60;
    final durationStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Pulse background flash (Held green transparent pulse over screen)
              if (claimed)
                Positioned.fill(
                  child: Opacity(
                    opacity: _flashPulse.value * 0.04,
                    child: Container(
                      color: const Color(0xFFB8FF00),
                    ),
                  ),
                ),
              
              // Fade in base screen content
              Positioned.fill(
                child: Opacity(
                  opacity: _bgFade.value,
                  child: child,
                ),
              ),
            ],
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // 1. Status Label (Slides up, fades in)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _statusFade.value,
                      child: Transform.translate(
                        offset: Offset(0.0, _statusSlide.value),
                        child: child,
                      ),
                    );
                  },
                  child: Center(
                    child: Text(
                      claimed ? "WALK_COMPLETE" : "WALK_ENDED",
                      style: GoogleFonts.jetBrainsMono(
                        color: claimed ? const Color(0xFFB8FF00) : const Color(0xFF888888),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 11 * 0.06,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Zone Name Title (Snaps, scales from 0.92 to 1.0)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _zoneFade.value,
                      child: Transform.scale(
                        scale: _zoneScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (claimed) ...[
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _starScale.value,
                              child: Text(
                                "✦ ",
                                style: GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFFB8FF00),
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      Flexible(
                        child: Text(
                          widget.zoneName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            color: claimed ? Colors.white : const Color(0xFFEBEBEB),
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // 3. Subtitle State Label (CLAIMED / NO CLAIM)
                FadeTransition(
                  opacity: _claimedFade,
                  child: Center(
                    child: Text(
                      claimed ? "CLAIMED" : "NO CLAIM",
                      style: GoogleFonts.spaceGrotesk(
                        color: claimed ? const Color(0xFFB8FF00) : const Color(0xFF444444),
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 4. Staggered Stat Grid Rows (Flat 2x3 grid, separated by borders)
                Column(
                  children: [
                    FadeTransition(
                      opacity: _row1Fade,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
                          ),
                        ),
                        child: Table(
                          border: const TableBorder(
                            verticalInside: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
                          ),
                          children: [
                            TableRow(
                              children: [
                                _buildStatCell("STEPS", "${widget.steps}${widget.isStepEstimated ? ' (EST)' : ''}"),
                                _buildStatCell("DISTANCE", "${widget.distanceKm.toStringAsFixed(2)} KM"),
                                _buildStatCell("TIME", durationStr),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: _row2Fade,
                      child: Table(
                        border: const TableBorder(
                          verticalInside: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
                        ),
                        children: [
                          TableRow(
                            children: [
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (context, _) {
                                  final displayLoops = claimed
                                      ? (widget.loops * _countUpProgress.value).round()
                                      : 0;
                                  return _buildStatCell(
                                    "LOOPS",
                                    "$displayLoops",
                                    valueColor: claimed ? const Color(0xFFB8FF00) : null,
                                  );
                                },
                              ),
                              _buildStatCell("CADENCE", "${widget.cadence} SPM"),
                              _buildStatCell("ELEVATION", "${widget.elevationGainMetres.toStringAsFixed(1)} M"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Route Map Thumbnail & Done CTA (Fades last)
                Expanded(
                  child: FadeTransition(
                    opacity: _footerFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Map Thumbnail
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              border: Border.all(color: const Color(0xFF2A2A2A), width: 1.0),
                            ),
                            child: widget.mapSnapshot != null
                                ? Image.memory(
                                    widget.mapSnapshot!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Center(
                                    child: Text(
                                      "SYS_MAP: UNAVAILABLE",
                                      style: GoogleFonts.jetBrainsMono(
                                        color: const Color(0xFF444444),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Secondary label for no claims
                        if (!claimed) ...[
                          Center(
                            child: Text(
                              "PERIMETER: 0% · WALK THE FULL BLOCK TO CLAIM",
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFF888888),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 11 * 0.06,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Done Action Button (52px, 0 radius, green)
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB8FF00),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              SoundManager.playButtonClick();
                              Navigator.pop(context);
                              widget.onDone();
                            },
                            child: Text(
                              "DONE",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 16 * 0.04,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCell(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFF888888),
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 10 * 0.06,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: valueColor ?? const Color(0xFFEBEBEB),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
