import 'alert_type.dart';
import 'alert_status.dart';

class AlertEvent {
  final String deviceId;
  final AlertType type;
  AlertStatus status;
  final DateTime openedAt;
  DateTime? resolvedAt;

  AlertEvent({
    required this.deviceId,
    required this.type,
    required this.status,
    required this.openedAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
    "deviceId": deviceId,
    "type": type.name,
    "status": status.name,
    "openedAt": openedAt.toIso8601String(),
    "resolvedAt": resolvedAt?.toIso8601String(),
  };

  factory AlertEvent.fromJson(Map<String, dynamic> json) {
    return AlertEvent(
      deviceId: json["deviceId"],
      type: AlertType.values.firstWhere((e) => e.name == json["type"]),
      status: AlertStatus.values.firstWhere((e) => e.name == json["status"]),
      openedAt: DateTime.parse(json["openedAt"]),
      resolvedAt: json["resolvedAt"] == null
          ? null
          : DateTime.parse(json["resolvedAt"]),
    );
  }
}