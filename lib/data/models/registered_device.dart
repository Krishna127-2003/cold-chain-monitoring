class RegisteredDevice {
  final String deviceId;
  final String qrCode;
  final String productKey;
  final String serviceType;
  final String email;
  final String loginType;
  final DateTime registeredAt;

  RegisteredDevice({
    required this.deviceId,
    required this.qrCode,
    required this.productKey,
    required this.serviceType,
    required this.email,
    required this.loginType,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
        "deviceId": deviceId,
        "qrCode": qrCode,
        "productKey": productKey,
        "serviceType": serviceType,
        "email": email,
        "loginType": loginType,
        "registeredAt": registeredAt.toIso8601String(),
      };

  factory RegisteredDevice.fromJson(Map<String, dynamic> json) {
    return RegisteredDevice(
      deviceId: json["deviceId"],
      qrCode: json["qrCode"],
      productKey: json["productKey"],
      serviceType: json["serviceType"],
      email: json["email"],
      loginType: json["loginType"],
      registeredAt: DateTime.parse(json["registeredAt"]),
    );
  }
}
