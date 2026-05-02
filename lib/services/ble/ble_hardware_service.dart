import 'dart:async';

import 'ble_hardware_data.dart';
import 'ble_hardware_repository.dart';

class BleHardwareService {
  BleHardwareService._();

  static final BleHardwareService instance = BleHardwareService._();

  final BleHardwareRepository _repo = BleHardwareRepository();

  Stream<BleHardwareData> get dataStream => _repo.dataStream;

  Future<void> start() => _repo.start();

  Future<void> stop() => _repo.stop();

  Future<void> dispose() => _repo.dispose();
}
