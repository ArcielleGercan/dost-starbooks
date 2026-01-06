import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import 'login.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AnimationController _bounceController;
  late AnimationController _buttonScaleController;
  late Animation<double> _flashOpacity;
  late Animation<double> _bounceAnimation;
  late Animation<double> _buttonScale;

  bool _showBackground = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    // Start background music on loop
    _startBackgroundMusic();

    // Flash animation - blue screen fades out
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _flashOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    ));

    // Initial bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -150, end: 30)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 30, end: 0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_bounceController);

    // Button scale animation for press effect
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );

    _startAnimationSequence();
  }

  @override
  void dispose() {
    _flashController.dispose();
    _bounceController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  void _startBackgroundMusic() async {
    try {
      // ✅ ADD THIS LINE - Preload the audio first
      await FlameAudio.audioCache.load('audio/homepage_music.mp3');

      // Then play it
      await FlameAudio.bgm.play('audio/homepage_music.mp3', volume: 0.5);
    } catch (e) {
      debugPrint('Background music not found: $e');
    }
  }

  void _startAnimationSequence() async {
    // Wait a moment to show the blue screen
    await Future.delayed(const Duration(milliseconds: 300));

    // Show background image
    setState(() {
      _showBackground = true;
    });

    // Start flash animation to fade out blue overlay
    await _flashController.forward();

    // Show content and start bounce
    setState(() {
      _showContent = true;
    });

    await _bounceController.forward();
  }

  void goToLogin() async {
    // Play button click sound
    try {
      await FlameAudio.play('click1.wav');
    } catch (e) {
      // If sound file doesn't exist, continue without sound
      debugPrint('Button click sound not found: $e');
    }

    // Animate button press
    await _buttonScaleController.forward();
    await _buttonScaleController.reverse();

    // Navigate to login with circular reveal transition
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            return AnimatedBuilder(
              animation: curvedAnimation,
              builder: (context, child) {
                return ClipPath(
                  clipper: CircularRevealClipper(
                    fraction: curvedAnimation.value,
                    centerAlignment: Alignment.center,
                  ),
                  child: child,
                );
              },
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _flashController,
        _bounceController,
        _buttonScaleController,
      ]),
      builder: (context, child) {
        final double currentOffset = _showContent ? _bounceAnimation.value : 0;

        return Scaffold(
          body: Stack(
            children: [
              // Background image (shows after blue flash)
              if (_showBackground)
                Positioned.fill(
                  child: Image.asset(
                    'assets/backgrounds/sslogo.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              // Blue flash overlay (fades out)
              Positioned.fill(
                child: Opacity(
                  opacity: _flashOpacity.value,
                  child: Container(
                    color: const Color(0xFF94D2FD),
                  ),
                ),
              ),
              // Content (logo and button) - animated
              Center(
                child: _showContent
                    ? Transform.translate(
                  offset: Offset(0, currentOffset),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images-logo/starbooksmainlogo.png',
                        height: 500,
                      ),
                      const SizedBox(height: 50),
                      Transform.scale(
                        scale: _buttonScale.value,
                        child: ElevatedButton(
                          onPressed: goToLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDD000),
                            foregroundColor: const Color(0xFF816A03),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'START',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Circular Reveal Clipper
class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Alignment centerAlignment;

  CircularRevealClipper({
    required this.fraction,
    this.centerAlignment = Alignment.center,
  });

  @override
  Path getClip(Size size) {
    final center = centerAlignment.alongSize(size);
    final radius = math.sqrt(math.pow(size.width, 2) + math.pow(size.height, 2)) * fraction;

    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return fraction != oldClipper.fraction || centerAlignment != oldClipper.centerAlignment;
  }
}