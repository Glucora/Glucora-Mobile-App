class BleHardwareData {
  final bool isLoading;
  final bool isConnected;
  final String? deviceName;
  final int? batteryPercent;
  final double? predictionValue;
  final double? iobValue;
  final double? latestGlucoseValue;
  final String status;

  const BleHardwareData({
    required this.isLoading,
    required this.isConnected,
    required this.deviceName,
    required this.batteryPercent,
    required this.predictionValue,
    required this.iobValue,
    required this.latestGlucoseValue,
    required this.status,
  });

  factory BleHardwareData.initial() {
    return const BleHardwareData(
      isLoading: true,
      isConnected: false,
      deviceName: null,
      batteryPercent: null,
      predictionValue: null,
      iobValue: null,
      latestGlucoseValue: null,
      status: 'Searching for hardware...',
    );
  }

  BleHardwareData copyWith({
    bool? isLoading,
    bool? isConnected,
    String? deviceName,
    int? batteryPercent,
    double? predictionValue,
    double? iobValue,
    double? latestGlucoseValue,
    String? status,
  }) {
    return BleHardwareData(
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      deviceName: deviceName ?? this.deviceName,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      predictionValue: predictionValue ?? this.predictionValue,
      iobValue: iobValue ?? this.iobValue,
      latestGlucoseValue: latestGlucoseValue ?? this.latestGlucoseValue,
      status: status ?? this.status,
    );
  }
}
