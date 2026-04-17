// lib\features\patient\widgets\glucose_chart_painter.dart
import 'package:flutter/material.dart';

class ChartPainter extends CustomPainter {
  final Color primaryColor;
  final double? currentGlucose;
  final double? predictedGlucose;
  final List<double>? historyGlucose;

  const ChartPainter({
    required this.primaryColor,
    this.currentGlucose,
    this.predictedGlucose,
    this.historyGlucose,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const lh = 18.0;
    final h = size.height - lh;
    final w = size.width;

    // Add left padding for Y-axis labels
    const chartX = 24.0;
    final chartW = w - chartX;

    double _mapY(double g, double height) {
      if (g <= 0) return height * 0.5;
      final clamped = g.clamp(40.0, 250.0);
      final fraction = (clamped - 40.0) / 210.0;
      // High glucose -> small Y (top)
      return height - (height * fraction * 0.8) - (height * 0.1);
    }

    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    // Draw Y-axis labels and gridlines
    final gridLevels = [50.0, 100.0, 150.0, 200.0, 250.0];
    for (final level in gridLevels) {
      final y = _mapY(level, h);
      canvas.drawLine(Offset(chartX, y), Offset(w, y), grid);

      final tp = TextPainter(
        text: TextSpan(
          text: '${level.toInt()}',
          style: const TextStyle(fontSize: 9, color: Color(0xFFAAAAAA)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    const xl = ['-60m', '-30m', 'Now', '+30m', '+60m'];
    final sLabel = chartW / 4;
    for (int i = 0; i < xl.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: xl[i],
          style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      double dx = chartX + (i * sLabel) - (tp.width / 2);
      // Clamp edge labels so they don't overflow
      if (i == 0) dx = chartX;
      if (i == xl.length - 1) dx = w - tp.width;
      tp.paint(canvas, Offset(dx, h + 4));
    }

    final double startY = (currentGlucose != null && currentGlucose! > 0)
        ? _mapY(currentGlucose!, h)
        : h * 0.37;

    final double endY = (predictedGlucose != null && predictedGlucose! > 0)
        ? _mapY(predictedGlucose!, h)
        : h * 0.04;

    List<Offset> gry;
    if (historyGlucose != null && historyGlucose!.length > 1) {
      gry = [];
      final int count = historyGlucose!.length;
      final double stepX = (chartW / 2) / (count - 1);

      for (int i = 0; i < count; i++) {
        gry.add(Offset(chartX + (i * stepX), _mapY(historyGlucose![i], h)));
      }

      // Ensure perfectly smooth connection to current live reading
      gry.last = Offset(chartX + (chartW / 2), startY);
    } else {
      gry = [
        Offset(chartX, startY + (h * 0.2)),
        Offset(chartX + (chartW / 2) * 0.33, startY + (h * 0.05)),
        Offset(chartX + (chartW / 2) * 0.66, startY + (h * 0.1)),
        Offset(chartX + (chartW / 2), startY),
      ];
    }

    final grn = [
      Offset(chartX + (chartW / 2), startY),
      Offset(
        chartX + (chartW / 2) + (chartW / 2) * 0.25,
        startY + (endY - startY) * 0.3,
      ),
      Offset(
        chartX + (chartW / 2) + (chartW / 2) * 0.5,
        startY + (endY - startY) * 0.6,
      ),
      Offset(
        chartX + (chartW / 2) + (chartW / 2) * 0.75,
        startY + (endY - startY) * 0.85,
      ),
      Offset(w, endY),
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
