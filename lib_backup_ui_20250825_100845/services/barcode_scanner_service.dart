// lib/services/barcode_scanner_service.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeScannerService {
  /// Check and request camera permission for scanning
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isDenied || status.isRestricted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    return status.isGranted;
  }
  
  /// Validate barcode format (8-12 digit numeric)
  static bool isValidBarcode(String barcode) {
    // Remove any whitespace
    final cleaned = barcode.trim();
    
    // Check if it's numeric and within the length range
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;
    if (cleaned.length < 8 || cleaned.length > 12) return false;
    
    return true;
  }
  
  /// Scan a barcode
  static Future<String?> scanBarcode({
    required BuildContext context,
    String title = 'Scan Barcode',
    String? instructionText,
  }) async {
    // Check permission
    final hasPermission = await checkCameraPermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required for scanning')),
        );
      }
      return null;
    }
    
    // Navigate to scanner screen
    if (!context.mounted) return null;
    
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          title: title,
          instructionText: instructionText,
        ),
      ),
    );
    
    return result;
  }
}

/// Barcode Scanner Screen
class BarcodeScannerScreen extends StatefulWidget {
  final String title;
  final String? instructionText;

  const BarcodeScannerScreen({
    super.key,
    required this.title,
    this.instructionText,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _screenOpened = false;
  String? _lastScanned;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_screenOpened) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue == null) continue;
      
      final code = barcode.rawValue!;
      
      // Avoid processing the same barcode multiple times
      if (code == _lastScanned) continue;
      _lastScanned = code;
      
      // Validate the barcode
      if (!BarcodeScannerService.isValidBarcode(code)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid barcode format: $code\nExpected 8-12 digits'),
            backgroundColor: Colors.red,
          ),
        );
        // Reset last scanned after a delay to allow rescanning
        Future.delayed(const Duration(seconds: 2), () {
          setState(() => _lastScanned = null);
        });
        continue;
      }
      
      // Valid barcode found
      _screenOpened = true;
      Navigator.pop(context, code);
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          
          // Overlay with scanning frame
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: Stack(
              children: [
                // Cut out center rectangle
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // Instructions
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.instructionText ?? 'Align barcode within frame',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                
                // Manual entry button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showManualEntryDialog(),
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Enter Manually'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Scanning animation
          Center(
            child: Container(
              width: 280,
              height: 280,
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  // Corner markers
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCornerMarker(true, true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCornerMarker(true, false),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCornerMarker(false, true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCornerMarker(false, false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.green, width: 4) : BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _showManualEntryDialog() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 12,
          decoration: const InputDecoration(
            hintText: '8-12 digit barcode',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (BarcodeScannerService.isValidBarcode(value)) {
              Navigator.pop(context, value);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid barcode format. Must be 8-12 digits.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text;
              if (BarcodeScannerService.isValidBarcode(value)) {
                Navigator.pop(context, value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid barcode format. Must be 8-12 digits.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    if (result != null && mounted) {
      _screenOpened = true;
      Navigator.pop(context, result);
    }
  }
}