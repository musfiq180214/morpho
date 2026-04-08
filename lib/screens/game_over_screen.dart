import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'home_screen.dart';
import 'game_screen.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final isNewRecord = gs.score >= gs.highScore && gs.score > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Background grid
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _DeadBgPainter(),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dead emoji blob
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF6B6B).withOpacity(0.1),
                          border: Border.all(
                            color: const Color(0xFFFF6B6B).withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text('💀', style: TextStyle(fontSize: 44)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Game over text
                      Text(
                        'GAME OVER',
                        style: GoogleFonts.orbitron(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFF6B6B),
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.6),
                              blurRadius: 20,
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Score box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'SCORE',
                              style: GoogleFonts.orbitron(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.4),
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gs.score.toString().padLeft(6, '0'),
                              style: GoogleFonts.orbitron(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),

                            if (isNewRecord) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        const Color(0xFFFFD700).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '★ NEW RECORD',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 10,
                                    color: const Color(0xFFFFD700),
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'BEST  ',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.3),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    gs.highScore.toString().padLeft(6, '0'),
                                    style: GoogleFonts.orbitron(
                                      fontSize: 16,
                                      color: const Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Play again button
                      _ActionButton(
                        label: 'PLAY AGAIN',
                        color: const Color(0xFF00FFD1),
                        onTap: () {
                          context.read<GameState>().startGame();
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const GameScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Home button
                      _ActionButton(
                        label: 'HOME',
                        color: Colors.white.withOpacity(0.15),
                        textColor: Colors.white.withOpacity(0.7),
                        onTap: () {
                          context.read<GameState>().resetToHome();
                          Navigator.of(context).pushAndRemoveUntil(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const HomeScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                            (_) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: textColor == null
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor ?? const Color(0xFF0A0A1A),
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeadBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B6B).withOpacity(0.025)
      ..strokeWidth = 1;

    for (int i = -5; i < 20; i++) {
      final x = i * 70.0;
      canvas.drawLine(Offset(x, 0), Offset(x + size.height * 0.4, size.height),
          paint);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6B6B).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.4),
        width: size.width,
        height: size.height * 0.7,
      ));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_) => false;
}
