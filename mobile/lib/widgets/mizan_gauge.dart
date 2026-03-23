import 'dart:math';
import 'package:flutter/material.dart';

class MizanGauge extends StatefulWidget {
  final double safeToSpend;
  final double maxDiscretionary;

  const MizanGauge({
    super.key,
    required this.safeToSpend,
    required this.maxDiscretionary,
  });

  @override
  State<MizanGauge> createState() => _MizanGaugeState();
}

class _MizanGaugeState extends State<MizanGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _setupAnimation();
  }

  @override
  void didUpdateWidget(covariant MizanGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.safeToSpend != widget.safeToSpend ||
        oldWidget.maxDiscretionary != widget.maxDiscretionary) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    double targetRatio = widget.maxDiscretionary > 0
        ? widget.safeToSpend / widget.maxDiscretionary
        : 0.0;
    targetRatio = targetRatio.clamp(0.0, 1.0);

    // Provide a small visual bump if it's super low but non-zero
    if (targetRatio > 0 && targetRatio < 0.05) targetRatio = 0.05;

    _animation = Tween<double>(begin: 0.0, end: targetRatio).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _GaugePainter(_animation.value),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double ratio;

  _GaugePainter(this.ratio);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;

    const startAngle = 3 * pi / 4; // 135 degrees
    const sweepAngle = 3 * pi / 2; // 270 degrees

    // Draw background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Determine gradient based on ratio
    List<Color> colors;
    if (ratio < 0.2) {
      colors = [const Color(0xFFef4444), const Color(0xFFdc2626)]; // Alert Red
    } else if (ratio < 0.5) {
      colors = [
        const Color(0xFFf97316),
        const Color(0xFFea580c),
      ]; // Sunset Orange
    } else {
      colors = [
        const Color(0xFF30e8c9),
        const Color(0xFF10b981),
      ]; // Neon Green to Green
    }

    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: colors,
      stops: const [0.0, 1.0],
    );

    final fgPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * ratio,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.ratio != ratio;
  }
}
