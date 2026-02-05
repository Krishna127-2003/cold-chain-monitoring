import 'package:url_launcher/url_launcher.dart';

class PdfDownloadApi {
  static Future<void> downloadPdf({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final String formattedStart =
        "${startDate.day.toString().padLeft(2, '0')}/"
        "${startDate.month.toString().padLeft(2, '0')}/"
        "${startDate.year}";

    final String formattedEnd =
        "${endDate.day.toString().padLeft(2, '0')}/"
        "${endDate.month.toString().padLeft(2, '0')}/"
        "${endDate.year}";

    final url =
        "https://testingesp32-b6dwfgcqb7drf4fu.centralindia-01.azurewebsites.net/api/Download"
        "?device_id=$deviceId"
        "&startdate=$formattedStart"
        "&enddate=$formattedEnd"
        "&downloadtype=pdf";

    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open PDF download link");
    }
  }
}
