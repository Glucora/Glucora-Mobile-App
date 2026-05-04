import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/features/patient/screens/patient_care_plan_screen.dart';
import 'package:glucora_ai_companion/features/patient/widgets/iob_detail_sheet.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_data.dart';
import 'package:glucora_ai_companion/services/ble/ble_hardware_service.dart';
import 'package:glucora_ai_companion/providers/glucose_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_prediction_screen.dart';
import 'recommendations_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

Timer? _timeTicker;

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
  double? _backendGlucoseValue;
  String _glucoseTrend = 'stable';
  String _backendGlucoseTrend = 'stable';
  DateTime? _glucoseUpdatedAt;
  DateTime? _backendGlucoseUpdatedAt;
  bool _glucoseLoading = true;

  // IOB
  double? _iobValue;
  double? _backendIobValue;
  bool _iobLoading = true;

  // Battery
  String? _batteryHealth;
  bool _batteryLoading = true;

  // BLE hardware
  final BleHardwareService _bleHardwareService = BleHardwareService.instance;
  StreamSubscription<BleHardwareData>? _bleDataSub;
  String? _hardwareDeviceName;
  int? _hardwareBatteryPercent;
  double? _hardwarePredictionValue;
  double? _hardwareLatestGlucoseValue;
  bool _hardwareConnected = false;
  bool _hardwareLoading = true;
  String _hardwareStatus = 'Searching for hardware...';
  bool _hadHardwareConnection = false;
  bool _disconnectSnackbarShown = false;
  bool _hideSensorValuesUntilReconnect = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initProvider());
    _startBleHardwareFeed();
    _timeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bleDataSub?.cancel();
    _bleHardwareService.stop();
    _timeTicker?.cancel();
    super.dispose();
  }

  Future<void> _initProvider() async {
    final provider = context.read<GlucoseProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (provider.patientProfileId == null) {
      await provider.init(user.id);
    }

    _syncFromProvider(provider);
  }

  void _syncFromProvider(GlucoseProvider provider) {
    final reading = provider.latestReading;
    final iob = provider.latestIob;
    final carePlan = provider.carePlanRaw;

    if (reading != null) {
      final value =
          double.tryParse(reading['value_mg_dl'].toString());
      final trend = reading['trend'] ?? 'stable';
      final updatedAt = reading['recorded_at'] != null
          ? DateTime.tryParse(reading['recorded_at'])
          : null;

      _backendGlucoseValue = value;
      _backendGlucoseTrend = trend;
      _backendGlucoseUpdatedAt = updatedAt;

      if (!_hardwareConnected && !_hideSensorValuesUntilReconnect) {
        setState(() {
          _glucoseValue = value;
          _glucoseTrend = trend;
          _glucoseUpdatedAt = updatedAt;
          _glucoseLoading = false;
        });
      }
    } else {
      setState(() => _glucoseLoading = false);
    }

    if (iob != null) {
      final iobVal =
          double.tryParse(iob['total_iob_units'].toString());
      _backendIobValue = iobVal;
      if (!_hardwareConnected) {
        setState(() {
          _iobValue = iobVal;
          _iobLoading = false;
        });
      }
    } else {
      setState(() => _iobLoading = false);
    }

    if (carePlan != null) {
      final doctorProfile = carePlan['doctor_profile'];
      final min = carePlan['target_glucose_min'];
      final max = carePlan['target_glucose_max'];
      final next = carePlan['next_appointment'];
      setState(() {
        _doctorName = doctorProfile?['users']?['full_name'] ??
            provider.carePlanDoctorName;
        _targetRange = (min != null && max != null)
            ? '$min–$max mg/dL'
            : '– mg/dL';
        _nextAppointment = next ?? '–';
      });
    }

    // Battery from device repository
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      provider.loadDeviceBattery(userId).then((battery) {
        if (mounted && battery != null) {
          setState(() {
            _batteryHealth = battery;
            _batteryLoading = false;
          });
        } else {
          setState(() => _batteryLoading = false);
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    final provider = context.read<GlucoseProvider>();
    await Future.wait([
      provider.loadLatestReading(),
      provider.loadLatestPrediction(),
      provider.loadLatestIob(),
      provider.loadCarePlan(),
      provider.loadRecommendations(limit: 3),
    ]);
    _syncFromProvider(provider);
  }

  Future<void> _startBleHardwareFeed() async {
    _bleDataSub?.cancel();

    _bleDataSub =
        _bleHardwareService.dataStream.listen((data) {
      if (!mounted) return;

      final didJustLoseConnection =
          _hardwareConnected && !data.isConnected;
      final shouldShowDisconnectSnackbar =
          didJustLoseConnection && !_disconnectSnackbarShown;

      setState(() {
        _hardwareLoading = data.isLoading;
        _hardwareConnected = data.isConnected;
        _hardwareDeviceName = data.deviceName;
        _hardwareBatteryPercent = data.batteryPercent;
        _hardwarePredictionValue = data.predictionValue;
        _hardwareLatestGlucoseValue = data.latestGlucoseValue;
        _hardwareStatus = data.status;

        if (data.latestGlucoseValue != null) {
          _glucoseValue = data.latestGlucoseValue;
          _glucoseUpdatedAt = DateTime.now();
          _glucoseLoading = false;
        }

        if (data.iobValue != null) {
          _iobValue = data.iobValue;
          _iobLoading = false;
        }

        if (data.isConnected) {
          _hadHardwareConnection = true;
          _disconnectSnackbarShown = false;
        }

        _hideSensorValuesUntilReconnect =
            _hadHardwareConnection && !data.isConnected;

        if (!data.isConnected &&
            _hideSensorValuesUntilReconnect) {
          _hardwareBatteryPercent = null;
          _hardwarePredictionValue = null;
          _hardwareLatestGlucoseValue = null;
          _glucoseValue = null;
          _glucoseTrend = 'stable';
          _glucoseUpdatedAt = null;
          _iobValue = null;
          _batteryHealth = null;
          _glucoseLoading = false;
          _iobLoading = false;
          _batteryLoading = false;
        } else if (!data.isConnected) {
          _hardwareBatteryPercent = null;
          _hardwarePredictionValue = null;
          _hardwareLatestGlucoseValue = null;
          _glucoseValue = _backendGlucoseValue;
          _glucoseTrend = _backendGlucoseTrend;
          _glucoseUpdatedAt = _backendGlucoseUpdatedAt;
          _iobValue = _backendIobValue;
        }
      });

      if (shouldShowDisconnectSnackbar) {
        _disconnectSnackbarShown = true;
        _showHardwareDisconnectedSnackBar();
      }

      if (data.isConnected) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });

    await _bleHardwareService.start();
  }

  void _showHardwareDisconnectedSnackBar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const TranslatedText(
          'Hardware connection was lost. Open Bluetooth Pairing to reconnect.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 12),
        action: SnackBarAction(
          label: 'Pair now',
          onPressed: () =>
              Navigator.of(context).pushNamed('/bluetooth-pairing'),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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

  double? _parseBatteryPercent(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    return (parsed.clamp(0, 100)) / 100.0;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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

    return Consumer<GlucoseProvider>(
      builder: (context, provider, _) {
        final prediction = provider.latestPrediction;
        final aiPredictedGlucose =
            (prediction?['predicted_value'] as num?)?.toDouble();
        final aiConfidenceScore =
            (prediction?['confidence_score'] as num?)?.toDouble();
        final aiRiskLevel = prediction?['risk_level'] as String?;
        final aiPredictionTime = prediction?['created_at'] != null
            ? DateTime.tryParse(prediction!['created_at'])
            : null;
        final aiHorizonMinutes =
            prediction?['horizon_minutes'] as int? ?? 30;
        final aiPredictionLoading =
            provider.isLoading && prediction == null;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TranslatedText(
                        "Welcome, $userName!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
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
                                  if (!_hardwareConnected)
                                    _disconnectedHardwarePlaceholder(
                                        context)
                                  else ...[
                                    _statusIndicatorsRow(context),
                                    const SizedBox(height: 12),
                                    _hardwareSnapshotCard(context),
                                  ],
                                ],
                              ),
                            ),
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
                                    child: _predictionCard(
                                      context,
                                      aiPredictedGlucose:
                                          aiPredictedGlucose,
                                      aiConfidenceScore:
                                          aiConfidenceScore,
                                      aiRiskLevel: aiRiskLevel,
                                      aiPredictionTime: aiPredictionTime,
                                      aiHorizonMinutes: aiHorizonMinutes,
                                      aiPredictionLoading:
                                          aiPredictionLoading,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RecommendationsScreen()),
                                    ),
                                    child: _recommendationsCard(
                                        context, provider),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const PatientCarePlanScreen()),
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
                            if (!_hardwareConnected)
                              _disconnectedHardwarePlaceholder(context)
                            else ...[
                              _statusIndicatorsRow(context),
                              const SizedBox(height: 12),
                              _hardwareSnapshotCard(context),
                            ],
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AIPredictionScreen()),
                              ),
                              child: _predictionCard(
                                context,
                                aiPredictedGlucose: aiPredictedGlucose,
                                aiConfidenceScore: aiConfidenceScore,
                                aiRiskLevel: aiRiskLevel,
                                aiPredictionTime: aiPredictionTime,
                                aiHorizonMinutes: aiHorizonMinutes,
                                aiPredictionLoading: aiPredictionLoading,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const RecommendationsScreen()),
                              ),
                              child:
                                  _recommendationsCard(context, provider),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PatientCarePlanScreen()),
                              ),
                              child: _carePlanCard(context),
                            ),
                          ],
                        ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Disconnected placeholder ───────────────────────────────────────────────

  Widget _disconnectedHardwarePlaceholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TranslatedText("No Hardware connected!",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/bluetooth-pairing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
            ),
            child: const TranslatedText("Get started"),
          ),
        ],
      ),
    );
  }

  // ── Glucose card ──────────────────────────────────────────────────────────

  Widget _glucoseCard(BuildContext context) {
    final colors = context.colors;
    final suppressValues =
        _hideSensorValuesUntilReconnect && !_hardwareConnected;
    final dotColor =
        suppressValues ? colors.textSecondary : _glucoseColor(colors);
    final showSpinner = _glucoseLoading && !suppressValues;

    final glucoseDisplay = (showSpinner || suppressValues)
        ? '– mg/dL'
        : '${_glucoseValue?.toStringAsFixed(0) ?? '–'} mg/dL';
    final updatedDisplay =
        suppressValues ? '–' : _timeAgo(_glucoseUpdatedAt);

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
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
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
                    color: dotColor, shape: BoxShape.circle),
                child: showSpinner
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(
                        suppressValues
                            ? Icons.bluetooth_disabled_rounded
                            : trendIcon,
                        color: Colors.white,
                        size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current Glucose Level:",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary)),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(glucoseDisplay,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: dotColor)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Last updated: $updatedDisplay',
                            style: TextStyle(
                                fontSize: 10,
                                color: colors.textSecondary),
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
                color: colors.textSecondary.withValues(alpha: 0.2)),
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
              decoration:
                  BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          TranslatedText(label,
              style: TextStyle(
                  fontSize: 12, color: colors.textSecondary)),
        ],
      );

  // ── IOB + Battery row ─────────────────────────────────────────────────────

  Widget _statusIndicatorsRow(BuildContext context) {
    final colors = context.colors;
    final suppressValues =
        _hideSensorValuesUntilReconnect && !_hardwareConnected;

    final String iobDisplay = (_iobLoading || suppressValues)
        ? '–'
        : (_iobValue?.toStringAsFixed(1) ?? '–');

    final double? batteryPercent = suppressValues
        ? null
        : _hardwareBatteryPercent != null
            ? (_hardwareBatteryPercent!.clamp(0, 100) / 100.0)
            : _parseBatteryPercent(_batteryHealth);

    final String batteryDisplay = suppressValues
        ? '–'
        : batteryPercent != null
            ? '${(batteryPercent * 100).toInt()}'
            : (_batteryLoading && _hardwareLoading
                ? '–'
                : (_batteryHealth ?? '–'));

    final Color batteryColor = batteryPercent == null
        ? const Color(0xFF4CAF50)
        : batteryPercent > 0.5
            ? const Color(0xFF4CAF50)
            : batteryPercent > 0.2
                ? const Color(0xFFFFB300)
                : const Color(0xFFEF1616);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
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
                        Text("IOB",
                            style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(iobDisplay,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary)),
                            Text(" U",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary)),
                          ],
                        ),
                        Text("Insulin on board",
                            style: TextStyle(
                                fontSize: 9.5,
                                color: colors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
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
                              strokeWidth: 2,
                              color: batteryColor),
                        )
                      : Icon(
                          batteryPercent != null &&
                                  batteryPercent <= 0.2
                              ? Icons.battery_alert_rounded
                              : Icons.battery_charging_full_rounded,
                          size: 19,
                          color: batteryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Sensor Battery",
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(batteryDisplay,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary)),
                          if (batteryPercent != null)
                            Text(" %",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (batteryPercent != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: batteryPercent,
                            minHeight: 5,
                            backgroundColor: colors.textSecondary
                                .withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation(batteryColor),
                          ),
                        )
                      else if (!_batteryLoading &&
                          _batteryHealth == null)
                        TranslatedText('No device paired',
                            style: TextStyle(
                                fontSize: 9.5,
                                color: colors.textSecondary))
                      else if (_batteryLoading && _hardwareLoading)
                        const SizedBox.shrink()
                      else
                        TranslatedText(_batteryHealth ?? 'Unknown',
                            style: TextStyle(
                                fontSize: 9.5,
                                color: colors.textSecondary)),
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

  Widget _hardwareSnapshotCard(BuildContext context) {
    final colors = context.colors;
    final suppressValues =
        _hideSensorValuesUntilReconnect && !_hardwareConnected;
    final String hardwareStatusText = _hardwareConnected
        ? (_hardwareLoading
            ? 'Reading advertised values...'
            : _hardwareStatus)
        : _hardwareStatus;
    final String hardwareDeviceLabel = suppressValues
        ? 'No hardware connected'
        : (_hardwareDeviceName ?? 'No hardware connected');

    final predictionValue =
        !suppressValues && _hardwarePredictionValue != null
            ? _hardwarePredictionValue!.toStringAsFixed(2)
            : '–';
    final latestGlucoseValue =
        !suppressValues && _hardwareLatestGlucoseValue != null
            ? _hardwareLatestGlucoseValue!.toStringAsFixed(2)
            : '–';

    return Container(
      width: double.infinity,
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
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hardwareConnected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_searching_rounded,
                size: 18,
                color: _hardwareConnected
                    ? colors.primary
                    : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(hardwareDeviceLabel,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(hardwareStatusText,
              style: TextStyle(
                  fontSize: 11, color: colors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _hardwareMetricTile(context,
                    title: 'Prediction', value: predictionValue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _hardwareMetricTile(context,
                    title: 'Latest Glucose',
                    value: latestGlucoseValue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hardwareMetricTile(BuildContext context,
      {required String title, required String value}) {
    final colors = context.colors;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary)),
        ],
      ),
    );
  }

  // ── Prediction card ───────────────────────────────────────────────────────

  Widget _predictionCard(
    BuildContext context, {
    required double? aiPredictedGlucose,
    required double? aiConfidenceScore,
    required String? aiRiskLevel,
    required DateTime? aiPredictionTime,
    required int aiHorizonMinutes,
    required bool aiPredictionLoading,
  }) {
    final colors = context.colors;
    final displayValue =
        aiPredictedGlucose ?? _hardwarePredictionValue ?? 135.0;
    final currentGlucose = _glucoseValue;
    double? percentageChange;
    bool isRising = true;

    if (currentGlucose != null && currentGlucose > 0) {
      percentageChange =
          ((displayValue - currentGlucose) / currentGlucose) * 100;
      isRising = percentageChange > 0;
    }

    String getPredictionTime() {
      if (aiPredictionTime != null) {
        final diff = DateTime.now().difference(aiPredictionTime);
        if (diff.inMinutes < 1) return "just now";
        if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
        if (diff.inHours < 24) return "${diff.inHours}h ago";
        return "${diff.inDays}d ago";
      }
      return "Waiting for data...";
    }

    Color getRiskColor() {
      if (aiRiskLevel == 'LOW') return const Color(0xFFEFDD16);
      if (aiRiskLevel == 'HIGH') return colors.error;
      return colors.success;
    }

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
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  TranslatedText("AI Prediction",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                  if (aiPredictionLoading)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: colors.primary),
                      ),
                    ),
                  if (aiRiskLevel != null && !aiPredictionLoading)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: getRiskColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(aiRiskLevel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: getRiskColor())),
                    ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AIPredictionScreen()),
                ),
                child: TranslatedText("View details",
                    style: TextStyle(
                        fontSize: 13,
                        color: colors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(displayValue.toStringAsFixed(0),
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
              if (percentageChange != null) ...[
                Icon(
                    isRising
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: isRising ? colors.error : colors.success,
                    size: 14),
                const SizedBox(width: 2),
                Text(
                    "${percentageChange.abs().toStringAsFixed(2)}%",
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            isRising ? colors.error : colors.success,
                        fontWeight: FontWeight.w600)),
              ] else if (_hardwarePredictionValue != null) ...[
                Icon(Icons.bluetooth_rounded,
                    color: colors.primary, size: 14),
                const SizedBox(width: 2),
                Text("From hardware",
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.primary,
                        fontWeight: FontWeight.w500)),
              ] else ...[
                Icon(Icons.timeline_rounded,
                    color: colors.textSecondary, size: 14),
                const SizedBox(width: 2),
                Text("Awaiting prediction",
                    style: TextStyle(
                        fontSize: 12, color: colors.textSecondary)),
              ],
              const SizedBox(width: 6),
              Text(
                  "Expected glucose in $aiHorizonMinutes minutes",
                  style: TextStyle(
                      fontSize: 12, color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            aiPredictionTime != null
                ? "Prediction generated: ${getPredictionTime()}"
                : (_hardwarePredictionValue != null
                    ? "Hardware prediction - syncing to cloud..."
                    : "No predictions available yet"),
            style: TextStyle(
                fontSize: 11, color: colors.textSecondary),
          ),
          if (aiConfidenceScore != null &&
              !aiPredictionLoading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: aiConfidenceScore / 100,
                      minHeight: 4,
                      backgroundColor: colors.textSecondary
                          .withValues(alpha: 0.15),
                      valueColor:
                          AlwaysStoppedAnimation(colors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text("${aiConfidenceScore.toInt()}% confidence",
                    style: TextStyle(
                        fontSize: 10, color: colors.textSecondary)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: ChartPainter(primaryColor: colors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: 14, height: 2.5, color: colors.primary),
              const SizedBox(width: 6),
              Text("Next $aiHorizonMinutes minutes",
                  style: TextStyle(
                      fontSize: 11, color: colors.textSecondary)),
              const SizedBox(width: 16),
              Container(
                  width: 14, height: 2.5, color: Colors.grey),
              const SizedBox(width: 6),
              Text("Last Hour",
                  style: TextStyle(
                      fontSize: 11, color: colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recommendations card ──────────────────────────────────────────────────

  Widget _recommendationsCard(
      BuildContext context, GlucoseProvider provider) {
    final colors = context.colors;
    final recs = provider.recommendations
        .take(3)
        .map((r) => r['message']?.toString() ?? '')
        .where((m) => m.isNotEmpty)
        .toList();

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
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TranslatedText("Recommendations",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RecommendationsScreen()),
                ),
                child: TranslatedText("View details",
                    style: TextStyle(
                        fontSize: 13,
                        color: colors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recs.isEmpty)
            TranslatedText("No recommendations available",
                style: TextStyle(
                    fontSize: 13, color: colors.textSecondary))
          else
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
                child: TranslatedText(
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

  Widget _rec(GlucoraColors colors, String recText) => Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: colors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Flexible(
            child: TranslatedText(recText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, color: colors.textPrimary)),
          ),
        ],
      );

  // ── Care plan card ────────────────────────────────────────────────────────

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
              offset: const Offset(0, 3)),
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
                padding:
                    const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 18, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TranslatedText('My Care Plan',
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
                    TranslatedText(
                        '$_doctorName  ·  Target: $_targetRange',
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        TranslatedText(
                            'Next appointment: $_nextAppointment',
                            style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary)),
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

// ── Chart painter (unchanged) ─────────────────────────────────────────────────

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
      canvas.drawLine(
          Offset(0, h * i / 3), Offset(w, h * i / 3), grid);
    }

    const xl = ['10', '20', '30', '40', '50', '60'];
    for (int i = 0; i < xl.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
            text: xl[i],
            style: const TextStyle(
                fontSize: 10, color: Color(0xFFAAAAAA))),
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
          ..color = primaryColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    for (final pt in [gry.last, grn.last]) {
      canvas.drawCircle(pt, 5, Paint()..color = primaryColor);
      canvas.drawCircle(pt, 3, Paint()..color = Colors.white);
    }
  }

  Path _sp(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      p.cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy,
          b.dx, b.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}