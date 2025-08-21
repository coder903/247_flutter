// lib/screens/inspections/battery_test_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/inspection.dart';
import '../../models/battery_test.dart';
import '../../repositories/battery_test_repository.dart';
import '../../config/constants.dart';
import '../../utils/battery_calculator.dart';
import '../../services/photo_service.dart';
import 'component_test_list_screen.dart';


class BatteryTestScreen extends StatefulWidget {
  final Inspection inspection;
  final String propertyName;

  const BatteryTestScreen({
    super.key,
    required this.inspection,
    required this.propertyName,
  });

  @override
  State<BatteryTestScreen> createState() => _BatteryTestScreenState();
}

class _BatteryTestScreenState extends State<BatteryTestScreen> {
  final BatteryTestRepository _batteryRepo = BatteryTestRepository();
  final _formKey = GlobalKey<FormState>();
  final _currentReadingController = TextEditingController();
  final _voltageReadingController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _panelConnectionController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<BatteryTest> _batteryTests = [];
  bool _isLoading = true;
  
  // Form state
  String _selectedPosition = 'B1';
  double _selectedAmpHours = 7.0;
  bool? _testPassed;
  double? _minRequired;
  String? _photoPath;
  String? _videoPath;
  
  // Available positions (can be expanded based on property)
  final List<String> _positions = ['B1', 'B2', 'B3', 'B4', 'PS1', 'PS2'];

  @override
  void initState() {
    super.initState();
    _loadExistingBatteryTests();
    _currentReadingController.addListener(_calculatePassFail);
  }

