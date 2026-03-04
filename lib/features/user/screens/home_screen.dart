import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_prediction_screen.dart';
import 'recommendations_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Allow all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final hPadding = isLandscape ? screenWidth * 0.08 : 20.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Welcome Back, Malak!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFE0E0E0), width: 1.5),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      size: 20, color: Color(0xFF555555)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── In landscape: side-by-side layout ──
            isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _glucoseCard()),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AIPredictionScreen()),
                              ),
                              child: _predictionCard(),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const RecommendationsScreen()),
                              ),
                              child: _recommendationsCard(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _glucoseCard(),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AIPredictionScreen()),
                        ),
                        child: _predictionCard(),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const RecommendationsScreen()),
                        ),
                        child: _recommendationsCard(),
                      ),
                    ],
                  ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Glucose card ──────────────────────────────────
  Widget _glucoseCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                    color: Color(0xFF199A8E), shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current Glucose Level:",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text("110 mg/dL",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "Last updated: 5 minutes ago",
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[400]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
                height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          ),

          // ── Centered, evenly spaced status dots ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dot(const Color(0xFF199A8E), "Normal"),
              _dot(const Color(0xFFEFDD16), "Low"),
              _dot(const Color(0xFFEF1616), "High"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF555555))),
        ],
      );

  // ── AI Prediction card ────────────────────────────
  Widget _predictionCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("AI Prediction",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text("View details",
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF199A8E),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text("135",
                  style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(" mg/dL",
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey[600])),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.arrow_upward,
                  color: Color(0xFFEF1616), size: 14),
              const SizedBox(width: 2),
              const Text("22.73%",
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEF1616),
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text("Expected glucose in 30 minutes",
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 4),
          Text("Glucose from 10:21pm 15 Jan, 2026",
              style:
                  TextStyle(fontSize: 11, color: Colors.grey[400])),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: CustomPaint(
                size: const Size(double.infinity, 130),
                painter: _ChartPainter()),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Container(
                width: 14,
                height: 2.5,
                color: const Color(0xFF199A8E)),
            const SizedBox(width: 6),
            Text("Next 60 minutes",
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[700])),
            const SizedBox(width: 16),
            Container(
                width: 14,
                height: 2.5,
                color: const Color(0xFFCCCCCC)),
            const SizedBox(width: 6),
            Text("Last Hour",
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[500])),
          ]),
        ],
      ),
    );
  }

  // ── Recommendations card ──────────────────────────
  Widget _recommendationsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Recommendations",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text("View details",
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF199A8E),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          _rec("Avoid high-carbohydrate meals"),
          const SizedBox(height: 10),
          _rec("Take a short walk"),
          const SizedBox(height: 10),
          _rec("Recheck glucose in 30 minutes"),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Icons.warning_amber_rounded,
                    size: 12, color: Colors.grey[400]),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Recommendations are supportive and not a medical diagnosis.",
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rec(String text) => Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFF199A8E), shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF333333))),
        ),
      ]);
}

// ── Chart painter ─────────────────────────────────────
class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const lh = 18.0;
    final h = size.height - lh;
    final w = size.width;
    final s = w / 5;

    final grid = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      canvas.drawLine(Offset(0, h * i / 3), Offset(w, h * i / 3), grid);
    }

    const xl = ['10', '20', '30', '40', '50', '60'];
    for (int i = 0; i < xl.length; i++) {
      final tp = TextPainter(
          text: TextSpan(
              text: xl[i],
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFFAAAAAA))),
          textDirection: TextDirection.ltr)
        ..layout();
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
          ..color = const Color(0xFF199A8E).withOpacity(0.10)
          ..style = PaintingStyle.fill);

    canvas.drawPath(
        _sp(gry),
        Paint()
          ..color = const Color(0xFFCCCCCC)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    canvas.drawPath(
        _sp(grn),
        Paint()
          ..color = const Color(0xFF199A8E)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    for (final pt in [gry.last, grn.last]) {
      canvas.drawCircle(
          pt, 5, Paint()..color = const Color(0xFF199A8E));
      canvas.drawCircle(pt, 3, Paint()..color = Colors.white);
    }
  }

  Path _sp(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      p.cubicTo(
          (a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}