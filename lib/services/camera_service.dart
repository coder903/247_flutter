// lib/services/camera_service.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'photo_service.dart';

class CameraService {
  static List<CameraDescription>? _cameras;
  
  /// Initialize cameras
  static Future<void> initCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }
  
  /// Get available cameras
  static List<CameraDescription> get cameras => _cameras ?? [];
  
  /// Check and request camera permission
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isDenied || status.isRestricted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    return status.isGranted;
  }
  
  /// Check and request microphone permission (for video)
  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isDenied || status.isRestricted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    return status.isGranted;
  }
  
  /// Take a photo
  static Future<String?> takePhoto({
    required BuildContext context,
    required String propertyId,
    required String deviceType,
    String? barcode,
  }) async {
    // Check permission
    final hasPermission = await checkCameraPermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
      }
      return null;
    }
    
    // Initialize cameras if needed
    if (_cameras == null || _cameras!.isEmpty) {
      await initCameras();
    }
    
    if (_cameras == null || _cameras!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera available')),
        );
      }
      return null;
    }
    
    // Navigate to camera screen
    if (!context.mounted) return null;
    
    final result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          cameras: _cameras!,
          isVideo: false,
        ),
      ),
    );
    
    if (result != null) {
      // Save and compress the photo
      final fileName = PhotoService.generatePhotoFileName(
        propertyId: propertyId,
        deviceType: deviceType,
        barcode: barcode,
      );
      
      final savedPath = await PhotoService.savePhoto(
        sourceFile: result,
        fileName: fileName,
        addGpsMetadata: true,
      );
      
      return savedPath;
    }
    
    return null;
  }
  
  /// Take a video
  static Future<String?> takeVideo({
    required BuildContext context,
    required String propertyId,
    required String deviceType,
    String? barcode,
  }) async {
    // Check permissions
    final hasCameraPermission = await checkCameraPermission();
    final hasMicPermission = await checkMicrophonePermission();
    
    if (!hasCameraPermission || !hasMicPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera and microphone permissions required')),
        );
      }
      return null;
    }
    
    // Initialize cameras if needed
    if (_cameras == null || _cameras!.isEmpty) {
      await initCameras();
    }
    
    if (_cameras == null || _cameras!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera available')),
        );
      }
      return null;
    }
    
    // Navigate to camera screen
    if (!context.mounted) return null;
    
    final result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          cameras: _cameras!,
          isVideo: true,
        ),
      ),
    );
    
    if (result != null) {
      // Generate filename for video
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeDeviceType = deviceType.replaceAll(RegExp(r'[^\w\s-]'), '');
      final barcodeStr = barcode != null ? '_$barcode' : '';
      final fileName = '${propertyId}_${safeDeviceType}${barcodeStr}_$timestamp.mp4';
      
      // Move video to app directory
      final photoDir = await PhotoService.getPhotoDirectory();
      final targetPath = '${photoDir.path}/$fileName';
      final targetFile = await result.copy(targetPath);
      
      return targetFile.path;
    }
    
    return null;
  }
}

/// Camera Screen for taking photos and videos
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isVideo;

  const CameraScreen({
    super.key,
    required this.cameras,
    required this.isVideo,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _errorMessage = 'No cameras available';
        _isInitializing = false;
      });
      return;
    }

    try {
      final camera = widget.cameras[_selectedCameraIndex];
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: widget.isVideo,
      );

      await _controller!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length <= 1) return;
    
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _isInitializing = true;
    });
    
    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      final image = await _controller!.takePicture();
      final file = File(image.path);
      
      if (!mounted) return;
      Navigator.pop(context, file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    if (_isRecording) {
      // Stop recording
      try {
        final video = await _controller!.stopVideoRecording();
        final file = File(video.path);
        
        if (!mounted) return;
        Navigator.pop(context, file);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping video: $e')),
        );
      }
    } else {
      // Start recording
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isVideo ? 'Take Video' : 'Take Photo'),
        backgroundColor: Colors.black,
        actions: [
          if (widget.cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview or error message
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_controller != null && _controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          
          // Recording indicator
          if (_isRecording)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recording',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Capture button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: widget.isVideo ? _toggleVideoRecording : _capturePhoto,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: widget.isVideo && _isRecording
                      ? const Icon(
                          Icons.stop,
                          size: 30,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}