  @override
  void dispose() {
    _currentReadingController.dispose();
    _voltageReadingController.dispose();
    _temperatureController.dispose();
    _barcodeController.dispose();
    _serialNumberController.dispose();
    _panelConnectionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingBatteryTests() async {
    setState(() => _isLoading = true);
    try {
      _batteryTests = await _batteryRepo.getByInspection(widget.inspection.id!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading battery tests: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculatePassFail() {
    final currentReading = double.tryParse(_currentReadingController.text);
    if (currentReading == null) {
      setState(() {
        _testPassed = null;
        _minRequired = null;
      });
      return;
    }
    
    final minRequired = BatteryCalculator.getMinRequired(_selectedAmpHours);
    final passed = BatteryCalculator.calculatePass(_selectedAmpHours, currentReading);
    
    setState(() {
      _minRequired = minRequired;
      _testPassed = passed;
    });
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
    
    if (result != null) {
      _barcodeController.text = result;
    }
  }

  Future<void> _takeBatteryPhoto() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available')),
          );
        }
        return;
      }

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            cameras: cameras,
            isVideo: false,
          ),
        ),
      );
      
      if (result != null) {
        setState(() => _photoPath = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _takeBatteryVideo() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available')),
          );
        }
        return;
      }

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            cameras: cameras,
            isVideo: true,
          ),
        ),
      );
      
      if (result != null) {
        setState(() => _videoPath = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _saveBatteryTest() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentReading = double.parse(_currentReadingController.text);
    final voltageReading = double.tryParse(_voltageReadingController.text);
    final temperature = double.tryParse(_temperatureController.text);
    
    try {
      final batteryTest = BatteryTest(
        inspectionId: widget.inspection.id!,
        position: _selectedPosition,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        serialNumber: _serialNumberController.text.isEmpty ? null : _serialNumberController.text,
        ratedAmpHours: _selectedAmpHours,
        voltageReading: voltageReading,
        currentReading: currentReading,
        temperatureF: temperature,
        panelConnection: _panelConnectionController.text.isEmpty ? null : _panelConnectionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        photoPath: _photoPath,
        videoPath: _videoPath,
      );
      
      await _batteryRepo.insert(batteryTest);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Battery $_selectedPosition saved - ${_testPassed! ? "PASSED" : "FAILED"}'),
            backgroundColor: _testPassed! ? Colors.green : Colors.red,
          ),
        );
        
        // Clear form for next battery
        _clearForm();
        await _loadExistingBatteryTests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving battery test: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _currentReadingController.clear();
    _voltageReadingController.clear();
    _temperatureController.clear();
    _barcodeController.clear();
    _serialNumberController.clear();
    _panelConnectionController.clear();
    _notesController.clear();
    setState(() {
      _selectedPosition = 'B1';
      _selectedAmpHours = 7.0;
      _testPassed = null;
      _minRequired = null;
      _photoPath = null;
      _videoPath = null;
    });
  }

  void _navigateToComponentTests() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentTestListScreen(  // <- Make sure it says ComponentTestListScreen, not ComponentTestScreen
          inspection: widget.inspection,
          propertyName: widget.propertyName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Tests'),
        actions: [
          if (_batteryTests.isNotEmpty)
            TextButton.icon(
              onPressed: _navigateToComponentTests,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text('Next', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Property info bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    widget.propertyName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                
                // Existing tests summary
                if (_batteryTests.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tested: ${_batteryTests.length} batteries',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 4),
                            Text('${_batteryTests.where((t) => t.passed == true).length}'),
                            const SizedBox(width: 12),
                            Icon(Icons.cancel, color: Colors.red, size: 20),
                            const SizedBox(width: 4),
                            Text('${_batteryTests.where((t) => t.passed == false).length}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                
                // Battery test form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Position and Amp Hours row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Position', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedPosition,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: _positions.map((pos) {
                                        final isUsed = _batteryTests.any((t) => t.position == pos);
                                        return DropdownMenuItem(
                                          value: pos,
                                          child: Row(
                                            children: [
                                              Text(pos),
                                              if (isUsed) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.check, size: 16, color: Colors.green),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _selectedPosition = value);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Amp Hours', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<double>(
                                      value: _selectedAmpHours,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: AppConstants.commonAmpHourRatings.map((ah) {
                                        return DropdownMenuItem(
                                          value: ah,
                                          child: Text('$ah Ah'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _selectedAmpHours = value);
                                          _calculatePassFail();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Current Reading with Pass/Fail indicator
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Current Reading *', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _currentReadingController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: 'Enter current reading',
                                        suffixText: 'Ah',
                                        filled: _testPassed != null,
                                        fillColor: _testPassed == true 
                                            ? Colors.green.withOpacity(0.1)
                                            : _testPassed == false 
                                                ? Colors.red.withOpacity(0.1)
                                                : null,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        final reading = double.tryParse(value);
                                        if (reading == null || reading < 0) {
                                          return 'Invalid reading';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (_testPassed != null) ...[
                                const SizedBox(width: 16),
                                Container(
                                  margin: const EdgeInsets.only(top: 28),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _testPassed! ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _testPassed! ? Icons.check_circle : Icons.cancel,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _testPassed! ? 'PASS' : 'FAIL',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          // Min required display
                          if (_minRequired != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Minimum required: ${_minRequired!.toStringAsFixed(2)} Ah (85% of ${_selectedAmpHours})',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // Voltage and Temperature row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Voltage Reading', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _voltageReadingController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        hintText: 'Optional',
                                        suffixText: 'V',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Temperature', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _temperatureController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        hintText: 'Optional',
                                        suffixText: '°F',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Barcode row
                          const Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _barcodeController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter or scan barcode',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _scanBarcode,
                                icon: const Icon(Icons.qr_code_scanner),
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Additional fields
                          const Text('Serial Number', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _serialNumberController,
                            decoration: const InputDecoration(
                              hintText: 'Optional',
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          const Text('Panel Connection', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _panelConnectionController,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Main Panel, Booster PS1',
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Media capture
                          const Text('Documentation', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _takeBatteryPhoto,
                                  icon: Icon(
                                    _photoPath != null ? Icons.check_circle : Icons.camera_alt,
                                    color: _photoPath != null ? Colors.green : null,
                                  ),
                                  label: Text(_photoPath != null ? 'Photo Taken' : 'Take Photo'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _takeBatteryVideo,
                                  icon: Icon(
                                    _videoPath != null ? Icons.check_circle : Icons.videocam,
                                    color: _videoPath != null ? Colors.green : null,
                                  ),
                                  label: Text(_videoPath != null ? 'Video Taken' : 'Take Video'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Notes
                          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Any additional notes about this battery',
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _saveBatteryTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                              child: const Text(
                                'Save Battery Test',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Skip to device tests
                          if (_batteryTests.isEmpty) ...[
                            Center(
                              child: TextButton(
                                onPressed: _navigateToComponentTests,
                                child: const Text('Skip Battery Tests →'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Placeholder screens - to be implemented
class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement barcode scanner
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Barcode Scanner Coming Soon'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Simulate scan
                Navigator.pop(context, '12345678');
              },
              child: const Text('Simulate Scan'),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  final bool isVideo;

  const CameraScreen({
    super.key,
    required this.cameras,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Implement camera
    return Scaffold(
      appBar: AppBar(title: Text(isVideo ? 'Take Video' : 'Take Photo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVideo ? Icons.videocam : Icons.camera_alt,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(isVideo ? 'Video Camera Coming Soon' : 'Photo Camera Coming Soon'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Simulate capture
                Navigator.pop(context, '/path/to/file');
              },
              child: Text(isVideo ? 'Simulate Video' : 'Simulate Photo'),
            ),
          ],
        ),
      ),
    );
  }
}

