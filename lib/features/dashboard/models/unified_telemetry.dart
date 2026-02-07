class UnifiedTelemetry {
  final String deviceId;
  final DateTime? timestamp;

  final double? pv;
  final double? sv;

  final bool powerOn;
  final int battery;

  final bool compressor1;
  final bool compressor2;
  final bool compressor;

  final bool heater;
  final bool agitator;
  final bool defrost;

  final bool probeOk;

  final String alarm; // ← direct from backend (HIGH TEMP etc)

  UnifiedTelemetry({
    required this.deviceId,
    required this.timestamp,
    required this.pv,
    required this.sv,
    required this.powerOn,
    required this.battery,
    required this.compressor1,
    required this.compressor2,
    required this.compressor,
    required this.heater,
    required this.agitator,
    required this.defrost,
    required this.probeOk,
    required this.alarm,
  });
}
