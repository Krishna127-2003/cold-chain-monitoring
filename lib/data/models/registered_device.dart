class RegisteredDevice {
  final String deviceId;
  final String qrCode;
  final String productKey;
  final String serviceType;
  final String email;
  final String loginType;
  final DateTime registeredAt;
  final String displayName;
  final String department;
  final String area;
  final String pin;


  RegisteredDevice({
    required this.deviceId,
    required this.qrCode,
    required this.productKey,
    required this.serviceType,
    required this.email,
    required this.loginType,
    required this.registeredAt,
    required this.displayName,
    required this.department,
    required this.area,
    required this.pin,
  });

  Map<String, dynamic> toJson() => {
        "deviceId": deviceId,
        "qrCode": qrCode,
        "productKey": productKey,
        "serviceType": serviceType,
        "email": email,
        "loginType": loginType,
        "registeredAt": registeredAt.toIso8601String(),
        "displayName": displayName,
        "department": department,
        "area": area,
        "pin": pin,
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
      displayName: json["displayName"] ?? "Unnamed Device",
      department: json["department"] ?? "Unknown Department",
      area: json["area"] ?? "Unknown Area",
      pin: json["pin"] ?? "0000",
    );
  }
}
