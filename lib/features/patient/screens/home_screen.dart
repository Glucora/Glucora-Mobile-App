// ═══════════════════════════════════════════════════════════════════════════════
// FILE: lib/features/patient/screens/home_screen.dart
// ═══════════════════════════════════════════════════════════════════════════════
// OVERVIEW:
// This is the main patient dashboard — the app's home screen. It displays
// real-time glucose readings (from BLE hardware or backend fallback), insulin
// on board (IOB), device battery, AI glucose predictions with mini chart,
// health recommendations, and care plan overview. The screen supports both
// portrait and landscape orientations with adaptive layouts.
//
// DATA SOURCES:
// - BLE hardware (primary): Real-time glucose, IOB, battery, predictions
// - Supabase backend (fallback): Last known readings when hardware disconnects
// - AI backend: Glucose predictions with confidence scores and risk levels
//
// KEY FEATURES:
// - Pull-to-refresh loads all data sources
// - Hardware disconnect detection with reconnection prompt
// - Custom painted glucose history + prediction chart
// - Responsive layout (portrait = stacked, landscape = side-by-side columns)
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL: _timeTicker
// PURPOSE: A global Timer that ticks every 30 seconds to trigger UI rebuilds.
//          This ensures "time ago" displays (like "5 min ago") stay current
//          without needing individual timers per widget. The timer is created
//          in initState and cancelled in dispose.
// ═══════════════════════════════════════════════════════════════════════════════
Timer? _timeTicker;

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: HomeScreen (StatefulWidget)
// PURPOSE: Creates the state object for the main dashboard. This is the entry
//          point for patients after login. The state holds all dashboard data
//          including glucose values, IOB, battery, hardware connection status,
//          and BLE history for the chart.
// ═══════════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATE: _HomeScreenState
// PURPOSE: Manages all mutable state for the Home dashboard. The state is
//          organized by data domain (care plan, glucose, IOB, battery, hardware).
//          Each domain maintains both "current display" values and "backend
//          fallback" values so the UI can seamlessly switch when hardware
//          disconnects.
// ═══════════════════════════════════════════════════════════════════════════════
class _HomeScreenState extends State<HomeScreen> {
  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Care Plan State
  // PURPOSE: Stores the patient's care plan information for display in the
  //          care plan card. These are populated from GlucoseProvider.carePlanRaw
  //          during _syncFromProvider(). Default values show "–" until data loads.
  // ═══════════════════════════════════════════════════════════════════════════════
  // Care plan
  String _doctorName = '';
  String _targetRange = '– mg/dL';
  String _nextAppointment = '–';

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Glucose State
  // PURPOSE: Tracks the current glucose reading with dual-source support:
  //          - _glucoseValue: What's currently displayed (hardware or backend)
  //          - _backendGlucoseValue: Last known value from Supabase (fallback)
  //          - _glucoseTrend: Direction (stable/up/down) for trend arrow icon
  //          - _glucoseUpdatedAt: When the reading was received (for "time ago")
  //          - _glucoseLoading: Shows spinner during initial load
  //          When hardware disconnects, _glucoseValue falls back to the backend value.
  // ═══════════════════════════════════════════════════════════════════════════════
  // Glucose
  double? _glucoseValue;
  double? _backendGlucoseValue;
  String _glucoseTrend = 'stable';
  String _backendGlucoseTrend = 'stable';
  DateTime? _glucoseUpdatedAt;
  DateTime? _backendGlucoseUpdatedAt;
  bool _glucoseLoading = true;

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Insulin On Board (IOB) State
  // PURPOSE: Tracks active insulin in the patient's system. Like glucose, it
  //          maintains both a display value and a backend fallback. IOB is
  //          critical for preventing insulin stacking (taking too much insulin
  //          while previous doses are still active).
  // ═══════════════════════════════════════════════════════════════════════════════
  // IOB
  double? _iobValue;
  double? _backendIobValue;
  bool _iobLoading = true;

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Device Battery State
  // PURPOSE: Tracks the connected glucose sensor/pump battery health.
  //          The battery value can come from either BLE hardware advertisement
  //          or the device repository in Supabase. Displayed as a percentage
  //          with a color-coded progress bar (green >50%, yellow >20%, red <20%).
  // ═══════════════════════════════════════════════════════════════════════════════
  // Battery
  String? _batteryHealth;
  bool _batteryLoading = true;

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: BLE Hardware State
  // PURPOSE: Manages the Bluetooth Low Energy connection to the glucose
  //          monitoring hardware. This is the primary data source for glucose,
  //          IOB, battery, and predictions. Key fields:
  //          - _bleHardwareService: Singleton service that manages BLE scanning,
  //            connection, and data streaming
  //          - _bleDataSub: StreamSubscription that listens to hardware data
  //          - _hardwareDeviceName: Name of the connected BLE device
  //          - _hardwareBatteryPercent: Battery level from hardware advertisement
  //          - _hardwarePredictionValue: AI prediction from hardware
  //          - _hardwareLatestGlucoseValue: Most recent glucose from hardware
  //          - _bleHistory: Rolling 1-hour window of glucose points for the chart
  //          - _hardwareConnected: Whether a device is currently connected
  //          - _hadHardwareConnection: True if we EVER connected (used to detect
  //            disconnects vs. never connected)
  //          - _disconnectSnackbarShown: Prevents showing disconnect snackbar multiple times
  //          - _hideSensorValuesUntilReconnect: When true, blanks out sensor values
  //            after disconnect to prevent showing stale data
  // ═══════════════════════════════════════════════════════════════════════════════
  // BLE hardware
  final BleHardwareService _bleHardwareService = BleHardwareService.instance;
  StreamSubscription<BleHardwareData>? _bleDataSub;
  String? _hardwareDeviceName;
  int? _hardwareBatteryPercent;
  double? _hardwarePredictionValue;
  double? _hardwareLatestGlucoseValue;
  final List<_GlucosePoint> _bleHistory = <_GlucosePoint>[];
  bool _hardwareConnected = false;
  bool _hardwareLoading = true;
  String _hardwareStatus = 'Searching for hardware...';
  bool _hadHardwareConnection = false;
  bool _disconnectSnackbarShown = false;
  bool _hideSensorValuesUntilReconnect = false;

