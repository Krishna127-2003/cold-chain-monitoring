import 'alert_processor.dart';

class AlertManager {
  static final AlertProcessor _processor = AlertProcessor();

  static Future<void> handleTelemetry({
    required String deviceId,
    required String equipmentType,
    double? temperature,
    double? sv,
    int? batteryPercent,
    required bool powerFail,
    required bool probeFail,
    required bool systemError,
  }) async {
    await _processor.process(
      deviceId: deviceId,
      equipmentType: equipmentType,
      temperature: temperature,
      sv: sv,
      batteryPercent: batteryPercent,
      powerFail: powerFail,
      probeFail: probeFail,
      systemError: systemError,
    );
  }
}
