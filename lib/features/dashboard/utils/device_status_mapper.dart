import '../models/device_status.dart';

class DeviceStatusMapper {
  static int _int(dynamic v) =>
      int.tryParse(v?.toString() ?? "") ?? 0;

  static double? _double(dynamic v) =>
      double.tryParse(v?.toString() ?? "");

  static bool _isBitSet(int value, int bit) {
    return (value & (1 << bit)) != 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;

    final s = v.toString(); // "03/02/2026 01:23:41"
    final parts = s.split(' ');
    if (parts.length != 2) return null;

    final d = parts[0].split('/');
    final t = parts[1].split(':');
    if (d.length != 3 || t.length != 3) return null;

    return DateTime(
      int.parse(d[2]), // year
      int.parse(d[1]), // month
      int.parse(d[0]), // day
      int.parse(t[0]),
      int.parse(t[1]),
      int.parse(t[2]),
    );
  }

  static DeviceStatus fromApi(Map<String, dynamic> raw) {
    final status = _int(raw["status"]);
    final error = _int(raw["Error"]);

    final powerOn = _int(raw["pwron"]) == 1;

    return DeviceStatus(
      // SYSTEM
      systemOk: error == 0,

      // COMPRESSOR (example logic)
      compressorOn: powerOn,

      lowAmp: _isBitSet(status, 4),
      highAmp: _isBitSet(status, 5),

      // POWER
      powerOn: powerOn,

      // PROBE
      probeOk: !_isBitSet(status, 3),

      // ALARM
      alarmActive: error != 0,
      alarmMuted: false,

      // DOOR (not available yet)
      doorClosed: true,

      // VALUES
      pv: _double(raw["temp"]),
      sv: _double(raw["setv"]),

      batteryPercent: _int(raw["battery"]),

      updatedAt: _parseDate(raw["timestamp"]),
    );
  }
}
