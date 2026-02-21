import '../datalogger/models/datalogger_telemetry.dart';

class UnifiedTelemetry {
  final String deviceId;
  final DateTime? timestamp;

  final double? pv;
  final double? sv;

  final bool systemHealthy;

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
  final DateTime? logTime;

  UnifiedTelemetry({
    required this.deviceId,
    required this.timestamp,
    required this.pv,
    required this.sv,
    required this.systemHealthy,
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
    this.logTime,
  });

  factory UnifiedTelemetry.empty() {
  return UnifiedTelemetry(
    deviceId: "",
    timestamp: null,
    pv: 0,
    sv: 0,
    powerOn: false,
    battery: 0,
    compressor: false,
    compressor1: false,
    compressor2: false,
    heater: false,
    agitator: false,
    defrost: false,
    probeOk: true,
    alarm: "CONNECTING",
    systemHealthy: true,
  );
}

factory UnifiedTelemetry.fromLogger(
  String deviceId,
  DataloggerTelemetry logger,
) {
  return UnifiedTelemetry(
    deviceId: deviceId,
    timestamp: logger.timestamp,

    // logger doesn't have PV/SV
    pv: null,
    sv: null,

    // assume healthy unless backend says otherwise
    systemHealthy: true,

    powerOn: true,
    battery: 0,

    compressor1: false,
    compressor2: false,
    compressor: false,

    heater: false,
    agitator: false,
    defrost: false,

    probeOk: true,

    alarm: "NONE",
    logTime: null,
  );
}
}
