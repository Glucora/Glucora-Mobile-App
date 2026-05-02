import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/providers/glucose_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({super.key});

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _init());
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final provider = context.read<GlucoseProvider>();
    if (provider.patientProfileId == null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) await provider.init(user.id);
    } else {
      await Future.wait([
        provider.loadLatestReading(),
        provider.loadLatestPrediction(),
      ]);
    }
  }

  Future<void> _refresh() async {
    final provider = context.read<GlucoseProvider>();
    await Future.wait([
      provider.loadLatestReading(),
      provider.loadLatestPrediction(),
    ]);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  String _formatDateTime(DateTime? time) {
    if (time == null) return 'Unknown';
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute$ampm · ${time.month}/${time.day}/${time.year}';
  }

  double? _calculateDifference(double? current, double? predicted) {
    if (current != null && predicted != null) return predicted - current;
    return null;
  }

  double? _calculatePercentageChange(double? current, double? predicted) {
    if (current != null && predicted != null && current > 0) {
      return ((predicted - current) / current) * 100;
    }
    return null;
  }

  String _getTrendDirection(double? diff) {
    if (diff == null) return 'stable';
    if (diff > 5) return 'rising';
    if (diff < -5) return 'falling';
    return 'stable';
  }

  Color _getRiskColor(BuildContext context, String? riskLevel) {
    final colors = context.colors;
    if (riskLevel == 'LOW') return const Color(0xFFEFDD16);
    if (riskLevel == 'HIGH') return colors.error;
    return colors.success;
  }

  String _getRiskMessage(String? riskLevel) {
    if (riskLevel == 'LOW') {
      return "Your glucose is predicted to go LOW. Consider taking fast-acting carbohydrates and monitor closely.";
    } else if (riskLevel == 'HIGH') {
      return "Your glucose is predicted to go HIGH. Consider taking insulin as prescribed and staying hydrated.";
    }
    return "Your glucose is predicted to stay in range. Continue with your current management plan.";
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Consumer<GlucoseProvider>(
      builder: (context, provider, _) {
        final prediction = provider.latestPrediction;
        final reading = provider.latestReading;

        final predictedValue =
            (prediction?['predicted_value'] as num?)?.toDouble();
        final confidenceScore =
            (prediction?['confidence_score'] as num?)?.toDouble();
        final riskLevel = prediction?['risk_level'] as String?;
        final predictionTime = prediction?['created_at'] != null
            ? DateTime.tryParse(prediction!['created_at'])
            : null;
        final predictedFor = prediction?['predicted_for'] != null
            ? DateTime.tryParse(prediction!['predicted_for'])
            : null;
        final horizonMinutes =
            prediction?['horizon_minutes'] as int? ?? 30;

        final currentGlucose =
            reading != null ? double.tryParse(reading['value_mg_dl'].toString()) : null;
        final currentGlucoseTime = reading?['recorded_at'] != null
            ? DateTime.tryParse(reading!['recorded_at'])
            : null;

        final difference = _calculateDifference(currentGlucose, predictedValue);
        final percentageChange =
            _calculatePercentageChange(currentGlucose, predictedValue);
        final trendDirection = _getTrendDirection(difference);
        final isRising = trendDirection == 'rising';
        final riskColor = _getRiskColor(context, riskLevel);

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
                  fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: colors.textPrimary, size: 20),
                onPressed: _refresh,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: provider.isLoading
                  ? _buildLoadingState(context)
                  : provider.errorMessage != null
                      ? _buildErrorState(context, provider)
                      : _buildContent(
                          context,
                          predictedValue: predictedValue,
                          confidenceScore: confidenceScore,
                          riskLevel: riskLevel,
                          predictionTime: predictionTime,
                          predictedFor: predictedFor,
                          horizonMinutes: horizonMinutes,
                          currentGlucose: currentGlucose,
                          currentGlucoseTime: currentGlucoseTime,
                          difference: difference,
                          percentageChange: percentageChange,
                          trendDirection: trendDirection,
                          isRising: isRising,
                          riskColor: riskColor,
                        ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text("Loading prediction data...",
                style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, GlucoseProvider provider) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(provider.errorMessage!,
                style: TextStyle(color: colors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                _refresh();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required double? predictedValue,
    required double? confidenceScore,
    required String? riskLevel,
    required DateTime? predictionTime,
    required DateTime? predictedFor,
    required int horizonMinutes,
    required double? currentGlucose,
    required DateTime? currentGlucoseTime,
    required double? difference,
    required double? percentageChange,
    required String trendDirection,
    required bool isRising,
    required Color riskColor,
  }) {
    final colors = context.colors;
    final displayValue = predictedValue ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: riskColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: riskColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Predicted in $horizonMinutes minutes",
                      style: TextStyle(
                          fontSize: 13, color: colors.textSecondary)),
                  if (confidenceScore != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${confidenceScore.toInt()}% confidence",
                        style:
                            TextStyle(fontSize: 10, color: colors.primary),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayValue.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary),
                  ),
                  Text(" mg/dL",
                      style: TextStyle(
                          fontSize: 18, color: colors.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              if (difference != null && percentageChange != null)
                Row(
                  children: [
                    Icon(
                      isRising
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color:
                          isRising ? colors.error : colors.success,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${percentageChange.abs().toStringAsFixed(2)}% ${isRising ? 'rise' : 'fall'} expected",
                      style: TextStyle(
                          color: isRising ? colors.error : colors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              if (predictionTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Prediction generated: ${_formatTime(predictionTime)}",
                    style: TextStyle(
                        fontSize: 10, color: colors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (confidenceScore != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Confidence Score",
                  style: TextStyle(
                      fontSize: 14, color: colors.textSecondary)),
              Text("${confidenceScore.toInt()}%",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidenceScore / 100,
              minHeight: 8,
              backgroundColor:
                  colors.textSecondary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text("Prediction Details",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary)),
        const SizedBox(height: 14),
        _detailRow(context, "Current Level",
            currentGlucose != null
                ? "${currentGlucose.toStringAsFixed(0)} mg/dL"
                : "Unknown",
            colors.primary),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        _detailRow(context, "Predicted ($horizonMinutes min)",
            "${displayValue.toStringAsFixed(0)} mg/dL", riskColor),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        _detailRow(
            context,
            "Change",
            difference != null
                ? "${difference > 0 ? '+' : ''}${difference.toStringAsFixed(0)} mg/dL (${percentageChange?.toStringAsFixed(1)}%)"
                : "Unknown",
            isRising ? colors.error : colors.success),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        _detailRow(context, "Trend", trendDirection.toUpperCase(),
            const Color(0xFFEFDD16)),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        _detailRow(context, "Risk Level", riskLevel ?? "Unknown", riskColor),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        _detailRow(
            context,
            "Last Reading",
            currentGlucoseTime != null
                ? _formatDateTime(currentGlucoseTime)
                : "Unknown",
            colors.textSecondary),
        if (predictedFor != null) ...[
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _detailRow(context, "Predicted For",
              _formatDateTime(predictedFor), colors.textSecondary),
        ],
        const SizedBox(height: 28),
        Text("What this means",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary)),
        const SizedBox(height: 10),
        _infoCard(context, Icons.info_outline_rounded,
            _getRiskMessage(riskLevel)),
        if (predictedValue == null && !context.read<GlucoseProvider>().isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _infoCard(
              context,
              Icons.timeline_outlined,
              "No AI predictions available yet. Connect your hardware device to receive real-time predictions.",
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _detailRow(
      BuildContext context, String label, String value, Color valueColor) {
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
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}