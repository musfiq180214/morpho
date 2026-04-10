import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _shapeCtrl;
  late Animation<double> _floatAnim;

  int _currentShapeIndex = 0;
  final List<ShapeType> _shapes = ShapeType.values;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _shapeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Cycle through shapes
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return false;
      await _shapeCtrl.forward();
      setState(() {
        _currentShapeIndex = (_currentShapeIndex + 1) % _shapes.length;
      });
      _shapeCtrl.reset();
      return mounted;
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _bgCtrl.dispose();
    _shapeCtrl.dispose();
    super.dispose();
  }

  Color _shapeColor(ShapeType s) {
    switch (s) {
      case ShapeType.circle:
        return const Color(0xFF00FFD1);
      case ShapeType.triangle:
        return const Color(0xFFFF6B6B);
      case ShapeType.square:
        return const Color(0xFF6B9FFF);
      case ShapeType.star:
        return const Color(0xFFFFD700);
    }
  }

  void _startGame() {
    context.read<GameState>().startGame();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final size = MediaQuery.of(context).size;
    final currentShape = _shapes[_currentShapeIndex];
    final color = _shapeColor(currentShape);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _HomeBgPainter(_bgCtrl.value, color),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Title
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: _glowCtrl,
                      builder: (_, __) => Text(
                        'MORPHO',
                        style: GoogleFonts.orbitron(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                              color: color.withOpacity(0.6 + 0.3 * _glowCtrl.value),
                              blurRadius: 24 + 12 * _glowCtrl.value,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SHAPE · SHIFT · SURVIVE',
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        color: Colors.black,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Animated blob
                AnimatedBuilder(
                  animation: Listenable.merge([_floatCtrl, _glowCtrl]),
                  builder: (_, __) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: AnimatedBuilder(
                          animation: _shapeCtrl,
                          builder: (_, __) {
                            return CustomPaint(
                              painter: _HomeBlobPainter(
                                shape: currentShape,
                                color: color,
                                glowIntensity: _glowCtrl.value,
                                morphT: _shapeCtrl.value,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Shape name
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    currentShape.name,
                    key: ValueKey(currentShape),
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      color: color.withOpacity(0.8),
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // High score
                if (gs.highScore > 0) ...[
                  Text(
                    'BEST',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      color: Colors.black,
                      letterSpacing: 3,

                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gs.highScore.toString().padLeft(6, '0'),
                    style: GoogleFonts.orbitron(
                      fontSize: 22,
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Play button
                GestureDetector(
                  onTap: _startGame,
                  child: AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (_, child) => Container(
                      width: 200,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            color,
                            Color.lerp(color, Colors.white, 0.2)!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4 + 0.2 * _glowCtrl.value),
                            blurRadius: 20 + 10 * _glowCtrl.value,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: child,
                    ),
                    child: Center(
                      child: Text(
                        'PLAY',
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0A0A1A),
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // How to play
                Text(
                  'TAP SHAPES TO MORPH · MATCH THE HOLE',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    color: Colors.black,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBgPainter extends CustomPainter {
  final double t;
  final Color accent;
  _HomeBgPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    // Moving diagonal lines
    for (int i = -5; i < 20; i++) {
      final x = (i * 60 + t * 40) % (size.width + 60) - 30;
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height * 0.3, size.height), paint);
    }

    // Accent glow at center-bottom
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withOpacity(0.08), Colors.transparent],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.55),
        width: size.width * 1.2,
        height: size.height * 0.8,
      ));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_HomeBgPainter old) => old.t != t || old.accent != accent;
}

class _HomeBlobPainter extends CustomPainter {
  final ShapeType shape;
  final Color color;
  final double glowIntensity;
  final double morphT;

  _HomeBlobPainter({
    required this.shape,
    required this.color,
    required this.glowIntensity,
    required this.morphT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;

    // Glow rings
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.06 * i * (0.7 + 0.3 * glowIntensity))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * i);
      canvas.drawCircle(center, r * (1 + 0.15 * i), glowPaint);
    }

    // Fill
    final fillPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = _buildPath(center, r, shape);

    // Scale down on morph
    final scale = morphT > 0
        ? 1.0 - morphT * 0.3 + (morphT > 0.5 ? (morphT - 0.5) * 0.6 : 0)
        : 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
    canvas.restore();
  }

  Path _buildPath(Offset center, double r, ShapeType s) {
    switch (s) {
      case ShapeType.circle:
        return Path()..addOval(Rect.fromCircle(center: center, radius: r));
      case ShapeType.square:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: r * 1.8, height: r * 1.8),
            Radius.circular(r * 0.2),
          ));
      case ShapeType.triangle:
        return Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r * 0.95, center.dy + r * 0.6)
          ..lineTo(center.dx - r * 0.95, center.dy + r * 0.6)
          ..close();
      case ShapeType.star:
        final path = Path();
        const pts = 5;
        final inner = r * 0.45;
        for (int i = 0; i < pts * 2; i++) {
          final angle = (i * math.pi / pts) - math.pi / 2;
          final rad = i.isEven ? r : inner;
          final x = center.dx + rad * math.cos(angle);
          final y = center.dy + rad * math.sin(angle);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        path.close();
        return path;
    }
  }

  @override
  bool shouldRepaint(_HomeBlobPainter old) =>
      old.shape != shape ||
      old.glowIntensity != glowIntensity ||
      old.morphT != morphT;
}
