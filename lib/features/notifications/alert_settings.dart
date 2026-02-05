class AlertSettings {
  bool app;
  bool email;
  bool sms;
  int level; // 0 to 5

  AlertSettings({
    required this.app,
    required this.email,
    required this.sms,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
        "app": app,
        "email": email,
        "sms": sms,
        "level": level,
      };

  factory AlertSettings.fromJson(Map<String, dynamic> json) {
    return AlertSettings(
      app: json["app"] ?? true,
      email: json["email"] ?? false,
      sms: json["sms"] ?? false,
      level: json["level"] ?? 1,
    );
  }
}
