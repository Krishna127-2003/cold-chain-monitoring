import '../models/device_status.dart';

class DeviceStatusMapper {

  static int _battery(dynamic v) {
    final n = int.tryParse(v?.toString() ?? "");
    return n ?? 0;
  }

  static bool _bit(Map<String, dynamic> raw, int index) {
    return raw["mixbit$index"]?.toString() == "1";
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  static DeviceStatus fromApi(Map<String, dynamic> raw) {
    final systemErr = _bit(raw, 12);

    final compressorOn = _bit(raw, 0);
    final lowAmp = _bit(raw, 10);
    final highAmp = _bit(raw, 11);

    final powerOn = _bit(raw, 7);
    final batteryPercent =
        _battery(raw["battery"] ?? raw["battery_percent"] ?? raw["batteryLevel"]);

    final probeFail = _bit(raw, 3);

    final alarmMuted = _bit(raw, 4);
    final co2Active = _bit(raw, 13);

    final doorOpen = raw["door"]?.toString() == "1";

    return DeviceStatus(
      systemOk: !systemErr,

      compressorOn: compressorOn,
      lowAmp: lowAmp,
      highAmp: highAmp,

      powerOn: powerOn,
      batteryPercent: batteryPercent, // 🔋 HERE
      probeOk: !probeFail,

      alarmActive: co2Active,
      alarmMuted: alarmMuted,

      doorClosed: !doorOpen,

      pv: _num(raw["pv"] ?? raw["temp"]),
      sv: _num(raw["sv"]),

      updatedAt: DateTime.tryParse(raw["timestamp"] ?? ""),
    );
  }
}
