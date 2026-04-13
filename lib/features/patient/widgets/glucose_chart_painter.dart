// lib\features\patient\widgets\glucose_chart_painter.dart
import 'package:flutter/material.dart';

class ChartPainter extends CustomPainter {
  final Color primaryColor;
  const ChartPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    const lh = 18.0;
    final h = size.height - lh;
    final w = size.width;
    final s = w / 5;

    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      canvas.drawLine(Offset(0, h * i / 3), Offset(w, h * i / 3), grid);
    }

    const xl = ['10', '20', '30', '40', '50', '60'];
    for (int i = 0; i < xl.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: xl[i],
          style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * s - tp.width / 2, h + 4));
    }

    final gry = [
      Offset(0, h * 0.58),
      Offset(s * 0.65, h * 0.42),
      Offset(s * 1.25, h * 0.53),
      Offset(s * 2.0, h * 0.37),
    ];
    final grn = [
      Offset(s * 2.0, h * 0.37),
      Offset(s * 2.7, h * 0.47),
      Offset(s * 3.5, h * 0.30),
      Offset(s * 4.2, h * 0.18),
      Offset(s * 5.0, h * 0.04),
    ];

    final fill = _sp(grn)
      ..lineTo(grn.last.dx, h)
      ..lineTo(grn.first.dx, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      _sp(gry),
      Paint()
        ..color = const Color(0xFFCCCCCC)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      _sp(grn),
      Paint()
        ..color = primaryColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (final pt in [gry.last, grn.last]) {
      canvas.drawCircle(pt, 5, Paint()..color = primaryColor);
      canvas.drawCircle(pt, 3, Paint()..color = Colors.white);
    }
  }

  Path _sp(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      p.cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
