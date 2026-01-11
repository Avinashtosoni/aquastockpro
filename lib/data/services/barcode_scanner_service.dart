import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Result of barcode scan
class BarcodeScanResult {
  final String code;
  final BarcodeFormat format;
  
  BarcodeScanResult({required this.code, required this.format});
}

/// Service for barcode scanning
class BarcodeScannerService {
  static final BarcodeScannerService _instance = BarcodeScannerService._internal();
  factory BarcodeScannerService() => _instance;
  BarcodeScannerService._internal();

  /// Show barcode scanner dialog and return scanned code
  Future<BarcodeScanResult?> scanBarcode(BuildContext context) async {
    return await showDialog<BarcodeScanResult>(
      context: context,
      builder: (context) => const _BarcodeScannerDialog(),
    );
  }
}

class _BarcodeScannerDialog extends StatefulWidget {
  const _BarcodeScannerDialog();

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;
    
    setState(() => _hasScanned = true);
    
    Navigator.of(context).pop(
      BarcodeScanResult(
        code: barcode.rawValue!,
        format: barcode.format,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 350,
        height: 450,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Barcode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Flash toggle
                      IconButton(
                        icon: ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, state, child) {
                            return Icon(
                              state.torchState == TorchState.on
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                            );
                          },
                        ),
                        onPressed: () => _controller.toggleTorch(),
                      ),
                      // Camera switch
                      IconButton(
                        icon: const Icon(Icons.cameraswitch),
                        onPressed: () => _controller.switchCamera(),
                      ),
                      // Close
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Scanner
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                    // Scan overlay
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Instructions
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Point camera at barcode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for inline barcode scanner (for embedding in a page)
class InlineBarcodeScannerWidget extends StatefulWidget {
  final Function(BarcodeScanResult) onBarcodeScanned;
  final double height;

  const InlineBarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.height = 200,
  });

  @override
  State<InlineBarcodeScannerWidget> createState() => _InlineBarcodeScannerWidgetState();
}

class _InlineBarcodeScannerWidgetState extends State<InlineBarcodeScannerWidget> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;
    
    setState(() => _hasScanned = true);
    
    widget.onBarcodeScanned(
      BarcodeScanResult(
        code: barcode.rawValue!,
        format: barcode.format,
      ),
    );
    
    // Reset after 2 seconds to allow scanning again
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hasScanned = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),
      ),
    );
  }
}
