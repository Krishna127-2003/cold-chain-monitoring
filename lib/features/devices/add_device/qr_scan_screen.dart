// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../../routes/app_routes.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;


class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin {
  bool _scanned = false;

  final MobileScannerController _controller = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
  );

  bool _torchOn = false;
  bool _frontCamera = false;

  // ✅ pinch zoom
  double _baseZoom = 0.0;
  double _currentZoom = 0.0;

  // ✅ scan line animation
  late final AnimationController _scanLineController;

  // ✅ Gallery scan loading
  bool _galleryLoading = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  /// ✅ Extract deviceId from QR content
  /// Supports:
  /// 1. Full URL with device_id query
  /// 2. Plain numeric ID (fallback)
  String? _extractDeviceId(String raw) {
    final value = raw.trim();

    // CASE 1: URL with device_id
    try {
      final uri = Uri.tryParse(value);
      if (uri != null && uri.queryParameters.containsKey("device_id")) {
        final id = uri.queryParameters["device_id"];
        if (id != null && id.isNotEmpty) {
          return id;
        }
      }
    } catch (_) {}

    // CASE 2: Plain numeric device id
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return value;
    }

    // ❌ Invalid QR
    return null;
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    HapticFeedback.selectionClick();
    setState(() => _torchOn = !_torchOn);
  }

  void _switchCamera() async {
    await _controller.switchCamera();
    HapticFeedback.selectionClick();
    setState(() => _frontCamera = !_frontCamera);
  }

  void _setZoom(double value) async {
    final z = value.clamp(0.0, 1.0);
    _currentZoom = z;
    await _controller.setZoomScale(z);
    setState(() {});
  }

  void _goNext({
    required String equipmentType,
    required String deviceId,
  }) {
    if (_scanned) return;

    setState(() => _scanned = true);
    HapticFeedback.lightImpact();

    Navigator.pushNamed(
      context,
      AppRoutes.productKey,
      arguments: {
        "deviceId": deviceId,
        "equipmentType": equipmentType,
      },
    );

    // optional: allow scanning again after coming back
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _scanned = false);
    });
  }

  /// ✅ DEMO BUTTON: Instant deviceId = 5192
  void _demoSkip({
    required String equipmentType,
  }) {
    _goNext(equipmentType: equipmentType, deviceId: "5192");
  }

  /// ✅ Pick image from gallery and scan QR
  Future<void> _scanFromGallery(String equipmentType) async {
    if (_galleryLoading) return;

    setState(() => _galleryLoading = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) {
        setState(() => _galleryLoading = false);
        return;
      }

      final inputImage = mlkit.InputImage.fromFile(File(picked.path));

      final barcodeScanner =
          mlkit.BarcodeScanner(formats: [mlkit.BarcodeFormat.qrCode]);

      final barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();

      if (!mounted) return;

      if (barcodes.isEmpty) {
        setState(() => _galleryLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No QR code detected in this image ❌")),
        );
        return;
      }

      final raw = barcodes.first.rawValue ?? "";
      if (raw.trim().isEmpty) {
        setState(() => _galleryLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR detected but value is empty ❌")),
        );
        return;
      }

      setState(() => _galleryLoading = false);

      final deviceId = _extractDeviceId(raw);

      if (deviceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid QR code ❌")),
        );
        return;
      }

      _goNext(
        equipmentType: equipmentType,
        deviceId: deviceId,
      );

    } catch (e) {
      if (!mounted) return;
      setState(() => _galleryLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gallery scan failed: $e")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final equipmentType = (args?["equipmentType"] ?? "UNKNOWN").toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          /// ✅ Gallery Scan Button
          IconButton(
            tooltip: "Scan from gallery",
            onPressed: _galleryLoading
                ? null
                : () => _scanFromGallery(equipmentType),
            icon: _galleryLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          /// ✅ Camera View + pinch zoom
          GestureDetector(
            onScaleStart: (_) {
              _baseZoom = _currentZoom;
            },
            onScaleUpdate: (details) {
              final zoom = _baseZoom + ((details.scale - 1.0) * 0.35);
              _setZoom(zoom);
            },
            child: MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              onDetect: (capture) {
                if (_scanned) return;

                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;

                final rawValue = barcodes.first.rawValue;
                if (rawValue == null || rawValue.isEmpty) return;

                final deviceId = _extractDeviceId(rawValue);

                if (deviceId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid QR code ❌")),
                  );
                  return;
                }

                _goNext(
                  equipmentType: equipmentType,
                  deviceId: deviceId,
                );
              },
            ),
          ),

          /// ✅ GPay Overlay (rounded cutout + glow + scan line + corner borders)
          GPayScannerOverlay(
            scanLineAnimation: _scanLineController,
            cutOutSize: 270,
            borderRadius: 20,
          ),

          /// ✅ Top controls (Flash + Switch)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  _TopActionButton(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    label: _torchOn ? "Flash On" : "Flash Off",
                    onTap: _toggleTorch,
                  ),
                  const SizedBox(width: 12),
                  _TopActionButton(
                    icon: Icons.cameraswitch_rounded,
                    label: _frontCamera ? "Front" : "Back",
                    onTap: _switchCamera,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.zoom_in,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${(_currentZoom * 100).toInt()}%",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ✅ Bottom instruction card (GPay-like) + Demo button
          Positioned(
            bottom: 22,
            left: 16,
            right: 16,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withValues(alpha: isDark ? 0.08 : 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _scanned
                                  ? "QR scanned ✅ Redirecting..."
                                  : "Align the QR code inside the box to scan",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// ✅ Demo button (5192)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed:
                              _scanned ? null : () => _demoSkip(equipmentType: equipmentType),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.bolt),
                          label: const Text(
                            "Skip Scan (Demo 5192)",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// ✅ Optional: Zoom slider
          Positioned(
            bottom: 130,
            left: 30,
            right: 30,
            child: SafeArea(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: _currentZoom,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) => _setZoom(v),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Premium top action button
class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ GPay-like overlay widget
class GPayScannerOverlay extends StatelessWidget {
  final AnimationController scanLineAnimation;
  final double cutOutSize;
  final double borderRadius;

  const GPayScannerOverlay({
    super.key,
    required this.scanLineAnimation,
    required this.cutOutSize,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scanLineAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _GPayOverlayPainter(
            progress: scanLineAnimation.value,
            cutOutSize: cutOutSize,
            borderRadius: borderRadius,
          ),
        );
      },
    );
  }
}

class _GPayOverlayPainter extends CustomPainter {
  final double progress;
  final double cutOutSize;
  final double borderRadius;

  _GPayOverlayPainter({
    required this.progress,
    required this.cutOutSize,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final rrect = RRect.fromRectXY(cutOutRect, borderRadius, borderRadius);

    /// ✅ Dark overlay with cutout
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.72);

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    /// ✅ Glow around cutout (soft premium)
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawRRect(rrect, glowPaint);

    /// ✅ Corner borders (GPay style)
    final cornerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;

    // top-left
    canvas.drawLine(
      cutOutRect.topLeft + const Offset(8, 0),
      cutOutRect.topLeft + const Offset(8 + cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.topLeft + const Offset(0, 8),
      cutOutRect.topLeft + const Offset(0, 8 + cornerLen),
      cornerPaint,
    );

    // top-right
    canvas.drawLine(
      cutOutRect.topRight + const Offset(-8, 0),
      cutOutRect.topRight + const Offset(-8 - cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.topRight + const Offset(0, 8),
      cutOutRect.topRight + const Offset(0, 8 + cornerLen),
      cornerPaint,
    );

    // bottom-left
    canvas.drawLine(
      cutOutRect.bottomLeft + const Offset(8, 0),
      cutOutRect.bottomLeft + const Offset(8 + cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.bottomLeft + const Offset(0, -8),
      cutOutRect.bottomLeft + const Offset(0, -8 - cornerLen),
      cornerPaint,
    );

    // bottom-right
    canvas.drawLine(
      cutOutRect.bottomRight + const Offset(-8, 0),
      cutOutRect.bottomRight + const Offset(-8 - cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.bottomRight + const Offset(0, -8),
      cutOutRect.bottomRight + const Offset(0, -8 - cornerLen),
      cornerPaint,
    );

    /// ✅ Scan line animation
    final lineY = cutOutRect.top + (cutOutRect.height * progress);

    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.85),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(
          cutOutRect.left,
          lineY - 2,
          cutOutRect.width,
          4,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(cutOutRect.left, lineY - 2, cutOutRect.width, 4),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GPayOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
