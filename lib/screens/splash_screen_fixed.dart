import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'bank_ocr_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class Particle {
  double x, y, size, speed, angle;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    this.color = Colors.white,
  });
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _gradientAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;

  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeParticles();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble() * 500 - 250,
          y: _random.nextDouble() * 500 - 250,
          size: _random.nextDouble() * 10 + 3,
          speed: _random.nextDouble() * 3 + 1,
          angle: _random.nextDouble() * 2 * pi,
          color: [
            Colors.white,
            Color(0xFF667eea),
            Color(0xFF764ba2),
            Color(0xFFf093fb),
          ][_random.nextInt(4)].withOpacity(_random.nextDouble() * 0.6 + 0.4),
        ),
      );
    }
  }

  void _initializeAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Glow animation controller
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Scale animation with elastic effect
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.3),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.3, end: 1.0),
            weight: 60,
          ),
        ]).animate(
          CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
        );

    // Rotation animation
    _rotationAnimation = Tween<double>(begin: 0.0, end: 4 * pi).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubicEmphasized),
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutQuart),
      ),
    );

    // Gradient color animation
    _gradientAnimation =
        ColorTween(
          begin: const Color(0xFF667eea),
          end: const Color(0xFF764ba2),
        ).animate(
          CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
        );

    // Particle animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startSplashSequence() {
    // Start all animations
    _mainController.forward();

    // Navigate to main screen after delay
    Timer(const Duration(milliseconds: 4500), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const BankOCRScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.5;
            const end = 1.0;
            const curve = Curves.easeInOutCubicEmphasized;

            var scaleTween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var scaleAnimation = animation.drive(scaleTween);

            var fadeTween = Tween(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: curve));
            var fadeAnimation = animation.drive(fadeTween);

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(opacity: fadeAnimation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 1800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Widget _buildQuantumLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _glowController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 180 * _glowAnimation.value,
              height: 180 * _glowAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.3 * _glowAnimation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Main logo container
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(_scaleAnimation.value)
                ..rotateZ(_rotationAnimation.value),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                      const Color(0xFFf093fb),
                      const Color(0xFF667eea),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                    transform: GradientRotation(_rotationAnimation.value * 2),
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.8),
                      blurRadius: 50,
                      spreadRadius: 15,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Outer animated ring
                    _buildAnimatedRing(12, 3, 0.0),
                    // Middle animated ring
                    _buildAnimatedRing(25, 2, 0.3),
                    // Inner core
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.8),
                            ],
                          ).createShader(bounds);
                        },
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 54,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedRing(double margin, double width, double delay) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final delayedValue = (_mainController.value - delay).clamp(0.0, 1.0);
        final normalizedValue = (1 - delay) > 0
            ? (delayedValue / (1 - delay)).clamp(0.0, 1.0)
            : 0.0;
        return Container(
          margin: EdgeInsets.all(margin),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(normalizedValue * 0.6),
              width: width,
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleUniverse() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: QuantumParticlePainter(
            particles: _particles,
            animationValue: _particleAnimation.value,
            mainControllerValue: _mainController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHolographicText() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main title with holographic effect
              SizedBox(
                width: 300,
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'N E O S C A N',
                        speed: const Duration(milliseconds: 100),
                        textStyle: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Monospace',
                          color: Colors.white,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 20,
                              offset: Offset(3, 3),
                            ),
                            Shadow(
                              color: Color(0xFF667eea),
                              blurRadius: 30,
                              offset: Offset(-3, -3),
                            ),
                          ],
                        ),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Subtitle with futuristic effect
              AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText(
                    'QUANTUM BANKING TECHNOLOGY',
                    duration: const Duration(milliseconds: 2000),
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Monospace',
                    ),
                  ),
                ],
                totalRepeatCount: 1,
              ),
              const SizedBox(height: 50),

              // Premium Custom Progress Indicator
              _buildQuantumProgressIndicator(),
              const SizedBox(height: 20),

              // Loading text
              AnimatedTextKit(
                animatedTexts: [
                  RotateAnimatedText(
                    'INITIALIZING...',
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ),
                  RotateAnimatedText(
                    'LOADING MODULES...',
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ),
                  RotateAnimatedText(
                    'READY FOR SCAN...',
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ),
                ],
                totalRepeatCount: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuantumProgressIndicator() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress background glow
              Container(
                width: 280 * _mainController.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                      const Color(0xFFf093fb),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.8),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Animated scanning line
              Positioned(
                right: 280 * (1 - _mainController.value) - 10,
                child: Container(
                  width: 20,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNebulaBackground() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 2.0,
              colors: [
                _gradientAnimation.value ?? const Color(0xFF667eea),
                const Color(0xFF764ba2),
                const Color(0xFF2c3e50),
                Colors.black,
              ],
              stops: const [0.1, 0.4, 0.8, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: NebulaPainter(_mainController.value, _glowAnimation.value),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Nebula Background
          _buildNebulaBackground(),

          // Particle Universe
          _buildParticleUniverse(),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Quantum Logo
                _buildQuantumLogo(),
                const SizedBox(height: 100),

                // Holographic Text
                _buildHolographicText(),
              ],
            ),
          ),

          // Bottom Signature
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      AnimatedTextKit(
                        animatedTexts: [
                          ScaleAnimatedText(
                            'ADVANCED AI DOCUMENT PROCESSING',
                            duration: const Duration(milliseconds: 1500),
                            textStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.6),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ],
                        totalRepeatCount: 1,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'v3.0.0 • QUANTUM EDITION',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuantumParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final double mainControllerValue;

  QuantumParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.mainControllerValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Return early if size is zero to prevent errors
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final pulse = sin(animationValue * 2 * pi + particle.angle) * 0.5 + 0.5;
      final expansion = mainControllerValue * 2;

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.color.opacity * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final x = center.dx + particle.x * (1 + expansion * 0.5);
      final y = center.dy + particle.y * (1 + expansion * 0.5);

      // Draw main particle
      canvas.drawCircle(Offset(x, y), particle.size * (1 + pulse * 0.5), paint);

      // Draw glow effect
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(
          particle.color.opacity * 0.3 * pulse,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(Offset(x, y), particle.size * 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant QuantumParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.mainControllerValue != mainControllerValue;
  }
}

class NebulaPainter extends CustomPainter {
  final double animationValue;
  final double glowValue;

  NebulaPainter(this.animationValue, this.glowValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Return early if size is zero to prevent division by zero
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw nebula clouds
    for (int i = 0; i < 5; i++) {
      final cloudPaint = Paint()
        ..color = [
          Color(0xFF667eea),
          Color(0xFF764ba2),
          Color(0xFFf093fb),
        ][i % 3].withOpacity(0.1 + 0.05 * sin(animationValue * pi + i));

      final cloudRadius = 100 + i * 80 + sin(animationValue * 2 * pi + i) * 20;
      canvas.drawCircle(center, cloudRadius, cloudPaint);
    }

    // Draw stars - FIXED: Convert to double explicitly
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * glowValue);

    final safeWidth = size.width > 0 ? size.width : 1.0;
    final safeHeight = size.height > 0 ? size.height : 1.0;

    for (int i = 0; i < 50; i++) {
      final x = (i * 137.0) % safeWidth; // Use double literals
      final y = (i * 237.0) % safeHeight; // Use double literals
      final starSize = (i % 3 + 1).toDouble() * glowValue; // Convert to double
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NebulaPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.glowValue != glowValue;
  }
}
