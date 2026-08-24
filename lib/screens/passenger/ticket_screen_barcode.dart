import 'package:flutter/material.dart';

class BarcodePainter extends CustomPainter {
  BarcodePainter({required this.code});

  final String code;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);

    if (code.isEmpty) return;

    const bars = 64;
    final barWidth = size.width / bars;
    var seed = 0;
    for (var i = 0; i < code.length; i++) {
      seed = (seed * 31 + code.codeUnitAt(i)) & 0x7fffffff;
    }

    var x = 0.0;
    final rand = seed;
    var state = rand == 0 ? 12345 : rand;
    for (var i = 0; i < bars; i++) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      final tall = (state >> 8) % 3 == 0;
      final height = tall ? size.height : size.height * 0.68;
      final offset = (size.height - height) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, offset, barWidth * 0.62, height),
          const Radius.circular(1),
        ),
        paint,
      );
      x += barWidth;
    }
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) =>
      oldDelegate.code != code;
}

class DashedDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const dashWidth = 7.0;
    const dashSpace = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedDividerPainter oldDelegate) => false;
}
