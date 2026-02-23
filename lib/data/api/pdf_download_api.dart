import 'package:url_launcher/url_launcher.dart';

class PdfDownloadApi {
  static Future<void> downloadPdf({
    required String deviceId,
    required String serviceType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final formattedStart =
        "${startDate.day.toString().padLeft(2, '0')}/"
        "${startDate.month.toString().padLeft(2, '0')}/"
        "${startDate.year}";

    final formattedEnd =
        "${endDate.day.toString().padLeft(2, '0')}/"
        "${endDate.month.toString().padLeft(2, '0')}/"
        "${endDate.year}";

    // 🎯 Route by device type
    final baseUrl = _baseUrlForType(serviceType);

    final url =
        "$baseUrl?device_id=$deviceId"
        "&startdate=$formattedStart"
        "&enddate=$formattedEnd"
        "&downloadtype=pdf";

    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open PDF");
    }
  }

  static String _baseUrlForType(String serviceType) {
    const base = "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api";

    switch (serviceType) {
      case "DATA_LOGGER_ULT":
        return "$base/Download16ch";
      case "ACTIVE_COOLPOD":
        return "$base/Downloadactcool";
      case "BBR":
        return "$base/Downloadbbr";
      case "DEEP_FREEZER":
        return "$base/Downloaddpfz";
      case "PLATELET":
        return "$base/Downloadpltinc";
      case "WALK_IN_COOLER":
        return "$base/Downloadwlkin";
      default:
        return "$base/Download";
    }
  }
}