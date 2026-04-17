import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen> {
  // AI Prediction data
  double? _predictedValue;
  double? _confidenceScore;
  String? _riskLevel;
  DateTime? _predictionTime;
  DateTime? _predictedFor;
  int? _horizonMinutes;
  
  // Current glucose data (for comparison)
  double? _currentGlucose;
  DateTime? _currentGlucoseTime;
  
  // Loading states
  bool _isLoading = true;
  String? _errorMessage;
  
  // Timer for auto-refresh
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Refresh every 30 seconds to show latest predictions
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = "User not logged in";
          _isLoading = false;
        });
        return;
      }

      final patientId = await getPatientProfileId(userId);
      if (patientId == null) {
        setState(() {
          _errorMessage = "Patient profile not found";
          _isLoading = false;
        });
        return;
      }

      // Fetch latest prediction
      final prediction = await getLatestPrediction(patientId);
      
      // Fetch latest glucose reading for comparison
      final glucoseReading = await getLatestGlucoseReading(patientId);

      if (mounted) {
        setState(() {
          if (prediction != null) {
            _predictedValue = (prediction['predicted_value'] as num?)?.toDouble();
            _confidenceScore = (prediction['confidence_score'] as num?)?.toDouble();
            _riskLevel = prediction['risk_level'];
            _predictionTime = DateTime.tryParse(prediction['created_at']);
            _predictedFor = DateTime.tryParse(prediction['predicted_for']);
            _horizonMinutes = prediction['horizon_minutes'];
          }
          
          if (glucoseReading != null) {
            _currentGlucose = double.tryParse(glucoseReading['value_mg_dl'].toString());
            _currentGlucoseTime = DateTime.tryParse(glucoseReading['recorded_at']);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load prediction data";
          _isLoading = false;
        });
      }
      debugPrint('Error fetching AI prediction: $e');
    }
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

  double? _calculateDifference() {
    if (_currentGlucose != null && _predictedValue != null) {
      return _predictedValue! - _currentGlucose!;
    }
    return null;
  }

  double? _calculatePercentageChange() {
    if (_currentGlucose != null && _predictedValue != null && _currentGlucose! > 0) {
      return ((_predictedValue! - _currentGlucose!) / _currentGlucose!) * 100;
    }
    return null;
  }

  String _getTrendDirection() {
    final diff = _calculateDifference();
    if (diff == null) return 'stable';
    if (diff > 5) return 'rising';
    if (diff < -5) return 'falling';
    return 'stable';
  }

  Color _getRiskColor(BuildContext context) {
    final colors = context.colors;
    if (_riskLevel == 'LOW') return const Color(0xFFEFDD16);
    if (_riskLevel == 'HIGH') return colors.error;
    return colors.success;
  }

  String _getRiskMessage() {
    if (_riskLevel == 'LOW') {
      return "Your glucose is predicted to go LOW. Consider taking fast-acting carbohydrates and monitor closely.";
    } else if (_riskLevel == 'HIGH') {
      return "Your glucose is predicted to go HIGH. Consider taking insulin as prescribed and staying hydrated.";
    } else {
      return "Your glucose is predicted to stay in range. Continue with your current management plan.";
    }
  }

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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.textPrimary, size: 20),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _isLoading
              ? _buildLoadingState(context)
              : _errorMessage != null
                  ? _buildErrorState(context)
                  : _buildContent(context),
        ),
      ),
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
            Text(
              "Loading prediction data...",
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.colors;
    final predictedValue = _predictedValue ?? 0;
    final horizonMinutes = _horizonMinutes ?? 30;
    final difference = _calculateDifference();
    final percentageChange = _calculatePercentageChange();
    final trendDirection = _getTrendDirection();
    final isRising = trendDirection == 'rising';
    final riskColor = _getRiskColor(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main prediction card
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
                  Text(
                    "Predicted in $horizonMinutes minutes",
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
                         const SizedBox(width: 4),
                      Text(
                        " mg/dL",
                        style: TextStyle(fontSize: 18, color: colors.textSecondary),
                      ),
                  if (_confidenceScore != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),

                      ),
                      child: Text(
                        "${_confidenceScore!.toInt()}% confidence",
                        style: TextStyle(fontSize: 10, color: colors.primary),
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
                    predictedValue.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
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
              const SizedBox(height: 6),
              if (difference != null && percentageChange != null)
                Row(
                  children: [
                    Icon(
                      isRising ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isRising ? colors.error : colors.success,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${percentageChange.abs().toStringAsFixed(2)}% ${isRising ? 'rise' : 'fall'} expected",
                      style: TextStyle(
                        color: isRising ? colors.error : colors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              if (_predictionTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Prediction generated: ${_formatTime(_predictionTime)}",
                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Confidence score bar (if available)
        if (_confidenceScore != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Confidence Score",
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                "${_confidenceScore!.toInt()}%",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _confidenceScore! / 100,
              minHeight: 8,
              backgroundColor: colors.textSecondary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          const SizedBox(height: 24),
        ],

        Text(
          "Prediction Details",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),

            _detailRow(context, "Current Level", "${currentGlucose.round()} mg/dL", colors.primary),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow(context, "Predicted (30 min)", "${predictedGlucose.round()} mg/dL", trendColor),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow(context, "Trend", isRising ? "Rising" : "Falling", const Color(0xFFEFDD16)),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow(context, "Last Reading", formattedDate, colors.textSecondary),

        _detailRow(context, "Current Level", 
            _currentGlucose != null ? "${_currentGlucose!.toStringAsFixed(0)} mg/dL" : "Unknown", 
            colors.primary),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        
        _detailRow(context, "Predicted ($horizonMinutes min)", 
            "${predictedValue.toStringAsFixed(0)} mg/dL", 
            riskColor),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        
        _detailRow(context, "Change", 
            difference != null 
                ? "${difference > 0 ? '+' : ''}${difference.toStringAsFixed(0)} mg/dL (${percentageChange?.toStringAsFixed(1)}%)"
                : "Unknown",
            isRising ? colors.error : colors.success),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        
        _detailRow(context, "Trend", 
            trendDirection.toUpperCase(),
            const Color(0xFFEFDD16)),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        
        _detailRow(context, "Risk Level", 
            _riskLevel ?? "Unknown",
            riskColor),
        const Divider(height: 24, color: Color(0xFFEEEEEE)),
        
        _detailRow(context, "Last Reading", 
            _currentGlucoseTime != null ? _formatDateTime(_currentGlucoseTime) : "Unknown",
            colors.textSecondary),
        
        if (_predictedFor != null) ...[
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _detailRow(context, "Predicted For", 
              _formatDateTime(_predictedFor),
              colors.textSecondary),
        ],

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
          _getRiskMessage(),
        ),

        // Show when no prediction exists
        if (_predictedValue == null && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _infoCard(
              context,
              Icons.info_outline_rounded,
              "Your glucose is predicted to ${isRising ? 'rise' : 'fall'} by ${diff.round()} mg/dL in the next 30 minutes. "
              "${isRising ? 'Consider reducing carbohydrate intake and staying active.' : 'Consider having a small snack and monitoring your levels.'}",
            ),
          ),

        const SizedBox(height: 30),
      ],
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