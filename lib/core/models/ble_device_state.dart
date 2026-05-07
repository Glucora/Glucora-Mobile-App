// lib\core\models\ble_device_state.dart
class BleDeviceState {
  final int batteryLevel;
  final bool isConnected;
  final double? currentReading;

  const BleDeviceState({
    required this.batteryLevel,
    required this.isConnected,
    this.currentReading,
  });

  BleDeviceState copyWith({
    int? batteryLevel,
    bool? isConnected,
    double? currentReading,
  }) {
    return BleDeviceState(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isConnected: isConnected ?? this.isConnected,
      currentReading: currentReading ?? this.currentReading,
    );
  }
}