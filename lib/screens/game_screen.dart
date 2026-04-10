import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../models/game_state.dart';
import '../models/wall.dart';
import '../widgets/blob_painter.dart';
import '../widgets/shape_button.dart';
import '../widgets/hud_widget.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _wobbleController;
  late AnimationController _bgController;
  late AnimationController _wallAnimController;

  Timer? _gameTimer;
  final List<Wall> _walls = [];
  int _wallCounter = 0;
  final double _wallSpacing = 1.1;

  // --- Flappy Physics Variables ---
  double _blobY = 0.3; // Start higher up
  double _blobVelocity = 0.0;
  final double _gravity = 0.0004;
  final double _jumpStrength = -0.011;
  // --------------------------------

  final List<_Particle> _particles = [];
  Timer? _particleTimer;
  bool _isHitFlashing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _wobbleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _bgController =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _wallAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _spawnInitialWalls();
    _startGameLoop();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) _spawnParticle();
    });
  }

  void _spawnInitialWalls() {
    for (int i = 0; i < 4; i++) {
      _walls.add(Wall.generate('w${_wallCounter++}', 1.5 + i * _wallSpacing));
    }
  }

  void _startGameLoop() {
    _gameTimer =
        Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (timer) {
          if (!mounted) return;
          final gs = context.read<GameState>();
          if (gs.isPaused ||
              gs.phase == GamePhase.dead ||
              gs.phase == GamePhase.idle) return;

          setState(() {
            // 1. Gravity Physics
            _blobVelocity += _gravity;
            _blobY += _blobVelocity;

            // 2. Floor/Ceiling Constraints
            if (_blobY > 0.88) { // Hit the bottom
              _blobY = 0.88;
              _triggerHit(gs);
            }
            if (_blobY < 0.02) { // Hit the top
              _blobY = 0.02;
              _blobVelocity = 0;
            }

            // 3. Wall Movement
            final speed = gs.speed * 0.005;
            for (final wall in _walls)
              wall.x -= speed;

            _checkCollisions(gs);

            _walls.removeWhere((w) {
              if (w.x < -0.15) {
                gs.onWallPassed();
                return true;
              }
              return false;
            });

            if (_walls.isEmpty || _walls.last.x < 1.0 - _wallSpacing + 0.3) {
              _walls.add(Wall.generate('w${_wallCounter++}', 1.2));
            }
            _updateParticles();
          });
        });
  }

  void _checkCollisions(GameState gs) {
    for (final wall in _walls) {
      if (wall.x > 0.18 && wall.x < 0.35) {
        final holeY = wall.holeY;
        const holeHalf = 0.11;
        final blobInHoleVertically = (_blobY - holeY).abs() < holeHalf;
        final shapeMatches = wall.holeShape == gs.currentShape;
        if (!blobInHoleVertically || !shapeMatches) _triggerHit(gs);
      }
    }
  }

  void _triggerHit(GameState gs) {
    if (_isHitFlashing) return;
    _isHitFlashing = true;
    HapticFeedback.heavyImpact();
    gs.onHit();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isHitFlashing = false);
    });
    if (gs.phase == GamePhase.dead && mounted) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted)
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GameOverScreen()));
      });
    }
  }

  void _spawnParticle() {
    final gs = context.read<GameState>();
    if (gs.phase != GamePhase.playing && gs.phase != GamePhase.morphing) return;
    final rng = math.Random();
    _particles.add(_Particle(
      x: 0.15 + rng.nextDouble() * 0.08,
      y: _blobY + (rng.nextDouble() - 0.5) * 0.12,
      vx: -(rng.nextDouble() * 0.006 + 0.002),
      vy: (rng.nextDouble() - 0.5) * 0.004,
      life: 1.0,
      size: rng.nextDouble() * 5 + 2,
      color: _getShapeColor(gs.currentShape),
    ));
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.life -= 0.04;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  Color _getShapeColor(ShapeType shape) {
    switch (shape) {
      case ShapeType.circle: return const Color(0xFF00BFA5);
      case ShapeType.triangle: return const Color(0xFFFF5252);
      case ShapeType.square: return const Color(0xFF448AFF);
      case ShapeType.star: return const Color(0xFFFBC02D);
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _particleTimer?.cancel();
    _pulseController.dispose();
    _wobbleController.dispose();
    _bgController.dispose();
    _wallAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final size = MediaQuery.of(context).size;
    final shapeColor = _getShapeColor(gs.currentShape);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Gameplay Layer (Tap to Jump)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (gs.isPaused || gs.phase == GamePhase.dead) return;
              setState(() {
                _blobVelocity = _jumpStrength; // Applied Jump
              });
            },
            child: Stack(
              children: [
                _buildBackground(size),
                _buildGameCanvas(size, gs, shapeColor),
              ],
            ),
          ),

          HudWidget(score: gs.score, lives: gs.lives, speed: gs.speed),

          if (_isHitFlashing)
            Positioned.fill(
                child: IgnorePointer(
                    child: Container(color: Colors.red.withOpacity(0.2)))),

          // 2. Control Layer
          _buildShapeControls(gs, size),

          // Pause Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: IconButton(
              icon: Icon(gs.isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.black87),
              onPressed: gs.togglePause,
            ),
          ),

          if (gs.isPaused) _buildPauseOverlay(gs),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (_, __) =>
          CustomPaint(size: size, painter: _BackgroundPainter(_bgController.value)),
    );
  }

  Widget _buildGameCanvas(Size size, GameState gs, Color shapeColor) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _wobbleController, _wallAnimController]),
      builder: (_, __) => CustomPaint(
        size: size,
        painter: _GameCanvasPainter(
          walls: _walls,
          particles: _particles,
          blobY: _blobY,
          shape: gs.currentShape,
          pulseAnim: _pulseController.value,
          wobbleAnim: _wobbleController.value,
          wallAnim: _wallAnimController.value,
          shapeColor: shapeColor,
          glowColor: shapeColor,
          isDead: gs.phase == GamePhase.dead,
        ),
      ),
    );
  }

  Widget _buildShapeControls(GameState gs, Size size) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 24
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.95)
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ShapeType.values.map((shape) {
            final color = _getShapeColor(shape);
            final bool isActive = gs.currentShape == shape;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                gs.morphTo(shape);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // We remove the border and add a shadow (shade) instead
                  boxShadow: isActive
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    )
                  ]
                      : [],
                ),
                child: ShapeButton(
                  shape: shape,
                  isActive: true, // Show the shape's actual color
                  color: color,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    gs.morphTo(shape);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(GameState gs) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: gs.togglePause,
        child: GlassContainer(
          blur: 15,
          opacity: 0.1,
          borderRadius: BorderRadius.zero,
          color: Colors.white.withOpacity(0.2),
          border: Border.fromBorderSide(BorderSide.none),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PAUSED',
                  style: GoogleFonts.orbitron(
                    color: Colors.black, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Tap to Resume',
                  style: GoogleFonts.rajdhani(
                    color: Colors.black54, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- PAINTERS REMAINING SIMILAR BUT ADAPTED FOR WHITE THEME ---

class _GameCanvasPainter extends CustomPainter {
  final List<Wall> walls;
  final List<_Particle> particles;
  final double blobY;
  final ShapeType shape;
  final double pulseAnim;
  final double wobbleAnim;
  final double wallAnim;
  final Color shapeColor;
  final Color glowColor;
  final bool isDead;

  _GameCanvasPainter({
    required this.walls, required this.particles, required this.blobY,
    required this.shape, required this.pulseAnim, required this.wobbleAnim,
    required this.wallAnim, required this.shapeColor, required this.glowColor,
    required this.isDead,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, Paint()..color = p.color.withOpacity(p.life * 0.4));
    }

    for (final wall in walls) {
      WallPainter(
        wall: wall,
        wallColor: const Color(0xFFF2F2F2),
        holeColor: Colors.white,
        glowColor: shapeColor,
        animValue: wallAnim,
      ).paint(canvas, size);
    }

    final blobSize = 70.0;
    final blobOffset = Offset(size.width * 0.25 - blobSize / 2, blobY * size.height - blobSize / 2);
    canvas.save();
    canvas.translate(blobOffset.dx, blobOffset.dy);
    BlobPainter(
      shape: shape, morphProgress: 1.0, pulseAnim: pulseAnim, wobbleAnim: wobbleAnim,
      primaryColor: shapeColor, glowColor: glowColor, isDead: isDead,
    ).paint(canvas, Size(blobSize, blobSize));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WallPainter {
  final Wall wall;
  final Color wallColor;
  final Color holeColor;
  final Color glowColor;
  final double animValue;

  WallPainter({required this.wall, required this.wallColor, required this.holeColor, required this.glowColor, required this.animValue});

  void paint(Canvas canvas, Size size) {
    final wallWidth = size.width * 0.15;
    final xPos = wall.x * size.width;
    final holeY = wall.holeY * size.height;
    final holeSize = 85.0 + (math.sin(animValue * math.pi) * 4);
    final rect = Rect.fromLTWH(xPos, 0, wallWidth, size.height);
    final holeRect = Rect.fromCenter(center: Offset(xPos + wallWidth / 2, holeY), width: holeSize, height: holeSize);

    Path wallPath = Path()..addRect(rect);
    Path holePath = _getShapePath(wall.holeShape, holeRect);
    canvas.drawPath(Path.combine(PathOperation.difference, wallPath, holePath), Paint()..color = wallColor);
    canvas.drawPath(holePath, Paint()..color = glowColor.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  Path _getShapePath(ShapeType shape, Rect rect) {
    final path = Path();
    final center = rect.center;
    final r = rect.width / 2;
    if (shape == ShapeType.circle) path.addOval(rect);
    else if (shape == ShapeType.square) path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    else if (shape == ShapeType.triangle) {
      path.moveTo(center.dx, rect.top); path.lineTo(rect.right, rect.bottom); path.lineTo(rect.left, rect.bottom); path.close();
    } else {
      for (int i = 0; i < 10; i++) {
        double radius = (i % 2 == 0) ? r : r * 0.45;
        double angle = (i * 36) * math.pi / 180 - math.pi / 2;
        double x = center.dx + radius * math.cos(angle);
        double y = center.dy + radius * math.sin(angle);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      path.close();
    }
    return path;
  }
}

class _BackgroundPainter extends CustomPainter {
  final double t;
  _BackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withOpacity(0.05)..strokeWidth = 1;
    for (int i = 0; i <= 8; i++) canvas.drawLine(Offset(i * size.width / 8, 0), Offset(i * size.width / 8, size.height), p);
    double rowH = size.height / 16;
    double offset = (t * rowH * 2) % rowH;
    for (int i = -1; i <= 16; i++) canvas.drawLine(Offset(0, i * rowH + offset), Offset(size.width, i * rowH + offset), p);
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.t != t;
}

class _Particle {
  double x, y, vx, vy, life, size;
  Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.size, required this.color});
}