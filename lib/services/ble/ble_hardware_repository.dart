import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_hardware_data.dart';

class BleHardwareUuids {
  static final Guid predictionService = Guid(
    'AB12ABAB-AB12-AB12-AB12-AB12AB12AB12',
  );
  static final Guid predictionCharacteristic = Guid(
    'AB12A1A2-AB12-AB12-AB12-AB12AB12AB12',
  );
  static final Guid iobCharacteristic = Guid(
    'AB12A2A4-AB12-AB12-AB12-AB12AB12AB12',
  );
  static final Guid latestGlucoseCharacteristic = Guid(
    'AB12A4A8-AB12-AB12-AB12-AB12AB12AB12',
  );

  static final Guid batteryService = Guid(
    '0000180F-0000-1000-8000-00805F9B34FB',
  );
  static final Guid batteryCharacteristic = Guid(
    '00002A19-0000-1000-8000-00805F9B34FB',
  );
}

class BleHardwareRepository {
  BleHardwareRepository({
    this.deviceNamePrefix = 'Glucora',
    this.pollInterval = const Duration(seconds: 4),
  });

  final String deviceNamePrefix;
  final Duration pollInterval;

  final StreamController<BleHardwareData> _controller =
      StreamController<BleHardwareData>.broadcast();

  static const bool _enableBleDebugLogs = kDebugMode;

  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  Timer? _pollTimer;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _batteryChar;
  BluetoothCharacteristic? _predictionChar;
  BluetoothCharacteristic? _iobChar;
  BluetoothCharacteristic? _latestGlucoseChar;
  final Set<String> _notifyEnabledCharacteristicIds = <String>{};
  final Map<String, List<int>> _lastNotifyPayloadByCharacteristic =
      <String, List<int>>{};
  final Map<String, DateTime> _lastNotifyTimestampByCharacteristic =
      <String, DateTime>{};
  final Map<String, StreamSubscription<List<int>>> _notifySubscriptions =
      <String, StreamSubscription<List<int>>>{};
  int _consecutiveEmptyPolls = 0;

  BleHardwareData _lastData = BleHardwareData.initial();

  Stream<BleHardwareData> get dataStream => _controller.stream;

  Future<void> start() async {
    _emit(
      _lastData.copyWith(isLoading: true, status: 'Preparing Bluetooth...'),
    );

    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      _emit(
        _lastData.copyWith(
          isLoading: false,
          status: 'Bluetooth is not supported on this device.',
        ),
      );
      return;
    }

    final granted = await _ensurePermissions();
    if (!granted) {
      _emit(
        _lastData.copyWith(
          isLoading: false,
          status: 'Bluetooth permissions are required.',
        ),
      );
      return;
    }

