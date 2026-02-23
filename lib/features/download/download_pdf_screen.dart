import 'package:flutter/material.dart';
import '../../data/api/pdf_download_api.dart';

class DownloadPdfScreen extends StatefulWidget {
  final String deviceId;
  final String serviceType;

  const DownloadPdfScreen({super.key, required this.deviceId, required this.serviceType,});

  @override
  State<DownloadPdfScreen> createState() => _DownloadPdfScreenState();
}

class _DownloadPdfScreenState extends State<DownloadPdfScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _downloading = false;

  String _format(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select start date first")));
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime.now(),
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1020),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        title: const Text("Download Data Log"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Device: ${widget.deviceId}",
              style: const TextStyle(color: Colors.white54),
            ),

            const SizedBox(height: 30),

            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Start Date",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _startDate == null ? "--" : _format(_startDate!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            InkWell(
              onTap: _pickEndDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "End Date",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _endDate == null ? "--" : _format(_endDate!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            OutlinedButton.icon(
              onPressed: _downloading
                  ? null
                  : () async {
                if (_startDate == null || _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Select both dates")),
                  );
                  return;
                }

                setState(() => _downloading = true);
                try {
                  await PdfDownloadApi.downloadPdf(
                    deviceId: widget.deviceId,
                    serviceType: widget.serviceType, // 👈 pass this
                    startDate: _startDate!,
                    endDate: _endDate!,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to open PDF download link"),
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _downloading = false);
                  }
                }
              },
              icon: _downloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_downloading ? "Preparing..." : "Download PDF"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
