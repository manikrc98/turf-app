import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MapSkeletonScreen extends StatefulWidget {
  const MapSkeletonScreen({super.key});

  @override
  State<MapSkeletonScreen> createState() => _MapSkeletonScreenState();
}

class _MapSkeletonScreenState extends State<MapSkeletonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top HUD coordinates ticker placeholder
            _buildSkeletonHUD(),

            // Map Area Skeleton
            Expanded(
              child: Stack(
                children: [
                  // Abstract street/map grid painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SkeletonGridPainter(),
                    ),
                  ),

                  // Central pulsing location beacon
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFB8FF00).withOpacity(0.5 * _pulseAnimation.value),
                                blurRadius: _glowAnimation.value,
                                spreadRadius: _glowAnimation.value / 3,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB8FF00),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Pulse indicator / loading message overlay on map
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 40,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                border: Border.all(color: const Color(0xFF2A2A2A), width: 1.0),
                              ),
                              child: Text(
                                "LOADING MAP SENSOR SYSTEM...",
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFFB8FF00),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 10 * 0.06,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Mock Location FAB on bottom right
                  Positioned(
                    bottom: 88.0,
                    right: 16.0,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        border: Border.all(color: const Color(0xFF2A2A2A), width: 1.0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.gps_fixed_outlined,
                          color: Color(0xFF444444),
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

            // Muted Bottom Navigation Bar
            _buildBottomNav(bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonHUD() {
    return Container(
      height: 28,
      width: double.infinity,
      color: const Color(0xB30A0A0A),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        "SYS_STATUS: CONNECTING · LAT: -- · LNG: --",
        style: GoogleFonts.jetBrainsMono(
          color: const Color(0xFF444444),
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 10 * 0.06,
        ),
      ),
    );
  }

  Widget _buildBottomNav(double bottomPadding) {
    return Container(
      height: 64.0 + bottomPadding,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A), width: 1.0),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem("MAP", Icons.map_outlined, isHighlighted: true),
          _buildNavItem("HISTORY", Icons.history_outlined, isHighlighted: false),
          _buildNavItem("MORE", Icons.more_horiz_outlined, isHighlighted: false),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, {required bool isHighlighted}) {
    final Color color = isHighlighted ? const Color(0xFFB8FF00).withOpacity(0.3) : const Color(0xFF222222);
    return Container(
      width: 80,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 9 * 0.06,
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw background grid lines
    const double gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some mock diagonal paths simulating streets/trails
    final pathPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final roadPath = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.4)
      ..lineTo(size.width * 0.6, size.height * 0.35)
      ..lineTo(size.width, size.height * 0.6)
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.4, size.height * 0.4)
      ..lineTo(size.width * 0.3, size.height)
      ..moveTo(size.width * 0.7, size.height)
      ..lineTo(size.width * 0.6, size.height * 0.35)
      ..lineTo(size.width * 0.9, 0);

    canvas.drawPath(roadPath, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapViewportSkeleton extends StatefulWidget {
  const MapViewportSkeleton({super.key});

  @override
  State<MapViewportSkeleton> createState() => _MapViewportSkeletonState();
}

class _MapViewportSkeletonState extends State<MapViewportSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Abstract street/map grid painter
        Positioned.fill(
          child: CustomPaint(
            painter: SkeletonGridPainter(),
          ),
        ),

        // Central pulsing location beacon
        Center(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB8FF00).withOpacity(0.5 * _pulseAnimation.value),
                      blurRadius: _glowAnimation.value,
                      spreadRadius: _glowAnimation.value / 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8FF00),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Pulse indicator / loading message overlay on map
        Positioned(
          left: 0,
          right: 0,
          top: 40,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      border: Border.all(color: const Color(0xFF2A2A2A), width: 1.0),
                    ),
                    child: Text(
                      "LOADING MAP SENSOR SYSTEM...",
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFB8FF00),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 10 * 0.06,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
