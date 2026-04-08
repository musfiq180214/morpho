import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HudWidget extends StatelessWidget {
  final int score;
  final int lives;
  final double speed;

  const HudWidget({
    super.key,
    required this.score,
    required this.lives,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPad + 8,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score
          Text(
            score.toString().padLeft(6, '0'),
            style: GoogleFonts.orbitron(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: const Color(0xFF00FFD1).withOpacity(0.6),
                  blurRadius: 12,
                )
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Lives
          Row(
            children: List.generate(3, (i) {
              final alive = i < lives;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: alive
                        ? const Color(0xFFFF6B6B)
                        : Colors.white.withOpacity(0.15),
                    boxShadow: alive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.6),
                              blurRadius: 6,
                            )
                          ]
                        : [],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          // Speed indicator
          Row(
            children: [
              Text(
                'SPD ',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 1.5,
                ),
              ),
              ...List.generate(7, (i) {
                final filled = i < (speed * 2).toInt();
                return Container(
                  margin: const EdgeInsets.only(right: 2),
                  width: 6,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: filled
                        ? Color.lerp(
                            const Color(0xFF00FFD1),
                            const Color(0xFFFF6B6B),
                            i / 7,
                          )
                        : Colors.white.withOpacity(0.1),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
