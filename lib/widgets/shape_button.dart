import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class ShapeButton extends StatefulWidget {
  final ShapeType shape;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const ShapeButton({
    super.key,
    required this.shape,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  State<ShapeButton> createState() => _ShapeButtonState();
}

class _ShapeButtonState extends State<ShapeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _scaleCtrl.reverse();
  void _onTapUp(_) {
    _scaleCtrl.forward();
    widget.onTap();
  }

  void _onTapCancel() => _scaleCtrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.color.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isActive
                  ? widget.color
                  : widget.color.withOpacity(0.35),
              width: widget.isActive ? 2 : 1,
            ),
            boxShadow: widget.isActive
                ? [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ]
                : [],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(36, 36),
              painter: _ShapeIconPainter(
                shape: widget.shape,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeIconPainter extends CustomPainter {
  final ShapeType shape;
  final Color color;

  _ShapeIconPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.44;

    switch (shape) {
      case ShapeType.circle:
        canvas.drawCircle(center, r, paint);
        break;
      case ShapeType.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: r * 1.7, height: r * 1.7),
            Radius.circular(r * 0.2),
          ),
          paint,
        );
        break;
      case ShapeType.triangle:
        final path = Path();
        path.moveTo(center.dx, center.dy - r);
        path.lineTo(center.dx + r * 0.95, center.dy + r * 0.6);
        path.lineTo(center.dx - r * 0.95, center.dy + r * 0.6);
        path.close();
        canvas.drawPath(path, paint);
        break;
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
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_ShapeIconPainter old) =>
      old.shape != shape || old.color != color;
}