    _adapterSub?.cancel();
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      } else {
        _emit(
          _lastData.copyWith(
            isLoading: false,
            isConnected: false,
            status: 'Please enable Bluetooth to connect hardware.',
          ),
        );
      }
    });

    final currentState = await FlutterBluePlus.adapterState.first;
    if (currentState == BluetoothAdapterState.on) {
      await _startScan();
    }
  }

  Future<void> stop() async {
    _pollTimer?.cancel();
    _pollTimer = null;

    await _scanSub?.cancel();
    _scanSub = null;

    await _connectionSub?.cancel();
    _connectionSub = null;

    await _cancelNotifySubscriptions();

    await FlutterBluePlus.stopScan();

    final currentDevice = _device;
    _device = null;

    if (currentDevice != null) {
      try {
        await currentDevice.disconnect();
      } catch (_) {
        // Ignore disconnect errors to keep cleanup resilient.
      }
    }

    _batteryChar = null;
    _predictionChar = null;
    _iobChar = null;
    _latestGlucoseChar = null;
    _notifyEnabledCharacteristicIds.clear();
    _lastNotifyPayloadByCharacteristic.clear();
    _lastNotifyTimestampByCharacteristic.clear();
    _consecutiveEmptyPolls = 0;
  }

  Future<void> dispose() async {
    await stop();
    await _adapterSub?.cancel();
    await _controller.close();
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _startScan() async {
    await _scanSub?.cancel();
    _scanSub = null;

    _emit(
      _lastData.copyWith(isLoading: true, status: 'Scanning for hardware...'),
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final advName = result.advertisementData.advName;
        final platformName = result.device.platformName;
        final candidateName = advName.isNotEmpty ? advName : platformName;
        final isMatching = candidateName.toLowerCase().startsWith(
          deviceNamePrefix.toLowerCase(),
        );

        if (isMatching) {
          _connectToDevice(result.device, candidateName);
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 12),
      withServices: [BleHardwareUuids.predictionService],
    );
  }

  Future<void> _connectToDevice(
    BluetoothDevice device,
    String deviceName,
  ) async {
    await FlutterBluePlus.stopScan();

    if (_device?.remoteId == device.remoteId) {
      return;
    }

    _device = device;

    _emit(
      _lastData.copyWith(
        isLoading: true,
        deviceName: deviceName,
        status: 'Connecting to $deviceName...',
      ),
    );

    try {
      try {
        await device.createBond();
      } catch (_) {
        // Bonding can fail on platforms/devices where it is not required.
      }

      await device.connect(timeout: const Duration(seconds: 12));
      await _discoverCharacteristics(device);
      _listenConnectionState(device);
      _consecutiveEmptyPolls = 0;

      _emit(
        _lastData.copyWith(
          isLoading: false,
          isConnected: true,
          deviceName: deviceName,
          status: 'Connected',
        ),
      );

      await _readAndPublish();
      _startPolling();
    } catch (e) {
      _emit(
        _lastData.copyWith(
          isLoading: false,
          isConnected: false,
          status: 'Connection failed. Retrying scan...',
        ),
      );

      _device = null;
      await _startScan();
    }
  }

  void _listenConnectionState(BluetoothDevice device) {
    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        _emit(_lastData.copyWith(isConnected: true, status: 'Connected'));
      } else if (state == BluetoothConnectionState.disconnected) {
        _emit(
          _lastData.copyWith(
            isConnected: false,
            isLoading: false,
            status: 'Disconnected. Reconnecting...',
          ),
        );
        _device = null;
        _batteryChar = null;
        _predictionChar = null;
        _iobChar = null;
        _latestGlucoseChar = null;
        await _cancelNotifySubscriptions();
        _notifyEnabledCharacteristicIds.clear();
        _lastNotifyPayloadByCharacteristic.clear();
        _lastNotifyTimestampByCharacteristic.clear();
        _consecutiveEmptyPolls = 0;
        await _startScan();
      }
    });
  }

  Future<void> _discoverCharacteristics(BluetoothDevice device) async {
    final services = await device.discoverServices();
    _batteryChar = null;
    _predictionChar = null;
    _iobChar = null;
    _latestGlucoseChar = null;
    await _cancelNotifySubscriptions();
    _notifyEnabledCharacteristicIds.clear();
    _lastNotifyPayloadByCharacteristic.clear();
    _lastNotifyTimestampByCharacteristic.clear();
    _consecutiveEmptyPolls = 0;

    if (_enableBleDebugLogs) {
      _logBle(
        'Discovered ${services.length} services for ${device.remoteId.str}.',
      );
    }

    for (final service in services) {
      if (_enableBleDebugLogs) {
        _logBle('Service: ${service.uuid.str}');
      }

      for (final c in service.characteristics) {
        if (_enableBleDebugLogs) {
          _logBle(
            'Characteristic: service=${service.uuid.str}, char=${c.uuid.str}, '
            'read=${c.properties.read}, notify=${c.properties.notify}',
          );
        }

        final isBatteryService = _uuidEquals(
          service.uuid,
          BleHardwareUuids.batteryService,
        );

        if (isBatteryService &&
            _uuidEquals(c.uuid, BleHardwareUuids.batteryCharacteristic)) {
          _batteryChar = c;
        } else if (_uuidEquals(
          c.uuid,
          BleHardwareUuids.predictionCharacteristic,
        )) {
          _predictionChar = c;
        } else if (_uuidEquals(c.uuid, BleHardwareUuids.iobCharacteristic)) {
          _iobChar = c;
        } else if (_uuidEquals(
          c.uuid,
          BleHardwareUuids.latestGlucoseCharacteristic,
        )) {
          _latestGlucoseChar = c;
        }
      }
    }

    if (_enableBleDebugLogs) {
      _logBle(
        'Binding result -> battery=${_batteryChar?.uuid.str ?? 'missing'}, '
        'prediction=${_predictionChar?.uuid.str ?? 'missing'}, '
        'iob=${_iobChar?.uuid.str ?? 'missing'}, '
        'latestGlucose=${_latestGlucoseChar?.uuid.str ?? 'missing'}',
      );
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _readAndPublish());
  }

  Future<void> _readAndPublish() async {
    final batteryRaw = await _safeRead(_batteryChar);
    final predictionRaw = await _safeRead(_predictionChar);
    final iobRaw = await _safeRead(_iobChar);
    final latestGlucoseRaw = await _safeRead(_latestGlucoseChar);

    if (_enableBleDebugLogs) {
      _logBle('Raw battery=${_bytesToHex(batteryRaw)}');
      _logBle('Raw prediction=${_bytesToHex(predictionRaw)}');
      _logBle('Raw iob=${_bytesToHex(iobRaw)}');
      _logBle('Raw latestGlucose=${_bytesToHex(latestGlucoseRaw)}');
    }

    final battery = _decodeBatteryPercent(batteryRaw);
    final predictionValue = _decodeNumeric(predictionRaw);
    final iobValue = _decodeNumeric(iobRaw);
    final latestGlucoseValue = _decodeNumeric(latestGlucoseRaw);

    final hasAnyFreshValue =
        battery != null ||
        predictionValue != null ||
        iobValue != null ||
        latestGlucoseValue != null;

    if (!hasAnyFreshValue) {
      _consecutiveEmptyPolls++;
      if (_enableBleDebugLogs) {
        _logBle('Empty poll count: $_consecutiveEmptyPolls');
      }

      if (_consecutiveEmptyPolls >= 2) {
        await _handleConnectionLoss();
        return;
      }
    } else {
      _consecutiveEmptyPolls = 0;
    }

    if (_enableBleDebugLogs) {
      _logBle(
        'Decoded -> battery=$battery, prediction=$predictionValue, '
        'iob=$iobValue, latestGlucose=$latestGlucoseValue',
      );
    }

    _emit(
      _lastData.copyWith(
        isLoading: false,
        isConnected: true,
        batteryPercent: battery,
        predictionValue: predictionValue,
        iobValue: iobValue,
        latestGlucoseValue: latestGlucoseValue,
        status: 'Connected',
      ),
    );
  }

  Future<List<int>?> _safeRead(BluetoothCharacteristic? c) async {
    if (c == null) {
      if (_enableBleDebugLogs) {
        _logBle('Read skipped: characteristic is null.');
      }
      return null;
    }

    if (_enableBleDebugLogs) {
      _logBle(
        'Read attempt for ${c.uuid.str} '
        '(read=${c.properties.read}, notify=${c.properties.notify}, indicate=${c.properties.indicate})',
      );
    }

    try {
      if (c.properties.read) {
        final data = await c.read();
        if (data.isNotEmpty) {
          return data;
        }
      }
    } catch (e) {
      if (_enableBleDebugLogs) {
        _logBle('Read failed for ${c.uuid.str}: $e');
      }
    }

    return _readViaNotification(c);
  }

  Future<List<int>?> _readViaNotification(BluetoothCharacteristic c) async {
    final supportsNotify = c.properties.notify || c.properties.indicate;
    if (!supportsNotify) {
      if (_enableBleDebugLogs) {
        _logBle(
          'No notify fallback for ${c.uuid.str} (notify/indicate unsupported).',
        );
      }
      return null;
    }

    final characteristicId = c.uuid.str;
    try {
      if (!_notifyEnabledCharacteristicIds.contains(characteristicId)) {
        await c.setNotifyValue(true);
        _notifyEnabledCharacteristicIds.add(characteristicId);

        _notifySubscriptions[characteristicId] = c.lastValueStream.listen((
          data,
        ) {
          if (data.isNotEmpty) {
            _lastNotifyPayloadByCharacteristic[characteristicId] = data;
            _lastNotifyTimestampByCharacteristic[characteristicId] =
                DateTime.now();
          }
        });

        if (_enableBleDebugLogs) {
          _logBle('Enabled notifications for ${c.uuid.str}');
        }
      }

      final cached = _lastNotifyPayloadByCharacteristic[characteristicId];
      if (_isCachedNotifyPayloadFresh(characteristicId) &&
          cached != null &&
          cached.isNotEmpty) {
        return cached;
      }

      final data = await c.lastValueStream
          .where((payload) => payload.isNotEmpty)
          .first
          .timeout(const Duration(seconds: 3));

      _lastNotifyPayloadByCharacteristic[characteristicId] = data;
      _lastNotifyTimestampByCharacteristic[characteristicId] = DateTime.now();
      return data;
    } catch (e) {
      if (_enableBleDebugLogs) {
        _logBle('Notification read failed for ${c.uuid.str}: $e');
      }
      return null;
    }
  }

  bool _isCachedNotifyPayloadFresh(String characteristicId) {
    final timestamp = _lastNotifyTimestampByCharacteristic[characteristicId];
    if (timestamp == null) return false;

    final maxAgeMs = pollInterval.inMilliseconds * 2;
    final ageMs = DateTime.now().difference(timestamp).inMilliseconds;
    return ageMs <= maxAgeMs;
  }

  Future<void> _handleConnectionLoss() async {
    if (_enableBleDebugLogs) {
      _logBle('Connection health check failed. Forcing reconnect.');
    }

    _pollTimer?.cancel();
    _pollTimer = null;

    _emit(
      _lastData.copyWith(
        isConnected: false,
        isLoading: false,
        status: 'Connection lost. Reconnecting...',
      ),
    );

    final currentDevice = _device;
    _device = null;
    _batteryChar = null;
    _predictionChar = null;
    _iobChar = null;
    _latestGlucoseChar = null;
    await _cancelNotifySubscriptions();
    _notifyEnabledCharacteristicIds.clear();
    _lastNotifyPayloadByCharacteristic.clear();
    _lastNotifyTimestampByCharacteristic.clear();
    _consecutiveEmptyPolls = 0;

    if (currentDevice != null) {
      try {
        await currentDevice.disconnect();
      } catch (_) {}
    }

    await _startScan();
  }

  Future<void> _cancelNotifySubscriptions() async {
    for (final sub in _notifySubscriptions.values) {
      await sub.cancel();
    }
    _notifySubscriptions.clear();
  }

  String _bytesToHex(List<int>? data) {
    if (data == null) return 'null';
    if (data.isEmpty) return '[]';
    return data
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  void _logBle(String message) {
    if (_enableBleDebugLogs) {
      debugPrint('BLE: $message');
    }
  }

  bool _uuidEquals(Guid a, Guid b) {
    return _normalizeUuid(a.str) == _normalizeUuid(b.str);
  }

  String _normalizeUuid(String value) {
    return value.toLowerCase().replaceAll('-', '');
  }

  int? _decodeBatteryPercent(List<int>? data) {
    if (data == null || data.isEmpty) return null;
    return data.first.clamp(0, 100);
  }

  double? _decodeNumeric(List<int>? data) {
    if (data == null || data.isEmpty) return null;

    // Try multiple encodings because firmware may expose 4-byte values
    // as either float32 or integer.
    if (data.length >= 4) {
      final bytes = Uint8List.fromList(data.sublist(0, 4));
      final bd = ByteData.sublistView(bytes);
      final floatLe = bd.getFloat32(0, Endian.little);
      final floatBe = bd.getFloat32(0, Endian.big);
      final uintLe = bd.getUint32(0, Endian.little).toDouble();
      final uintBe = bd.getUint32(0, Endian.big).toDouble();

      final floatLeValid = floatLe.isFinite && floatLe.abs() >= 0.01;
      final floatBeValid = floatBe.isFinite && floatBe.abs() >= 0.01;

      if (floatLeValid && floatLe.abs() <= 100000) return floatLe;
      if (floatBeValid && floatBe.abs() <= 100000) return floatBe;
      if (uintLe <= 100000) return uintLe;
      if (uintBe <= 100000) return uintBe;

      return floatLe.isFinite ? floatLe : uintLe;
    }

    if (data.length >= 2) {
      final bytes = Uint8List.fromList(data.sublist(0, 2));
      final bd = ByteData.sublistView(bytes);
      return bd.getUint16(0, Endian.little).toDouble();
    }

    return data.first.toDouble();
  }

  void _emit(BleHardwareData data) {
    _lastData = data;
    if (!_controller.isClosed) {
      _controller.add(data);
    }
  }
}