  // ═══════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE: initState()
  // PURPOSE: Called once when the widget is first built. Initializes three things:
  //          1. Provider data: Fetches patient profile and all related data from Supabase
  //          2. BLE hardware: Starts scanning/connecting to the glucose device
  //          3. Time ticker: Creates a 30-second timer to refresh "time ago" text
  //          The order matters: provider init happens first so we have fallback
  //          data ready before hardware connects.
  // ═══════════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initProvider());
    _startBleHardwareFeed();
    _timeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE: dispose()
  // PURPOSE: Called when the widget is permanently removed. Cleans up ALL resources
  //          to prevent memory leaks:
  //          1. Cancels the BLE data stream subscription (stops receiving data)
  //          2. Stops the BLE hardware service (stops scanning/connecting)
  //          3. Cancels the global time ticker timer
  //          Failing to cancel subscriptions causes memory leaks and keeps
  //          background processes running after the screen is gone.
  // ═══════════════════════════════════════════════════════════════════════════════
  @override
  void dispose() {
    _bleDataSub?.cancel();
    _bleHardwareService.stop();
    _timeTicker?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _initProvider()
  // PURPOSE: Initializes the GlucoseProvider for the current authenticated user.
  //          If patientProfileId is null (first visit), calls provider.init()
  //          which fetches the profile and loads all data. Otherwise, just
  //          syncs from the already-loaded provider data. After initialization,
  //          _syncFromProvider() copies provider data into local state for display.
  // ═══════════════════════════════════════════════════════════════════════════════
  Future<void> _initProvider() async {
    final provider = context.read<GlucoseProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (provider.patientProfileId == null) {
      await provider.init(user.id);
    }

    _syncFromProvider(provider);
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _syncFromProvider()
  // PURPOSE: Copies data from GlucoseProvider into local state variables.
  //          This decouples the UI from directly accessing the provider during
  //          every build, and enables the dual-source (hardware + backend) pattern.
  //          The method handles:
  //          - Latest glucose reading (value, trend, timestamp)
  //          - Latest IOB value
  //          - Care plan data (doctor name, target range, appointment)
  //          - Device battery health
  //          Debug prints log the sync details in development builds.
  //          If hardware is NOT connected, display values fall back to backend data.
  // ═══════════════════════════════════════════════════════════════════════════════
  void _syncFromProvider(GlucoseProvider provider) {
    final reading = provider.latestReading;
    final iob = provider.latestIob;
    final carePlan = provider.carePlanRaw;

    // Log sync info for debugging
    if (kDebugMode) {
      print('[HomeScreen] _syncFromProvider called');
      print('[HomeScreen] Latest reading: $reading');
      print('[HomeScreen] Loaded logs count: ${provider.logs.length}');
      if (provider.logs.isNotEmpty) {
        final oldestLog = provider.logs.last;
        final newestLog = provider.logs.first;
        print(
          '[HomeScreen] Log range: ${oldestLog.recordedAt} to ${newestLog.recordedAt}',
        );
      }
    }

    if (reading != null) {
      final value = double.tryParse(reading['value_mg_dl'].toString());
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
      final iobVal = double.tryParse(iob['total_iob_units'].toString());
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
        _doctorName =
            doctorProfile?['users']?['full_name'] ??
            provider.carePlanDoctorName;
        _targetRange = (min != null && max != null)
            ? '$min–$max mg/dL'
            : '– mg/dL';
        _nextAppointment = next ?? '–';
      });
    }

    // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Device Battery State
  // PURPOSE: Tracks the connected glucose sensor/pump battery health.
  //          The battery value can come from either BLE hardware advertisement
  //          or the device repository in Supabase. Displayed as a percentage
  //          with a color-coded progress bar (green >50%, yellow >20%, red <20%).
  // ═══════════════════════════════════════════════════════════════════════════════
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

    // Trigger rebuild for chart when logs are updated
    if (provider.logs.isNotEmpty || _bleHistory.isNotEmpty) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _onRefresh()
  // PURPOSE: Pull-to-refresh handler. Reloads ALL data sources in parallel:
  //          - Latest glucose reading from Supabase
  //          - Full glucose log history
  //          - Latest AI prediction
  //          - Latest IOB value
  //          - Care plan data
  //          - Recommendations (limited to 3 for preview)
  //          After all loads complete, syncs the new data into local state.
  //          Future.wait() runs all loads concurrently for speed.
  // ═══════════════════════════════════════════════════════════════════════════════
  Future<void> _onRefresh() async {
    final provider = context.read<GlucoseProvider>();
    await Future.wait([
      provider.loadLatestReading(),
      provider.loadLogs(),
      provider.loadLatestPrediction(),
      provider.loadLatestIob(),
      provider.loadCarePlan(),
      provider.loadRecommendations(limit: 3),
    ]);
    _syncFromProvider(provider);
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _startBleHardwareFeed()
  // PURPOSE: Establishes the BLE data stream connection. This is the core of
  //          real-time glucose monitoring. The method:
  //          1. Cancels any existing subscription (prevents duplicate listeners)
  //          2. Listens to BleHardwareService.dataStream for incoming data
  //          3. On each data packet, updates local state with new values
  //          4. Appends glucose values to _bleHistory for chart rendering
  //          5. Detects disconnections and shows reconnection prompts
  //          6. Manages the "hide values until reconnect" state for stale data
  //          The stream provides: glucose, prediction, IOB, battery, connection status
  // ═══════════════════════════════════════════════════════════════════════════════
  Future<void> _startBleHardwareFeed() async {
    _bleDataSub?.cancel();

    _bleDataSub = _bleHardwareService.dataStream.listen((data) {
      if (!mounted) return;

      if (kDebugMode) {
        print(
          '[HomeScreen] BLE DATA: glucose=${data.latestGlucoseValue}, '
          'pred=${data.predictionValue}, iob=${data.iobValue}, '
          'battery=${data.batteryPercent}%, connected=${data.isConnected}',
        );
      }

      if (data.latestGlucoseValue != null) {
        _appendBleHistory(data.latestGlucoseValue!);
        if (kDebugMode) {
          print(
            '[HomeScreen] ✓ Added to BLE history: ${data.latestGlucoseValue} mg/dL',
          );
        }
      }

      final didJustLoseConnection = _hardwareConnected && !data.isConnected;
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

        if (!data.isConnected && _hideSensorValuesUntilReconnect) {
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _appendBleHistory()
  // PURPOSE: Maintains a rolling 1-hour window of glucose data points from the
  //          BLE hardware for chart rendering. The algorithm:
  //          1. If the new value is the same as the last one within 20 seconds,
  //             update the timestamp of the existing point (prevents duplicate points)
  //          2. Otherwise, add a new _GlucosePoint with current time and value
  //          3. Remove any points older than 1 hour to keep the chart performant
  //          This ensures the chart always shows the most recent hour of data
  //          without growing unbounded.
  // ═══════════════════════════════════════════════════════════════════════════════
  void _appendBleHistory(double value) {
    final now = DateTime.now();
    if (_bleHistory.isNotEmpty) {
      final last = _bleHistory.last;
      final isSameValue = (last.value - value).abs() < 0.01;
      if (isSameValue && now.difference(last.time).inSeconds < 20) {
        _bleHistory[_bleHistory.length - 1] = _GlucosePoint(now, value);
        return;
      }
    }

    _bleHistory.add(_GlucosePoint(now, value));

    final cutoff = now.subtract(const Duration(hours: 1));
    _bleHistory.removeWhere((point) => point.time.isBefore(cutoff));
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _buildChartSeries()
  // PURPOSE: Builds the data structure needed by the custom chart painter.
  //          Combines two data sources into a unified timeline:
  //          1. Supabase logs: Historical glucose readings from the past hour
  //          2. BLE history: Real-time glucose points from hardware
  //          Then adds prediction points (from hardware or AI) extending into
  //          the future by horizonMinutes. The result is a _GlucoseChartSeries
  //          containing history points and prediction points for the painter.
  //          Debug prints help diagnose chart data issues during development.
  // ═══════════════════════════════════════════════════════════════════════════════
  _GlucoseChartSeries _buildChartSeries(
    GlucoseProvider provider, {
    required int horizonMinutes,
    required double? aiPredictedGlucose,
    required DateTime? aiPredictionTime,
    required DateTime? aiPredictedFor,
  }) {
    final now = DateTime.now();
    final historyStart = now.subtract(const Duration(hours: 1));

    final history = <_GlucosePoint>[];

    // Add logs from Supabase
    for (final log in provider.logs) {
      if (log.isPredicted) continue;
      final loggedAt = log.recordedAt;
      // Use UTC comparison to avoid timezone issues
      final loggedAtUtc = loggedAt.isUtc ? loggedAt : loggedAt.toUtc();
      final nowUtc = now.toUtc();
      final historyStartUtc = historyStart.toUtc();

      if (loggedAtUtc.isBefore(historyStartUtc) ||
          loggedAtUtc.isAfter(nowUtc)) {
        if (kDebugMode && loggedAtUtc.isBefore(historyStartUtc)) {
          debugPrint(
            '[ChartSeries] Skipping old log: ${log.value} mg/dL at ${log.recordedAt} '
            '(outside 1-hour window)',
          );
        }
        continue;
      }
      history.add(_GlucosePoint(loggedAt.toLocal(), log.value));
    }

    // Add BLE history (already in local time)
    for (final point in _bleHistory) {
      if (point.time.toUtc().isBefore(historyStart.toUtc())) continue;
      history.add(point);
    }

    history.sort((a, b) => a.time.compareTo(b.time));

    if (kDebugMode) {
      print(
        '[ChartSeries] Built chart: ${history.length} total history points',
      );
      print(
        '[ChartSeries]   - From Supabase logs: ${provider.logs.where((l) => !l.isPredicted).length} logs',
      );
      print(
        '[ChartSeries]   - From BLE history: ${_bleHistory.length} BLE points',
      );
      print(
        '[ChartSeries]   - Chart history window: 1 hour (${historyStart.toLocal()} to $now)',
      );
      if (history.isNotEmpty) {
        print(
          '[ChartSeries] History range: ${history.first.value.toStringAsFixed(1)}-'
          '${history.last.value.toStringAsFixed(1)} mg/dL',
        );
      }
    }

    final predictionValue = _hardwarePredictionValue ?? aiPredictedGlucose;
    final horizon = Duration(minutes: horizonMinutes > 0 ? horizonMinutes : 30);
    DateTime predictionTime;
    if (_hardwarePredictionValue != null) {
      predictionTime = now.add(horizon);
    } else if (aiPredictedFor != null) {
      predictionTime = aiPredictedFor.toLocal();
    } else if (aiPredictionTime != null) {
      predictionTime = aiPredictionTime.toLocal().add(horizon);
    } else {
      predictionTime = now.add(horizon);
    }

    if (predictionTime.isBefore(now)) {
      predictionTime = now.add(horizon);
    }

    final predictions = <_GlucosePoint>[];
    if (predictionValue != null) {
      final anchorValue =
          _glucoseValue ?? (history.isNotEmpty ? history.last.value : null);
      if (anchorValue != null) {
        predictions.add(_GlucosePoint(now, anchorValue));
      }
      predictions.add(_GlucosePoint(predictionTime, predictionValue));
    }

    return _GlucoseChartSeries(history: history, predictions: predictions);
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // METHOD: _showHardwareDisconnectedSnackBar()
  // PURPOSE: Displays a persistent SnackBar when BLE hardware disconnects.
  //          Includes an action button that navigates to the Bluetooth pairing
  //          screen for easy reconnection. The snackbar lasts 12 seconds and
  //          is only shown once per disconnect event (tracked by flag).
  // ═══════════════════════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: UI Helpers
  // PURPOSE: Small utility methods used across multiple widgets in this screen.
  //          Keeping them as private methods keeps the build method clean and
  //          ensures consistent behavior (e.g., time formatting, color coding).
  // ═══════════════════════════════════════════════════════════════════════════════
  // ── Helpers ───────────────────────────────────────────────────────────────

  // METHOD: _timeAgo()
  // PURPOSE: Formats a DateTime into a human-readable relative time string:
  //          "just now", "5 min ago", "2h ago", or "1d ago". Returns "–" for null.
  //          Used by the glucose card to show when the last reading was received.
  String _timeAgo(DateTime? dt) {
    if (dt == null) return '–';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // METHOD: _glucoseColor()
  // PURPOSE: Returns a color based on glucose level for status indication:
  //          - <70 mg/dL: Yellow (hypoglycemia / low)
  //          - >180 mg/dL: Red (hyperglycemia / high)
  //          - 70-180 mg/dL: Primary theme color (in target range)
  //          Used by the glucose card's status dot and trend icon background.
  Color _glucoseColor(GlucoraColors colors) {
    if (_glucoseValue == null) return colors.primary;
    if (_glucoseValue! < 70) return const Color(0xFFEFDD16);
    if (_glucoseValue! > 180) return colors.error;
    return colors.primary;
  }

  // METHOD: _parseBatteryPercent()
  // PURPOSE: Parses a battery percentage string (e.g., "85%") into a normalized
  //          double (0.0 to 1.0). Returns null for invalid input. The normalized
  //          value is used by LinearProgressIndicator which expects 0.0-1.0 range.
  double? _parseBatteryPercent(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    return (parsed.clamp(0, 100)) / 100.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Build Method
  // PURPOSE: Renders the complete dashboard. The layout adapts to orientation:
  //          - Portrait: Single column with stacked cards
  //          - Landscape: Two columns (glucose/IOB/battery left, predictions/recs/care right)
  //          The build method uses Consumer<GlucoseProvider> to reactively rebuild
  //          when provider data changes. It extracts prediction data and builds
  //          the chart series, then delegates to sub-widget builders for each card.
  // ═══════════════════════════════════════════════════════════════════════════════
  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 18
        ? 'Good Afternoon'
        : 'Good Evening';

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
        final aiPredictedGlucose = (prediction?['predicted_value'] as num?)
            ?.toDouble();
        final aiConfidenceScore = (prediction?['confidence_score'] as num?)
            ?.toDouble();
        final aiRiskLevel = prediction?['risk_level'] as String?;
        final aiPredictionTime = prediction?['created_at'] != null
            ? DateTime.tryParse(prediction!['created_at'])
            : null;
        final aiPredictedFor = prediction?['predicted_for'] != null
            ? DateTime.tryParse(prediction!['predicted_for'])
            : null;
        final aiHorizonMinutes = prediction?['horizon_minutes'] as int? ?? 30;
        final aiPredictionLoading = provider.isLoading && prediction == null;

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
                        greeting,
                        style: TextStyle(
                          fontSize: 24,
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
                                    _disconnectedHardwarePlaceholder(context)
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
                                            const AIPredictionScreen(),
                                      ),
                                    ),
                                    child: _predictionCard(
                                      context,
                                      provider: provider,
                                      aiPredictedGlucose: aiPredictedGlucose,
                                      aiConfidenceScore: aiConfidenceScore,
                                      aiRiskLevel: aiRiskLevel,
                                      aiPredictionTime: aiPredictionTime,
                                      aiPredictedFor: aiPredictedFor,
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
                                            const RecommendationsScreen(),
                                      ),
                                    ),
                                    child: _recommendationsCard(
                                      context,
                                      provider,
                                    ),
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
                                  builder: (_) => const AIPredictionScreen(),
                                ),
                              ),
                              child: _predictionCard(
                                context,
                                provider: provider,
                                aiPredictedGlucose: aiPredictedGlucose,
                                aiConfidenceScore: aiConfidenceScore,
                                aiRiskLevel: aiRiskLevel,
                                aiPredictionTime: aiPredictionTime,
                                aiPredictedFor: aiPredictedFor,
                                aiHorizonMinutes: aiHorizonMinutes,
                                aiPredictionLoading: aiPredictionLoading,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RecommendationsScreen(),
                                ),
                              ),
                              child: _recommendationsCard(context, provider),
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
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Disconnected Hardware Placeholder
  // PURPOSE: Shown when no BLE hardware is connected. Displays a friendly
  //          message and a "Get started" button that navigates to the Bluetooth
  //          pairing screen. This replaces the hardware-specific cards
  //          (IOB, battery, hardware snapshot) when no device is paired.
  // ═══════════════════════════════════════════════════════════════════════════════
  // ── Disconnected placeholder ───────────────────────────────────────────────

  Widget _disconnectedHardwarePlaceholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TranslatedText(
            "No Hardware connected!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/bluetooth-pairing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const TranslatedText("Get started"),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Glucose Card Widget
  // PURPOSE: The primary dashboard card showing the current glucose level.
  //          Features:
  //          - Color-coded status dot (green=in range, yellow=low, red=high)
  //          - Trend arrow icon (up/down/stable) inside the dot
  //          - Glucose value in large bold text
  //          - "Last updated" timestamp with "time ago" formatting
  //          - Legend row showing Normal/Low/High color indicators
  //          When hardware disconnects and values are hidden, shows a Bluetooth
  //          disabled icon instead of the trend arrow.
  // ═══════════════════════════════════════════════════════════════════════════════
  // ── Glucose card ──────────────────────────────────────────────────────────


  Widget _glucoseCard(BuildContext context) {
    final colors = context.colors;
    final suppressValues =
        _hideSensorValuesUntilReconnect && !_hardwareConnected;
    final dotColor = suppressValues
        ? colors.textSecondary
        : _glucoseColor(colors);
    final showSpinner = _glucoseLoading && !suppressValues;

    final glucoseDisplay = (showSpinner || suppressValues)
        ? '– mg/dL'
        : '${_glucoseValue?.toStringAsFixed(0) ?? '–'} mg/dL';
    final updatedDisplay = suppressValues ? '–' : _timeAgo(_glucoseUpdatedAt);

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
                child: showSpinner
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        suppressValues
                            ? Icons.bluetooth_disabled_rounded
                            : trendIcon,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Glucose Level",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      glucoseDisplay,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated: $updatedDisplay',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
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
      TranslatedText(
        label,
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Status Indicators Row (IOB + Battery)
  // PURPOSE: Two side-by-side cards showing:
  //          - IOB (Insulin On Board): Active insulin with tap-to-expand detail sheet
  //          - Sensor Battery: Battery percentage with color-coded progress bar
  //          When hardware disconnects, both show "–" and hide the progress bar.
  //          The battery card shows different icons based on level (alert for <20%).
  // ═══════════════════════════════════════════════════════════════════════════════
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
        : (_batteryLoading && _hardwareLoading ? '–' : (_batteryHealth ?? '–'));

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.textSecondary.withValues(alpha: 0.2),
              ),
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
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : Icon(
                          Icons.water_drop_rounded,
                          size: 19,
                          color: colors.primary,
                        ),
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
                            Text(
                              " U",
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.textSecondary.withValues(alpha: 0.2),
              ),
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
                            strokeWidth: 2,
                            color: batteryColor,
                          ),
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
                          if (batteryPercent != null)
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
                      if (batteryPercent != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: batteryPercent,
                            minHeight: 5,
                            backgroundColor: colors.textSecondary.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: AlwaysStoppedAnimation(batteryColor),
                          ),
                        )
                      else if (!_batteryLoading && _batteryHealth == null)
                        TranslatedText(
                          'No device paired',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: colors.textSecondary,
                          ),
                        )
                      else if (_batteryLoading && _hardwareLoading)
                        const SizedBox.shrink()
                      else
                        TranslatedText(
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

  Widget _hardwareSnapshotCard(BuildContext context) {
    final colors = context.colors;
    final suppressValues =
        _hideSensorValuesUntilReconnect && !_hardwareConnected;
    final String hardwareStatusText = _hardwareConnected
        ? (_hardwareLoading ? 'Reading advertised values...' : _hardwareStatus)
        : _hardwareStatus;
    final String hardwareDeviceLabel = suppressValues
        ? 'No hardware connected'
        : (_hardwareDeviceName ?? 'No hardware connected');

    final predictionValue = !suppressValues && _hardwarePredictionValue != null
        ? _hardwarePredictionValue!.toStringAsFixed(2)
        : '–';
    final latestGlucoseValue =
        !suppressValues && _hardwareLatestGlucoseValue != null
        ? _hardwareLatestGlucoseValue!.toStringAsFixed(2)
        : '–';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
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
                child: Text(
                  hardwareDeviceLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hardwareStatusText,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _hardwareMetricTile(
                  context,
                  title: 'Prediction',
                  value: predictionValue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _hardwareMetricTile(
                  context,
                  title: 'Latest Glucose',
                  value: latestGlucoseValue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hardwareMetricTile(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: AI Prediction Card
  // PURPOSE: Displays the AI glucose prediction with rich information:
  //          - Large predicted value with mg/dL unit
  //          - Percentage change from current glucose (with up/down arrow)
  //          - Risk level badge (LOW/MEDIUM/HIGH) with color coding
  //          - Confidence score as a progress bar
  //          - Generation time ("5 min ago")
  //          - Custom painted mini chart showing history + prediction
  //          - Legend explaining chart lines
  //          Tapping the card navigates to the full AIPredictionScreen.
  //          The prediction can come from either hardware or the AI backend.
  // ═══════════════════════════════════════════════════════════════════════════════
  // ── Prediction card ───────────────────────────────────────────────────────

  Widget _predictionCard(
    BuildContext context, {
    required GlucoseProvider provider,
    required double? aiPredictedGlucose,
    required double? aiConfidenceScore,
    required String? aiRiskLevel,
    required DateTime? aiPredictionTime,
    required DateTime? aiPredictedFor,
    required int aiHorizonMinutes,
    required bool aiPredictionLoading,
  }) {
    final colors = context.colors;
    final displayValue =
        aiPredictedGlucose ?? _hardwarePredictionValue ?? 0.0;
    final chartSeries = _buildChartSeries(
      provider,
      horizonMinutes: aiHorizonMinutes,
      aiPredictedGlucose: aiPredictedGlucose,
      aiPredictionTime: aiPredictionTime,
      aiPredictedFor: aiPredictedFor,
    );
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
              Row(
                children: [
                  TranslatedText(
                    "AI Prediction",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (aiPredictionLoading)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  if (aiRiskLevel != null && !aiPredictionLoading)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: getRiskColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        aiRiskLevel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: getRiskColor(),
                        ),
                      ),
                    ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIPredictionScreen()),
                ),
                child: TranslatedText(
                  "View details",
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
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
                displayValue.toStringAsFixed(0),
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
                  style: TextStyle(fontSize: 18, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (percentageChange != null) ...[
                Icon(
                  isRising ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isRising ? colors.error : colors.success,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  "${percentageChange.abs().toStringAsFixed(2)}%",
                  style: TextStyle(
                    fontSize: 13,
                    color: isRising ? colors.error : colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_hardwarePredictionValue != null) ...[
                Icon(Icons.bluetooth_rounded, color: colors.primary, size: 14),
                const SizedBox(width: 2),
                Text(
                  "From hardware",
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.timeline_rounded,
                  color: colors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  "Awaiting prediction",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
              const SizedBox(width: 6),
              Text(
                "Expected glucose in $aiHorizonMinutes minutes",
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            aiPredictionTime != null
                ? "Prediction generated: ${getPredictionTime()}"
                : (_hardwarePredictionValue != null
                      ? "Hardware prediction - syncing to cloud..."
                      : "No predictions available yet"),
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
          if (aiConfidenceScore != null && !aiPredictionLoading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: aiConfidenceScore / 100,
                      minHeight: 4,
                      backgroundColor: colors.textSecondary.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${aiConfidenceScore.toInt()}% confidence",
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: ChartPainter(
                primaryColor: colors.primary,
                history: chartSeries.history,
                predictions: chartSeries.predictions,
                now: DateTime.now(),
                historyWindow: const Duration(hours: 1),
                futureWindow: Duration(minutes: aiHorizonMinutes),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 14, height: 2.5, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                "Next $aiHorizonMinutes minutes",
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(width: 16),
              Container(width: 14, height: 2.5, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "Last Hour",
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Recommendations Card
  // PURPOSE: Shows up to 3 AI-generated health recommendations as a preview.
  //          Each recommendation is displayed as a bullet point. Tapping the card
  //          navigates to the full RecommendationsScreen. Includes a medical
  //          disclaimer at the bottom. If no recommendations exist, shows
  //          "No recommendations available".
  // ═══════════════════════════════════════════════════════════════════════════════
  // ── Recommendations card ──────────────────────────────────────────────────

  Widget _recommendationsCard(BuildContext context, GlucoseProvider provider) {
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
              TranslatedText(
                "Recommendations",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecommendationsScreen(),
                  ),
                ),
                child: TranslatedText(
                  "View details",
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recs.isEmpty)
            TranslatedText(
              "No recommendations available",
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            )
          else
            ...recs.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _rec(colors, rec),
              ),
            ),
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
                child: TranslatedText(
                  "Recommendations are supportive and not a medical diagnosis.",
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
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
          color: colors.primary,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: TranslatedText(
          recText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
        ),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════════
  // SECTION: Care Plan Card
  // PURPOSE: A compact overview card showing the patient's care plan summary:
  //          - Doctor's name
  //          - Target glucose range
  //          - Next appointment date
  //          Features a colored left accent bar for visual distinction.
  //          Tapping navigates to the full PatientCarePlanScreen.
  // ═══════════════════════════════════════════════════════════════════════════════
  // ── Care plan card ────────────────────────────────────────────────────────

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
                        Icon(
                          Icons.assignment_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TranslatedText(
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
                    TranslatedText(
                      '$_doctorName  ·  Target: $_targetRange',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
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
                        TranslatedText(
                          'Next appointment: $_nextAppointment',
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

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: Chart Painter
// PURPOSE: CustomPainter that renders a glucose history + prediction chart.
//          This is a low-level Flutter API that draws directly to a Canvas.
//          The chart shows:
//          - Horizontal grid lines (3 levels)
//          - Time axis labels (120m, 90m, 60m, 30m, Now, 15m, 30m)
//          - Vertical "Now" divider line
//          - Hypoglycemia threshold line at 70 mg/dL (yellow dashed)
//          - Hyperglycemia threshold line at 180 mg/dL (red dashed)
//          - Gray line for historical glucose readings
//          - Primary-colored line with fill for predicted future readings
//          - Endpoint dot highlighting the prediction target
//          The painter handles coordinate mapping from glucose values (Y axis)
//          and time (X axis) to pixel positions on the canvas.
// ═══════════════════════════════════════════════════════════════════════════════
// ── Chart painter (unchanged) ─────────────────────────────────────────────────

class ChartPainter extends CustomPainter {
  final Color primaryColor;
  final List<_GlucosePoint> history;
  final List<_GlucosePoint> predictions;
  final DateTime now;
  final Duration historyWindow;
  final Duration futureWindow;

  const ChartPainter({
    required this.primaryColor,
    required this.history,
    required this.predictions,
    required this.now,
    required this.historyWindow,
    required this.futureWindow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const lh = 18.0;
    final h = size.height - lh;
    final w = size.width;
    final midX = w * 0.5;
    final historyStart = now.subtract(historyWindow);
    final futureEnd = now.add(futureWindow);

    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      canvas.drawLine(Offset(0, h * i / 3), Offset(w, h * i / 3), grid);
    }

    final ticks = <({DateTime time, String label})>[
      (time: now.subtract(const Duration(minutes: 120)), label: '120m'),
      (time: now.subtract(const Duration(minutes: 90)), label: '90m'),
      (time: now.subtract(const Duration(minutes: 60)), label: '60m'),
      (time: now.subtract(const Duration(minutes: 30)), label: '30m'),
      (time: now, label: 'Now'),
      (time: now.add(const Duration(minutes: 15)), label: '15m'),
      (time: now.add(const Duration(minutes: 30)), label: '30m'),
    ];
    for (final tick in ticks) {
      if (tick.time.isBefore(historyStart) || tick.time.isAfter(futureEnd)) {
        continue;
      }
      final x = _mapTimeToX(tick.time, historyStart, futureEnd, midX, w);
      final tp = TextPainter(
        text: TextSpan(
          text: tick.label,
          style: const TextStyle(fontSize: 9, color: Color(0xFFAAAAAA)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelX = x - tp.width / 2;
      final clampedX = labelX.clamp(0.0, w - tp.width);
      tp.paint(canvas, Offset(clampedX, h + 4));
    }

    canvas.drawLine(
      Offset(midX, 0),
      Offset(midX, h),
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );

    final allValues = <double>[
      ...history.map((e) => e.value),
      ...predictions.map((e) => e.value),
    ];
    double minY = 70;
    double maxY = 180;
    if (allValues.isNotEmpty) {
      minY = allValues.reduce((a, b) => a < b ? a : b);
      maxY = allValues.reduce((a, b) => a > b ? a : b);
    }
    if (minY == maxY) {
      minY -= 10;
      maxY += 10;
    }
    final padding = (maxY - minY) * 0.15;
    minY -= padding;
    maxY += padding;

    final hypoY = _mapValueToY(70.0, minY, maxY, h);
    final hyperY = _mapValueToY(180.0, minY, maxY, h);

    _drawDashedLine(
      canvas,
      Offset(0, hypoY),
      Offset(w, hypoY),
      Colors.yellow.withValues(alpha: 0.4),
      4,
      2,
    );

    _drawDashedLine(
      canvas,
      Offset(0, hyperY),
      Offset(w, hyperY),
      Colors.red.withValues(alpha: 0.4),
      4,
      2,
    );

    List<Offset> buildOffsets(List<_GlucosePoint> points) {
      return points.map((point) {
        final x = _mapTimeToX(point.time, historyStart, futureEnd, midX, w);
        final y = _mapValueToY(point.value, minY, maxY, h);
        return Offset(x, y);
      }).toList();
    }

    final historyOffsets = buildOffsets(history);
    if (historyOffsets.length >= 2) {
      canvas.drawPath(
        _sp(historyOffsets),
        Paint()
          ..color = const Color(0xFFCCCCCC)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    } else if (historyOffsets.length == 1) {
      canvas.drawCircle(
        historyOffsets.first,
        3,
        Paint()..color = const Color(0xFFCCCCCC),
      );
    }

    final predictionOffsets = buildOffsets(predictions);
    if (predictionOffsets.length >= 2) {
      final fill = _sp(predictionOffsets)
        ..lineTo(predictionOffsets.last.dx, h)
        ..lineTo(predictionOffsets.first.dx, h)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..color = primaryColor.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        _sp(predictionOffsets),
        Paint()
          ..color = primaryColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    } else if (predictionOffsets.length == 1) {
      canvas.drawCircle(
        predictionOffsets.first,
        4,
        Paint()..color = primaryColor,
      );
    }

    if (predictionOffsets.isNotEmpty) {
      final lastPoint = predictionOffsets.last;
      canvas.drawCircle(lastPoint, 5, Paint()..color = primaryColor);
      canvas.drawCircle(lastPoint, 3, Paint()..color = Colors.white);
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

  double _mapValueToY(double value, double minY, double maxY, double h) {
    final range = maxY - minY;
    final ratio = range == 0 ? 0.5 : (value - minY) / range;
    return h - (ratio.clamp(0.0, 1.0) * h);
  }

  double _mapTimeToX(
    DateTime time,
    DateTime historyStart,
    DateTime futureEnd,
    double midX,
    double w,
  ) {
    if (!time.isAfter(now)) {
      final clamped = time.isBefore(historyStart) ? historyStart : time;
      final totalMs = historyWindow.inMilliseconds.toDouble();
      final elapsedMs = clamped.difference(historyStart).inMilliseconds;
      final ratio = totalMs == 0 ? 0.0 : elapsedMs / totalMs;
      return midX * ratio.clamp(0.0, 1.0);
    }

    final clamped = time.isAfter(futureEnd) ? futureEnd : time;
    final totalMs = futureWindow.inMilliseconds.toDouble();
    final elapsedMs = clamped.difference(now).inMilliseconds;
    final ratio = totalMs == 0 ? 0.0 : elapsedMs / totalMs;
    return midX + (midX * ratio.clamp(0.0, 1.0));
  }

  // ignore: unused_element
  String _formatTime(DateTime time) {
    final diff = time.difference(now);
    final minutes = diff.inMinutes.abs();
    if (diff.isNegative) {
      return '$minutes min ago';
    } else if (minutes == 0) {
      return 'Now';
    } else {
      return '$minutes min';
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double dashWidth,
    double dashSpace,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distanceSquared = dx * dx + dy * dy;

    if (distanceSquared == 0) {
      canvas.drawCircle(start, 1.5, paint);
      return;
    }

    final distance = sqrt(distanceSquared.toDouble());
    final steps = (distance / (dashWidth + dashSpace)).ceil();

    for (int i = 0; i < steps; i++) {
      final t1 = (i * (dashWidth + dashSpace)) / distance;
      final t2 = ((i * (dashWidth + dashSpace)) + dashWidth) / distance;
      final p1 = Offset(start.dx + dx * t1, start.dy + dy * t1);
      final p2 = Offset(
        start.dx + dx * t2.clamp(0.0, 1.0),
        start.dy + dy * t2.clamp(0.0, 1.0),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.now != now ||
        oldDelegate.historyWindow != historyWindow ||
        oldDelegate.futureWindow != futureWindow ||
        !listEquals(oldDelegate.history, history) ||
        !listEquals(oldDelegate.predictions, predictions);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA CLASS: _GlucosePoint
// PURPOSE: Immutable data class representing a single glucose reading at a
//          specific time. Used by the chart painter and BLE history.
//          Implements == and hashCode for proper list comparison in shouldRepaint.
// ═══════════════════════════════════════════════════════════════════════════════
class _GlucosePoint {
  final DateTime time;
  final double value;

  const _GlucosePoint(this.time, this.value);

  @override
  bool operator ==(Object other) {
    return other is _GlucosePoint && other.time == time && other.value == value;
  }

  @override
  int get hashCode => Object.hash(time, value);
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA CLASS: _GlucoseChartSeries
// PURPOSE: Container for the two data series needed by the chart painter:
//          history (past readings) and predictions (future forecast).
// ═══════════════════════════════════════════════════════════════════════════════
class _GlucoseChartSeries {
  final List<_GlucosePoint> history;
  final List<_GlucosePoint> predictions;

  const _GlucoseChartSeries({required this.history, required this.predictions});
}
