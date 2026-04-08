import 'package:flutter/material.dart';
import '../models/game_state.dart';

class Wall {
  final String id;
  final ShapeType holeShape;
  double x; // 0.0 to 1.0 (normalized)
  final double holeY; // 0.0 to 1.0

  Wall({
    required this.id,
    required this.holeShape,
    required this.x,
    required this.holeY,
  });

  static Wall generate(String id, double startX) {
    final shapes = ShapeType.values;
    final shape = shapes[(id.hashCode.abs()) % shapes.length];
    return Wall(
      id: id,
      holeShape: shape,
      x: startX,
      holeY: 0.3 + (id.hashCode.abs() % 40) / 100.0,
    );
  }
}

class WallPainter extends CustomPainter {
  final Wall wall;
  final Color wallColor;
  final Color holeColor;
  final Color glowColor;
  final double animValue;

  WallPainter({
    required this.wall,
    required this.wallColor,
    required this.holeColor,
    required this.glowColor,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wallX = wall.x * size.width;
    const wallWidth = 52.0;
    const holeSize = 80.0;
    final holeY = wall.holeY * size.height;

    // Glow effect
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.18 + 0.07 * animValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    // Wall body
    final wallPaint = Paint()
      ..color = wallColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = glowColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw top wall section
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(wallX - wallWidth / 2, 0, wallWidth, holeY - holeSize / 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(topRect, glowPaint);
    canvas.drawRRect(topRect, wallPaint);
    canvas.drawRRect(topRect, borderPaint);

    // Draw bottom wall section
    final bottomTop = holeY + holeSize / 2;
    final bottomRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          wallX - wallWidth / 2, bottomTop, wallWidth, size.height - bottomTop),
      const Radius.circular(4),
    );
    canvas.drawRRect(bottomRect, glowPaint);
    canvas.drawRRect(bottomRect, wallPaint);
    canvas.drawRRect(bottomRect, borderPaint);

    // Draw shape hint in hole
    _drawShapeHint(canvas, Offset(wallX, holeY), holeSize * 0.55, glowColor);
  }

  void _drawShapeHint(
      Canvas canvas, Offset center, double size, Color color) {
    final hintPaint = Paint()
      ..color = color.withOpacity(0.25 + 0.1 * animValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    switch (wall.holeShape) {
      case ShapeType.circle:
        canvas.drawCircle(center, size / 2, hintPaint);
        break;
      case ShapeType.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: center, width: size * 0.85, height: size * 0.85),
            const Radius.circular(6),
          ),
          hintPaint,
        );
        break;
      case ShapeType.triangle:
        final path = Path();
        path.moveTo(center.dx, center.dy - size / 2);
        path.lineTo(center.dx + size / 2, center.dy + size / 2);
        path.lineTo(center.dx - size / 2, center.dy + size / 2);
        path.close();
        canvas.drawPath(path, hintPaint);
        break;
      case ShapeType.star:
        _drawStar(canvas, center, size / 2, hintPaint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * 3.14159265 / points) - 3.14159265 / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double angle) => _mathCos(angle);
  double _sin(double angle) => _mathSin(angle);

  double _mathCos(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / (2 * i * (2 * i - 1));
      result += term;
    }
    return result;
  }

  double _mathSin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(WallPainter oldDelegate) =>
      oldDelegate.wall.x != wall.x || oldDelegate.animValue != animValue;
}
