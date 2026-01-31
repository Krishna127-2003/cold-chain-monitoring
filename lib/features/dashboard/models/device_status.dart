class DeviceStatus {
  final bool systemOk;

  final bool compressorOn;
  final bool lowAmp;
  final bool highAmp;

  final bool powerOn;
  final int batteryPercent; // 🔋 ADD THIS

  final bool probeOk;

  final bool alarmActive;
  final bool alarmMuted;

  final bool doorClosed;

  final double? pv;
  final double? sv;

  final DateTime? updatedAt;

  DeviceStatus({
    required this.systemOk,
    required this.compressorOn,
    required this.lowAmp,
    required this.highAmp,
    required this.powerOn,
    required this.batteryPercent, // 🔋 ADD THIS
    required this.probeOk,
    required this.alarmActive,
    required this.alarmMuted,
    required this.doorClosed,
    required this.pv,
    required this.sv,
    required this.updatedAt,
  });
}
