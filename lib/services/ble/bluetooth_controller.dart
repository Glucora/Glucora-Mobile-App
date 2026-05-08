import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────
// BluetoothController  (ChangeNotifier – Controller layer)
//
// Encapsulates all BLE scanning / connecting / disconnecting logic.
// The UI (BluetoothPairingScreen) only reads state and calls
// methods – it never touches FlutterBluePlus directly.
// ─────────────────────────────────────────────────────────────
class BluetoothController extends ChangeNotifier {
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;

  List<ScanResult> scanResults = [];
  List<BluetoothDevice> connectedDevices = [];
  bool isScanning = false;
  bool isBusy = false;
  String? statusMessage;

  // ── Lifecycle ────────────────────────────────────────────
  void init() {
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });

    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      isScanning = scanning;
      notifyListeners();
    });

    refreshConnectedDevices();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // ── Permissions ───────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  // ── Public API ────────────────────────────────────────────
  Future<void> refreshConnectedDevices() async {
    connectedDevices = FlutterBluePlus.connectedDevices;
    notifyListeners();
  }

  Future<void> startScan() async {
    if (isScanning || isBusy) return;
    _setBusy(true, 'Scanning for nearby devices...');

    try {
      if (!await _requestPermissions()) {
        statusMessage = 'Bluetooth permissions are required to scan.';
        notifyListeners();
        return;
      }
      scanResults = [];
      notifyListeners();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      statusMessage = scanResults.isEmpty
          ? 'Scan finished. No BLE advertisements found yet.'
          : 'Found ${scanResults.length} device(s). Tap one to connect.';
      notifyListeners();
    } catch (e) {
      statusMessage = 'Scan failed: $e';
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    _setBusy(true, 'Connecting to ${deviceLabel(device)}...');

    try {
      if (!await _requestPermissions()) {
        statusMessage = 'Bluetooth permissions are required to connect.';
        notifyListeners();
        return;
      }
      try { await device.createBond(); } catch (_) {}
      await device.connect(timeout: const Duration(seconds: 12));
      await refreshConnectedDevices();
      statusMessage = 'Connected to ${deviceLabel(device)}.';
      notifyListeners();
    } catch (e) {
      statusMessage = 'Connection failed: $e';
      notifyListeners();
      rethrow; // Let UI show a SnackBar
    } finally {
      _setBusy(false);
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    _setBusy(true);
    try {
      await device.disconnect();
      await refreshConnectedDevices();
      statusMessage = 'Disconnected from ${deviceLabel(device)}.';
      notifyListeners();
    } catch (e) {
      statusMessage = 'Disconnect failed: $e';
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  // ── Convenience helpers ───────────────────────────────────
  bool isConnected(BluetoothDevice device) =>
      connectedDevices.any((d) => d.remoteId == device.remoteId);

  String deviceLabel(BluetoothDevice device) {
    final name = device.platformName.trim();
    return name.isNotEmpty ? name : 'Device ${device.remoteId.str}';
  }

  void _setBusy(bool value, [String? message]) {
    isBusy = value;
    if (message != null) statusMessage = message;
    notifyListeners();
  }
}
