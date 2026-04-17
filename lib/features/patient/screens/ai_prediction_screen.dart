import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

import 'package:intl/intl.dart';

class AIPredictionScreen extends StatelessWidget {
  final double currentGlucose;
  final double predictedGlucose;
  final double percentageChange;
  final DateTime? lastReadingTime;

  const AIPredictionScreen({
    super.key,
    required this.currentGlucose,
    required this.predictedGlucose,
    required this.percentageChange,
    this.lastReadingTime,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRising = percentageChange >= 0;
    final trendColor = isRising ? colors.error : colors.primary;
    final trendIcon = isRising ? Icons.arrow_upward : Icons.arrow_downward;
    final diff = (predictedGlucose - currentGlucose).abs();
    
    final formattedDate = lastReadingTime != null
        ? DateFormat('h:mma · d MMM, yyyy').format(lastReadingTime!)
        : '--';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
        ),
        title: Text(
          "AI Prediction",
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.primary, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Predicted in 30 minutes",
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${predictedGlucose.round()}",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        " mg/dL",
                        style: TextStyle(fontSize: 18, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(trendIcon,
                          color: trendColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${percentageChange.abs().toStringAsFixed(2)}% ${isRising ? 'rise' : 'fall'} expected",
                        style: TextStyle(
                            color: trendColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Prediction Details",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),

            const SizedBox(height: 14),

            _detailRow(context, "Current Level", "${currentGlucose.round()} mg/dL", colors.primary),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow(context, "Predicted (30 min)", "${predictedGlucose.round()} mg/dL", trendColor),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow(context, "Trend", isRising ? "Rising" : "Falling", const Color(0xFFEFDD16)),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow(context, "Last Reading", formattedDate, colors.textSecondary),

            const SizedBox(height: 28),

            Text(
              "What this means",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),

            const SizedBox(height: 10),

            _infoCard(
              context,
              Icons.info_outline_rounded,
              "Your glucose is predicted to ${isRising ? 'rise' : 'fall'} by ${diff.round()} mg/dL in the next 30 minutes. "
              "${isRising ? 'Consider reducing carbohydrate intake and staying active.' : 'Consider having a small snack and monitoring your levels.'}",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, Color valueColor) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: colors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ],
    );
  }

  Widget _infoCard(BuildContext context, IconData icon, String text) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}