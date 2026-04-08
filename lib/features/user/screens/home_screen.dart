import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucora_ai_companion/features/patient/screens/patient_care_plan_screen.dart';
import 'package:glucora_ai_companion/features/user/screens/iob_card.dart';
import 'package:glucora_ai_companion/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_prediction_screen.dart';
import 'recommendations_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Care plan
  String _doctorName = '';
  String _targetRange = '– mg/dL';
  String _nextAppointment = '–';

  // Glucose
  double? _glucoseValue;
  String _glucoseTrend = 'stable';
  DateTime? _glucoseUpdatedAt;
  bool _glucoseLoading = true;

  // IOB
  double? _iobValue;
  bool _iobLoading = true;

  // Battery
  String? _batteryHealth;
  bool _batteryLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCarePlanSummary();
    _fetchLatestGlucose();
    _fetchLatestIOB();
    _fetchDeviceBattery();
  }

  // ════════════════════════════════════════════════════
  // HELPER: GET PATIENT PROFILE ID
  // ════════════════════════════════════════════════════
  Future<int?> getPatientProfileId(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('patient_profile')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null && response['id'] != null) {
        return response['id'] as int;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting patient profile ID: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════
  // FETCH: CARE PLAN
  // ════════════════════════════════════════════════════
  Future<void> _fetchCarePlanSummary() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final patientProfileId = await getPatientProfileId(userId);
      if (patientProfileId == null) return;

      final response = await supabase
          .from('care_plans')
          .select(
            'target_glucose_min, target_glucose_max, next_appointment, '
            'doctor_profile!care_plans_doctor_id_fkey(user_id, users(full_name))',
          )
          .eq('patient_id', patientProfileId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return;

      final doctorProfile = response['doctor_profile'];
      final doctorUser = doctorProfile?['users'];
      final doctorName = doctorUser?['full_name'] ?? 'Your Doctor';
      final min = response['target_glucose_min'];
      final max = response['target_glucose_max'];
      final appt = response['next_appointment'];

      setState(() {
        _doctorName = doctorName;
        _targetRange = (min != null && max != null) ? '$min–$max mg/dL' : '– mg/dL';
        _nextAppointment = appt ?? '–';
      });
    } catch (e) {
      if (kDebugMode) print('Failed to fetch care plan summary: $e');
    }
  }

  // ════════════════════════════════════════════════════
  // FETCH: LATEST GLUCOSE
  // ════════════════════════════════════════════════════
  Future<void> _fetchLatestGlucose() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _glucoseLoading = false);
        return;
      }

      final patientId = await getPatientProfileId(userId);
      if (patientId == null) {
        setState(() => _glucoseLoading = false);
        return;
      }

      final response = await supabase
          .from('glucose_readings')
          .select('value_mg_dl, trend, recorded_at')
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        if (response != null) {
          _glucoseValue = double.tryParse(response['value_mg_dl'].toString());
          _glucoseTrend = response['trend'] ?? 'stable';
          _glucoseUpdatedAt = DateTime.tryParse(response['recorded_at']);
        }
        _glucoseLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print('Failed to fetch glucose: $e');
      setState(() => _glucoseLoading = false);
    }
  }

  // ════════════════════════════════════════════════════
  // FETCH: LATEST IOB
  // ════════════════════════════════════════════════════
  Future<void> _fetchLatestIOB() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final patientId = await getPatientProfileId(userId);
      if (patientId == null) return;

      final response = await supabase
          .from('insulin_on_board')
          .select('total_iob_units')
          .eq('patient_id', patientId)
          .order('calculated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _iobValue = response != null
            ? double.tryParse(response['total_iob_units'].toString())
            : null;
        _iobLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print('Failed to fetch IOB: $e');
      setState(() => _iobLoading = false);
    }
  }

  // ════════════════════════════════════════════════════
  // FETCH: DEVICE BATTERY - FIXED VERSION
  // ════════════════════════════════════════════════════
  Future<void> _fetchDeviceBattery() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        setState(() => _batteryLoading = false);
        return;
      }

      // Try multiple approaches to get battery health
      String? batteryValue;
      
      // Approach 1: Get active device first
      final activeDevice = await supabase
          .from('devices')
          .select('battery_health, last_sync_at')
          .eq('patient_id', userId)
          .eq('is_active', true)
          .order('last_sync_at', ascending: false)
          .maybeSingle();
      
      if (activeDevice != null && activeDevice['battery_health'] != null) {
        batteryValue = activeDevice['battery_health'].toString();
      } else {
        // Approach 2: Get any device (most recent)
        final device = await supabase
            .from('devices')
            .select('battery_health, last_sync_at')
            .eq('patient_id', userId)
            .order('last_sync_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (device != null && device['battery_health'] != null) {
          batteryValue = device['battery_health'].toString();
        }
      }
      
      // If still no battery, try to see if there are any devices at all
      if (batteryValue == null) {
        final devices = await supabase
            .from('devices')
            .select('id')
            .eq('patient_id', userId);
        
        if (kDebugMode) {
          print('Device count for user $userId: ${devices.length}');
        }
      }
      
      setState(() {
        _batteryHealth = batteryValue;
        _batteryLoading = false;
      });
      
      if (kDebugMode) {
        print('Battery fetched successfully: $_batteryHealth');
      }
      
      // If no battery found after first attempt, try again in 2 seconds
      // (in case device data is still syncing)
      if (batteryValue == null && mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _retryFetchBattery();
          }
        });
      }
      
    } catch (e) {
      if (kDebugMode) print('Failed to fetch battery: $e');
      setState(() => _batteryLoading = false);
    }
  }

  // Retry function for battery fetch
  Future<void> _retryFetchBattery() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) return;
      
      final response = await supabase
          .from('devices')
          .select('battery_health')
          .eq('patient_id', userId)
          .not('battery_health', 'is', null)
          .order('last_sync_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response != null && response['battery_health'] != null && mounted) {
        setState(() {
          _batteryHealth = response['battery_health'].toString();
        });
        
        if (kDebugMode) {
          print('Battery fetched on retry: $_batteryHealth');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Retry battery fetch failed: $e');
    }
  }

  // ════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════
  String _timeAgo(DateTime? dt) {
    if (dt == null) return '–';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _glucoseColor(GlucoraColors colors) {
    if (_glucoseValue == null) return colors.primary;
    if (_glucoseValue! < 70) return const Color(0xFFEFDD16);
    if (_glucoseValue! > 180) return colors.error;
    return colors.primary;
  }

  /// Parses battery_health string into a 0.0–1.0 fraction.
  /// Handles formats like "95%", "95", or falls back to null.
  double? _parseBatteryPercent(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    return (parsed.clamp(0, 100)) / 100.0;
  }

  // ════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String userName =
        supabase.auth.currentUser?.userMetadata?['full_name'] ?? "User";

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

            isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const AIPredictionScreen())),
                              child: _predictionCard(context),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RecommendationsScreen())),
                              child: _recommendationsCard(context),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const PatientCarePlanScreen())),
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
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AIPredictionScreen())),
                        child: _predictionCard(context),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RecommendationsScreen())),
                        child: _recommendationsCard(context),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PatientCarePlanScreen())),
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
  // GLUCOSE CARD — live data
  // ════════════════════════════════════════════════════
  Widget _glucoseCard(BuildContext context) {
    final colors = context.colors;
    final dotColor = _glucoseColor(colors);

    IconData trendIcon;
    switch (_glucoseTrend.toLowerCase()) {
      case 'up':
      case 'rising':
        trendIcon = Icons.arrow_upward_rounded;
        break;
      case 'down':
      case 'falling':
        trendIcon = Icons.arrow_downward_rounded;
        break;
      default:
        trendIcon = Icons.remove_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
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
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
                child: _glucoseLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(trendIcon, color: Colors.white, size: 22),
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
                          _glucoseLoading
                              ? '– mg/dL'
                              : '${_glucoseValue?.toStringAsFixed(0) ?? '–'} mg/dL',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: dotColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Last updated: ${_timeAgo(_glucoseUpdatedAt)}',
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
          Text(label,
              style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        ],
      );

  // ════════════════════════════════════════════════════
  // IOB + BATTERY ROW — both live
  // ════════════════════════════════════════════════════
  Widget _statusIndicatorsRow(BuildContext context) {
    final colors = context.colors;

    final String iobDisplay =
        _iobLoading ? '–' : (_iobValue?.toStringAsFixed(1) ?? '–');

    // Battery - parse the percentage
    final double? batteryPercent = _parseBatteryPercent(_batteryHealth);
    
    // Display: use numeric value if parseable, otherwise show the raw string
    final String batteryDisplay = batteryPercent != null
        ? '${(batteryPercent * 100).toInt()}'
        : (_batteryLoading ? '–' : (_batteryHealth ?? '–'));

    final Color batteryColor = batteryPercent == null
        ? const Color(0xFF4CAF50) // default to green when unknown
        : batteryPercent > 0.5
            ? const Color(0xFF4CAF50)
            : batteryPercent > 0.2
                ? const Color(0xFFFFB300)
                : const Color(0xFFEF1616);

    return Row(
      children: [
        // ── IOB card ──
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _iobLoading
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.primary),
                        )
                      : Icon(Icons.water_drop_rounded,
                          size: 19, color: colors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const IobDetailSheet(),
                    ),
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
                              iobDisplay,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              " U",
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
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ── Battery card ──
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: batteryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _batteryLoading
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: batteryColor),
                        )
                      : Icon(
                          batteryPercent != null && batteryPercent <= 0.2
                              ? Icons.battery_alert_rounded
                              : Icons.battery_charging_full_rounded,
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
                            batteryDisplay,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (batteryPercent != null) ...[
                            Text(
                              " %",
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Show progress bar only when we have a numeric value
                      if (batteryPercent != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: batteryPercent,
                            minHeight: 5,
                            backgroundColor:
                                colors.textSecondary.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(batteryColor),
                          ),
                        )
                      else if (!_batteryLoading && _batteryHealth == null)
                        Text(
                          'No device paired',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: colors.textSecondary,
                          ),
                        )
                      else if (_batteryLoading)
                        const SizedBox.shrink()
                      else
                        Text(
                          _batteryHealth ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: colors.textSecondary,
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
  // AI PREDICTION CARD
  // ════════════════════════════════════════════════════
  Widget _predictionCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
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
              Text("AI Prediction",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              Text("View details",
                  style: TextStyle(
                      fontSize: 13,
                      color: colors.primary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("135",
                  style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(" mg/dL",
                    style: TextStyle(
                        fontSize: 18, color: colors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.arrow_upward, color: colors.error, size: 14),
              const SizedBox(width: 2),
              Text("22.73%",
                  style: TextStyle(
                      fontSize: 13,
                      color: colors.error,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text("Expected glucose in 30 minutes",
                  style:
                      TextStyle(fontSize: 12, color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text("Glucose from 10:21pm 15 Jan, 2026",
              style: TextStyle(fontSize: 11, color: colors.textSecondary)),
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
              Container(width: 14, height: 2.5, color: colors.primary),
              const SizedBox(width: 6),
              Text("Next 60 minutes",
                  style:
                      TextStyle(fontSize: 11, color: colors.textSecondary)),
              const SizedBox(width: 16),
              Container(width: 14, height: 2.5, color: Colors.grey),
              const SizedBox(width: 6),
              Text("Last Hour",
                  style:
                      TextStyle(fontSize: 11, color: colors.textSecondary)),
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
    final supabase = Supabase.instance.client;

    return FutureBuilder<List<String>>(
      future: _fetchRecommendations(supabase),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final recs = snapshot.data ?? [];

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
                  Text("Recommendations",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RecommendationsScreen())),
                    child: Text("View details",
                        style: TextStyle(
                            fontSize: 13,
                            color: colors.primary,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...recs.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _rec(colors, rec),
                  )),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 12, color: colors.textSecondary),
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
      },
    );
  }

  Future<List<String>> _fetchRecommendations(SupabaseClient supabase) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return ["User not logged in"];

      final patientProfileId = await getPatientProfileId(userId);
      if (patientProfileId == null) return ["No patient profile found"];

      final response = await supabase
          .from('ai_recommendations')
          .select('message')
          .eq('patient_id', patientProfileId)
          .order('created_at', ascending: false)
          .limit(3);

      if (response.isEmpty) return ["No recommendations available"];

      final List<String> recs = [];
      for (final item in response) {
        if (item.containsKey('message')) {
          recs.add(item['message']?.toString() ?? '');
        }
      }

      return recs.isEmpty ? ["No recommendations available"] : recs;
    } catch (e) {
      if (kDebugMode) print('Failed to fetch recommendations: $e');
      return ["Failed to fetch recommendations"];
    }
  }

  Widget _rec(GlucoraColors colors, String recText) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: colors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              recText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
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
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
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
                        Icon(Icons.assignment_outlined,
                            size: 18, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('My Care Plan',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary)),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: colors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('$_doctorName  ·  Target: $_targetRange',
                        style: TextStyle(
                            fontSize: 12, color: colors.textSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Next appointment: $_nextAppointment',
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary)),
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
      p.cubicTo(
          (a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}