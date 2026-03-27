import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucora_ai_companion/features/patient/screens/patient_care_plan_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_prediction_screen.dart';
import 'recommendations_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String userName = supabase.auth.currentUser?.userMetadata?['full_name'] ?? "User";

    final colors = context.colors;

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
                Text(
                  "Welcome Back, $userName!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.textSecondary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Landscape vs Portrait layouts ──
            isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: glucose + IOB/battery
                      Expanded(
                        child: Column(
                          children: [
                            _glucoseCard(context),
                            const SizedBox(height: 12),
                            _statusIndicatorsRow(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right: prediction + recommendations + care plan
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AIPredictionScreen(),
                                ),
                              ),
                              child: _predictionCard(context),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RecommendationsScreen(),
                                ),
                              ),
                              child: _recommendationsCard(context),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PatientCarePlanScreen(),
                                ),
                              ),
                              child: _carePlanCard(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _glucoseCard(context),
                      const SizedBox(height: 12),
                      _statusIndicatorsRow(context),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AIPredictionScreen(),
                          ),
                        ),
                        child: _predictionCard(context),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecommendationsScreen(),
                          ),
                        ),
                        child: _recommendationsCard(context),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PatientCarePlanScreen(),
                          ),
                        ),
                        child: _carePlanCard(context),
                      ),
                    ],
                  ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // IOB + BATTERY ROW
  // ════════════════════════════════════════════════════
  Widget _statusIndicatorsRow(BuildContext context) {
    final colors = context.colors;

    // IOB values
    const double iobValue = 2.4;
    // ignore: unnecessary_string_escapes
    const String iobUnit = "U";

    // Battery values
    const double batteryPercent = 0.80;
    const int batteryDisplay = 80;

    // Battery color: green > 50%, amber 20–50%, red < 20%
    final Color batteryColor = batteryPercent > 0.5
        ? const Color(0xFF4CAF50)
        : batteryPercent > 0.2
            ? const Color(0xFFFFB300)
            : const Color(0xFFEF1616);

    return Row(
      children: [
        // ── IOB card ──────────────────────────────────
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon bubble
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    size: 19,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "IOB",
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$iobValue",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            " $iobUnit",
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Insulin on board",
                        style: TextStyle(
                          fontSize: 9.5,
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ── Battery card ───────────────────────────────
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon bubble — color matches battery level
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: batteryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    batteryPercent > 0.2
                        ? Icons.battery_charging_full_rounded
                        : Icons.battery_alert_rounded,
                    size: 19,
                    color: batteryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sensor Battery",
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$batteryDisplay",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            " %",
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: batteryPercent,
                          minHeight: 5,
                          backgroundColor:
                              colors.textSecondary.withValues(alpha: 0.15),
                          valueColor:
                              AlwaysStoppedAnimation(batteryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  // GLUCOSE CARD
  // ════════════════════════════════════════════════════
  Widget _glucoseCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
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
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Glucose Level:",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "110 mg/dL",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "Last updated: 5 minutes ago",
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textSecondary,
                            ),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: colors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dot(colors.primary, "Normal", colors),
              _dot(const Color(0xFFEFDD16), "Low", colors),
              _dot(colors.error, "High", colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c, String label, GlucoraColors colors) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      );

  // ════════════════════════════════════════════════════
  // AI PREDICTION CARD
  // ════════════════════════════════════════════════════
  Widget _predictionCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "AI Prediction",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                "View details",
                style: TextStyle(
                  fontSize: 13,
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "135",
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  " mg/dL",
                  style: TextStyle(
                      fontSize: 18, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.arrow_upward, color: colors.error, size: 14),
              const SizedBox(width: 2),
              Text(
                "22.73%",
                style: TextStyle(
                  fontSize: 13,
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "Expected glucose in 30 minutes",
                style: TextStyle(
                    fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Glucose from 10:21pm 15 Jan, 2026",
            style:
                TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _ChartPainter(primaryColor: colors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: 14, height: 2.5, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                "Next 60 minutes",
                style: TextStyle(
                    fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(width: 16),
              Container(
                  width: 14, height: 2.5, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "Last Hour",
                style: TextStyle(
                    fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // RECOMMENDATIONS CARD
  // ════════════════════════════════════════════════════
  Widget _recommendationsCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recommendations",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                "View details",
                style: TextStyle(
                  fontSize: 13,
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rec(colors, "Avoid high-carbohydrate meals"),
          const SizedBox(height: 10),
          _rec(colors, "Take a short walk"),
          const SizedBox(height: 10),
          _rec(colors, "Recheck glucose in 30 minutes"),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Recommendations are supportive and not a medical diagnosis.",
                  style: TextStyle(
                      fontSize: 10, color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rec(GlucoraColors colors, String text) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style:
                  TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
          ),
        ],
      );

  // ════════════════════════════════════════════════════
  // CARE PLAN CARD
  // ════════════════════════════════════════════════════
  Widget _carePlanCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'My Care Plan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dr. Sarah Johnson  ·  Target: 70–180 mg/dL',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Next appointment: Apr 5, 2026',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// CHART PAINTER
// ════════════════════════════════════════════════════
class _ChartPainter extends CustomPainter {
  final Color primaryColor;
  const _ChartPainter({required this.primaryColor});

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
          style: const TextStyle(
              fontSize: 10, color: Color(0xFFAAAAAA)),
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
      p.cubicTo(
          (a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}