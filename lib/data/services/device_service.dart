import '../services/api_client.dart';
import '../storage/secure_store.dart';

class DeviceService {
  final ApiClient _apiClient = ApiClient();
  final SecureStore _secureStore = SecureStore();

  Future<Map<String, dynamic>> verifyDevice({
    required String deviceId,
    required String productKey,
    required String equipmentType,
  }) async {
    final token = await _secureStore.getToken();

    final response = await _apiClient.post(
      "/device/verify",
      token: token,
      body: {
        "deviceId": deviceId,
        "productKey": productKey,
        "equipmentType": equipmentType,
      },
    );

    return response;
  }
}
