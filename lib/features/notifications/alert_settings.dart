class AlertSettings {
  bool app;
  int level;

  AlertSettings({
    required this.app,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
        "app": app,
        "level": level,
      };

  factory AlertSettings.fromJson(Map<String, dynamic> json) {
    return AlertSettings(
      app: json["app"] ?? true,
      level: json["level"] ?? 1,
    );
  }
}
