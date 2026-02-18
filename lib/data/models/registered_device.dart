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

  final String pinHash;

  final int deviceNumber;

  final String modeOp;

  const RegisteredDevice({
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
    required this.pinHash,
    required this.deviceNumber,
    required this.modeOp,
  });

  factory RegisteredDevice.fromJson(Map<String, dynamic> json) {
    return RegisteredDevice(
      deviceId: json['deviceId'] ?? '',
      qrCode: json['qrCode'] ?? '',
      productKey: json['productKey'] ?? '',
      serviceType: json['serviceType'] ?? '',
      email: json['email'] ?? '',
      loginType: json['loginType'] ?? '',
      registeredAt: DateTime.tryParse(json['registeredAt'] ?? '') ??
          DateTime.now().toUtc(),
      displayName: json['displayName'] ?? '',
      department: json['department'] ?? '',
      area: json['area'] ?? '',
      pinHash: json['pinHash'] ?? '',
      deviceNumber: json['deviceNumber'] ?? 0,
      modeOp: json['modeOp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'qrCode': qrCode,
      'productKey': productKey,
      'serviceType': serviceType,
      'email': email,
      'loginType': loginType,
      'registeredAt': registeredAt.toIso8601String(),
      'displayName': displayName,
      'department': department,
      'area': area,
      'pinHash': pinHash,
      'deviceNumber': deviceNumber,
      'modeOp': modeOp,
    };
  }
}
