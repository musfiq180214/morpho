import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class BlobPainter extends CustomPainter {
  final ShapeType shape;
  final double morphProgress; // 0.0 to 1.0
  final double pulseAnim;
  final double wobbleAnim;
  final Color primaryColor;
  final Color glowColor;
  final bool isDead;

  BlobPainter({
    required this.shape,
    required this.morphProgress,
    required this.pulseAnim,
    required this.wobbleAnim,
    required this.primaryColor,
    required this.glowColor,
    this.isDead = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.38;

    // Outer glow
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(isDead ? 0.1 : 0.3 + 0.1 * pulseAnim)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDead ? 4 : 16);

    // Main fill
    final fillPaint = Paint()
      ..color = isDead
          ? primaryColor.withOpacity(0.3)
          : primaryColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Highlight paint
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(isDead ? 0.05 : 0.25)
      ..style = PaintingStyle.fill;

    // Border
    final borderPaint = Paint()
      ..color = isDead ? glowColor.withOpacity(0.2) : glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Draw glow
    final glowPath = _buildShapePath(center, baseRadius * 1.25, shape);
    canvas.drawPath(glowPath, glowPaint);

    // Draw main shape
    final shapePath = _buildShapePath(center, baseRadius, shape);
    canvas.drawPath(shapePath, fillPaint);
    canvas.drawPath(shapePath, borderPaint);

    // Highlight (inner light)
    if (!isDead) {
      final highlightPath = _buildShapePath(
        Offset(center.dx - baseRadius * 0.15, center.dy - baseRadius * 0.15),
        baseRadius * 0.35,
        ShapeType.circle,
      );
      canvas.drawPath(highlightPath, highlightPaint);
    }

    // Eyes
    if (!isDead) {
      _drawEyes(canvas, center, baseRadius, shape);
    } else {
      _drawDeadEyes(canvas, center, baseRadius);
    }
  }

  Path _buildShapePath(Offset center, double radius, ShapeType s) {
    switch (s) {
      case ShapeType.circle:
        return _circlePath(center, radius);
      case ShapeType.square:
        return _squarePath(center, radius);
      case ShapeType.triangle:
        return _trianglePath(center, radius);
      case ShapeType.star:
        return _starPath(center, radius);
    }
  }

  Path _circlePath(Offset center, double radius) {
    final wobble = radius * 0.06 * wobbleAnim;
    final path = Path();
    const steps = 32;
    for (int i = 0; i <= steps; i++) {
      final angle = (i / steps) * 2 * math.pi;
      final r = radius + wobble * math.sin(angle * 3 + wobbleAnim * 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _squarePath(Offset center, double radius) {
    final s = radius * 0.88;
    final wobble = radius * 0.04 * wobbleAnim;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: center,
            width: s * 2 + wobble,
            height: s * 2 - wobble),
        Radius.circular(radius * 0.18),
      ));
  }

  Path _trianglePath(Offset center, double radius) {
    final path = Path();
    final wobble = radius * 0.05 * wobbleAnim;
    path.moveTo(center.dx, center.dy - radius - wobble);
    path.lineTo(center.dx + radius * 0.95, center.dy + radius * 0.55 + wobble);
    path.lineTo(center.dx - radius * 0.95, center.dy + radius * 0.55 + wobble);
    path.close();
    return path;
  }

  Path _starPath(Offset center, double radius) {
    final path = Path();
    const points = 5;
    final innerR = radius * 0.45;
    final wobble = radius * 0.04 * wobbleAnim;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? radius + wobble : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawEyes(
      Canvas canvas, Offset center, double radius, ShapeType shape) {
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = const Color(0xFF0A0A1A)
      ..style = PaintingStyle.fill;

    double eyeY = center.dy - radius * 0.15;
    if (shape == ShapeType.triangle) eyeY = center.dy + radius * 0.1;

    final eyeR = radius * 0.14;
    final eyeSpacing = radius * 0.32;

    // Left eye
    canvas.drawCircle(
        Offset(center.dx - eyeSpacing, eyeY), eyeR, eyePaint);
    canvas.drawCircle(
        Offset(center.dx - eyeSpacing + eyeR * 0.2, eyeY + eyeR * 0.15),
        eyeR * 0.5,
        pupilPaint);

    // Right eye
    canvas.drawCircle(Offset(center.dx + eyeSpacing, eyeY), eyeR, eyePaint);
    canvas.drawCircle(
        Offset(center.dx + eyeSpacing + eyeR * 0.2, eyeY + eyeR * 0.15),
        eyeR * 0.5,
        pupilPaint);
  }

  void _drawDeadEyes(Canvas canvas, Offset center, double radius) {
    final eyePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final eyeY = center.dy - radius * 0.1;
    final eyeR = radius * 0.12;
    final eyeSpacing = radius * 0.32;

    // X eyes
    for (final dx in [-eyeSpacing, eyeSpacing]) {
      final ex = center.dx + dx;
      canvas.drawLine(
          Offset(ex - eyeR, eyeY - eyeR), Offset(ex + eyeR, eyeY + eyeR), eyePaint);
      canvas.drawLine(
          Offset(ex + eyeR, eyeY - eyeR), Offset(ex - eyeR, eyeY + eyeR), eyePaint);
    }
  }

  @override
  bool shouldRepaint(BlobPainter old) =>
      old.shape != shape ||
      old.morphProgress != morphProgress ||
      old.pulseAnim != pulseAnim ||
      old.wobbleAnim != wobbleAnim ||
      old.isDead != isDead;
}
