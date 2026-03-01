import 'dart:math';
import 'package:flutter/material.dart';
import 'package:einhod_water/core/theme/app_theme.dart';

class LiquidLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const LiquidLoadingIndicator({
    super.key,
    this.size = 50.0,
    this.color,
  });

  @override
  State<LiquidLoadingIndicator> createState() => _LiquidLoadingIndicatorState();
}

class _LiquidLoadingIndicatorState extends State<LiquidLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading animated water droplet',
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: WaterDropletPainter(
          animation: _controller,
          color: widget.color ?? AppColors.oceanBlue,
        ),
      ),
    );
  }
}

class WaterDropletPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WaterDropletPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Create a morphing shape
    final path = Path();
    final time = animation.value * 2 * pi;

    // We'll create a blob-like shape using sine waves
    for (double i = 0; i <= 360; i += 1) {
      final angle = i * pi / 180;
      
      // Add some noise/waviness based on time
      final wave1 = sin(angle * 3 + time) * 0.1; // 3 peaks
      final wave2 = cos(angle * 2 - time * 1.5) * 0.05; // 2 peaks
      
      final r = radius * (0.8 + wave1 + wave2);
      
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Draw shadow/glow
    canvas.drawShadow(path, color.withOpacity(0.3), 4.0, true);
    
    // Draw main shape
    canvas.drawPath(path, paint);

    // Draw highlight (reflection)
    final highlightPath = Path();
    final highlightR = radius * 0.6;
    highlightPath.addOval(Rect.fromCircle(
      center: center - Offset(radius * 0.2, radius * 0.2), 
      radius: radius * 0.15
    ));
    canvas.drawPath(
      highlightPath, 
      Paint()..color = Colors.white.withOpacity(0.4)
    );
  }

  @override
  bool shouldRepaint(WaterDropletPainter oldDelegate) => true;
}
