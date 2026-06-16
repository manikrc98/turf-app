import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/supabase_sync_provider.dart';
import '../location/sound_manager.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _starFade;
  late Animation<double> _starScale;
  late Animation<double> _wordmarkFade;
  late Animation<double> _taglineFade;
  late Animation<double> _signinFade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Star icon fades in between 200ms and 400ms (0.125 to 0.25)
    _starFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.125, 0.25, curve: Curves.easeIn),
      ),
    );

    // Star icon pulses from 1.0 to 1.1 and back between 400ms and 800ms (0.25 to 0.50)
    _starScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 25.0, // 0ms to 400ms
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12.5, // 400ms to 600ms
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 12.5, // 600ms to 800ms
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 50.0, // 800ms to 1600ms
      ),
    ]).animate(_animController);

    // Wordmark fades up between 600ms and 900ms (0.375 to 0.5625)
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.375, 0.5625, curve: Curves.easeOut),
      ),
    );

    // Tagline fades up between 800ms and 1100ms (0.50 to 0.6875)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.50, 0.6875, curve: Curves.easeOut),
      ),
    );

    // Sign-in section fades up between 1000ms and 1300ms (0.625 to 0.8125)
    _signinFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.625, 0.8125, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerSuccessHaptic() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final syncProvider = Provider.of<SupabaseSyncProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Upper Half: Centered Logo & Branding
                  const SizedBox(height: 48),
                  
                  // App Logo
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _starFade.value,
                        child: Transform.scale(
                          scale: _starScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/turf_app_logo.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // TURF Wordmark
                  FadeTransition(
                    opacity: _wordmarkFade,
                    child: Text(
                      "TURF",
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFEBEBEB),
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 64 * 0.04,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Tagline
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      "WALK IT. OWN IT. HOLD IT.",
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 12 * 0.06,
                      ),
                    ),
                  ),
                  
                  // Whitespace separating upper and lower half
                  const SizedBox(height: 120),

                  // Lower Half: Sign-In Section
                  FadeTransition(
                    opacity: _signinFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Divider Line
                        Container(
                          height: 1,
                          color: const Color(0xFF2A2A2A),
                        ),
                        const SizedBox(height: 20),
                        
                        // Sign-In Monospace Label
                        Text(
                          "SIGN IN TO CLAIM YOUR TURF",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF444444),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 11 * 0.06,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Google Sign-In Button or Spinner
                        if (syncProvider.isSyncing)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFFB8FF00), // Lime green #B8FF00 spinner
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEBEBEB),
                                foregroundColor: const Color(0xFF0A0A0A),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero, // Zero border-radius
                                ),
                              ),
                              onPressed: () async {
                                 HapticFeedback.heavyImpact(); // Heavy impact on tap
                                 SoundManager.playButtonClick();
                                 final success = await syncProvider.signInWithGoogle();
                                 if (success) {
                                   SoundManager.playLogin(); // Login success sound
                                   _triggerSuccessHaptic(); // Success feedback
                                 } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF141414),
                                      behavior: SnackBarBehavior.floating,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      content: Text(
                                        "SIGN_IN_FAILED",
                                        style: GoogleFonts.jetBrainsMono(
                                          color: const Color(0xFFFF3B3B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Official G logo
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Image.asset(
                                      'assets/google_logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "SIGN IN WITH GOOGLE",
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0A0A0A),
                                      letterSpacing: 14 * 0.06,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
