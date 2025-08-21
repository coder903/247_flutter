// lib/screens/inspections/component_test_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../services/photo_service.dart';

class ComponentTestFormScreen extends StatefulWidget {
  final Inspection inspection;
  final Map<String, dynamic> device;
  final ComponentTest? existingTest;

  const ComponentTestFormScreen({
    super.key,
    required this.inspection,
    required this.device,
    this.existingTest,
  });

  @override
  State<ComponentTestFormScreen> createState() => _ComponentTestFormScreenState();
}

class _ComponentTestFormScreenState extends State<ComponentTestFormScreen> {
  final ComponentTestRepository _componentTestRepo = ComponentTestRepository();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  // Device-specific controllers
  final _sensitivityController = TextEditingController();
  final _decibelController = TextEditingController();
  final _sizeController = TextEditingController();
  
  String _testResult = 'Pass';
  bool _check24hrPost = false;
  DateTime? _servicedDate;
  DateTime? _hydroDate;
  String? _photoPath;
  String? _videoPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingTest();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _sensitivityController.dispose();
    _decibelController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _loadExistingTest() {
    if (widget.existingTest != null) {
      final test = widget.existingTest!;
      _testResult = test.testResult ?? 'Pass';
      _notesController.text = test.notes ?? '';
      _sensitivityController.text = test.sensitivity ?? '';
      _decibelController.text = test.decibelLevel ?? '';
      _sizeController.text = test.size ?? '';
      _check24hrPost = test.check24hrPost ?? false;
      _servicedDate = test.servicedDate;
      _hydroDate = test.hydroDate;
      _photoPath = test.photoPath;
      _videoPath = test.videoPath;
    }
  }

  String get _deviceTypeName => widget.device['device_type_name'] ?? 'Unknown Device';

  Widget _buildTestResultSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Test Result *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildResultButton('Pass', Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResultButton('Fail', Colors.red),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResultButton('Not Tested', Colors.orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultButton(String result, Color color) {
    final isSelected = _testResult == result;
    return OutlinedButton(
      onPressed: () => setState(() => _testResult = result),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color : null,
        foregroundColor: isSelected ? Colors.white : color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        result,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDeviceSpecificFields() {
    switch (_deviceTypeName) {
      case 'Smoke Detector':
      case 'Heat Detector':
        return _buildSmokeDetectorFields();
      
      case 'Horn/Strobe':
      case 'Horn':
      case 'Strobe':
        return _buildHornStrobeFields();
      
      case 'Fire Extinguisher':
        return _buildFireExtinguisherFields();
      
      case 'Emergency Light':
        return _buildEmergencyLightFields();
      
      case 'Exit Sign':
        return _buildExitSignFields();
      
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSmokeDetectorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Sensitivity', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _sensitivityController,
          decoration: const InputDecoration(
            hintText: 'Enter sensitivity reading',
            suffixText: '%/ft',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Typical range: 0.5-3.5%/ft obscuration',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHornStrobeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Decibel Level', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _decibelController,
          decoration: const InputDecoration(
            hintText: 'Enter decibel reading',
            suffixText: 'dB',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Minimum: 75dB at 10 feet',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFireExtinguisherFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        
        // Size
        const Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _sizeController,
          decoration: const InputDecoration(
            hintText: 'e.g., 5 lbs, 10 lbs, 20 lbs',
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Service Date
        const Text('Last Service Date', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  _servicedDate != null
                      ? DateFormat('MM/dd/yyyy').format(_servicedDate!)
                      : 'Select service date',
                  style: TextStyle(
                    fontSize: 16,
                    color: _servicedDate != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_servicedDate != null) ...[
          const SizedBox(height: 8),
          _buildServiceStatus(),
        ],
        
        const SizedBox(height: 20),
        
        // Hydrostatic Test Date
        const Text('Hydrostatic Test Date', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  _hydroDate != null
                      ? DateFormat('MM/dd/yyyy').format(_hydroDate!)
                      : 'Select hydro test date',
                  style: TextStyle(
                    fontSize: 16,
                    color: _hydroDate != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_hydroDate != null) ...[
          const SizedBox(height: 8),
          _buildHydroStatus(),
        ],
      ],
    );
  }

  Widget _buildServiceStatus() {
    if (_servicedDate == null) return const SizedBox.shrink();
    
    final monthsSinceService = DateTime.now().difference(_servicedDate!).inDays / 30;
    final needsService = monthsSinceService >= 12;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: needsService ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            needsService ? Icons.warning : Icons.check_circle,
            size: 16,
            color: needsService ? Colors.red[700] : Colors.green[700],
          ),
          const SizedBox(width: 8),
          Text(
            needsService
                ? 'Service overdue (${monthsSinceService.toInt()} months ago)'
                : 'Service current (${monthsSinceService.toInt()} months ago)',
            style: TextStyle(
              fontSize: 12,
              color: needsService ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHydroStatus() {
    if (_hydroDate == null) return const SizedBox.shrink();
    
    final yearsSinceHydro = DateTime.now().difference(_hydroDate!).inDays / 365;
    final needsHydro = yearsSinceHydro >= 5; // 5 years for most extinguishers
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: needsHydro ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            needsHydro ? Icons.warning : Icons.check_circle,
            size: 16,
            color: needsHydro ? Colors.red[700] : Colors.green[700],
          ),
          const SizedBox(width: 8),
          Text(
            needsHydro
                ? 'Hydro test overdue (${yearsSinceHydro.toStringAsFixed(1)} years ago)'
                : 'Hydro test current (${yearsSinceHydro.toStringAsFixed(1)} years ago)',
            style: TextStyle(
              fontSize: 12,
              color: needsHydro ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyLightFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('24 Hour Post Check', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: CheckboxListTile(
            title: const Text('24 hour post check completed'),
            subtitle: const Text('Battery maintained charge after 24 hours'),
            value: _check24hrPost,
            onChanged: (value) => setState(() => _check24hrPost = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Emergency lights should provide 90 minutes of illumination',
                  style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExitSignFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Exit Sign Checklist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Sign clearly visible and unobstructed\n'
                '• Letters properly illuminated\n'
                '• No physical damage\n'
                '• Battery backup functional (if applicable)',
                style: TextStyle(fontSize: 14, color: Colors.blue[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isServiceDate) async {
    final initialDate = isServiceDate ? _servicedDate : _hydroDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isServiceDate) {
          _servicedDate = picked;
        } else {
          _hydroDate = picked;
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    // TODO: Implement camera
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera integration coming soon')),
    );
    // Simulate photo taken
    setState(() => _photoPath = '/path/to/photo.jpg');
  }

  Future<void> _takeVideo() async {
    // TODO: Implement video
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video integration coming soon')),
    );
    // Simulate video taken
    setState(() => _videoPath = '/path/to/video.mp4');
  }

  Future<void> _saveTest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final test = ComponentTest(
        id: widget.existingTest?.id,
        inspectionId: widget.inspection.id!,
        deviceId: widget.device['id'],
        testResult: _testResult,
        sensitivity: _sensitivityController.text.isEmpty ? null : _sensitivityController.text,
        decibelLevel: _decibelController.text.isEmpty ? null : _decibelController.text,
        servicedDate: _servicedDate,
        hydroDate: _hydroDate,
        size: _sizeController.text.isEmpty ? null : _sizeController.text,
        check24hrPost: _deviceTypeName == 'Emergency Light' ? _check24hrPost : null,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        photoPath: _photoPath,
        videoPath: _videoPath,
      );
      
      if (widget.existingTest != null) {
        await _componentTestRepo.update(test);
      } else {
        await _componentTestRepo.insert(test);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.device['device_type_name']} test saved'),
          backgroundColor: _testResult == 'Pass' ? Colors.green : 
                          _testResult == 'Fail' ? Colors.red : Colors.orange,
        ),
      );
      
      Navigator.pop(context, true);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving test: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_deviceTypeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.qr_code, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Barcode: ${widget.device['barcode'] ?? 'None'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.device['location_description'] ?? 'No location',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                      if (widget.device['manufacturer_name'] != null ||
                          widget.device['model_number'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              [
                                widget.device['manufacturer_name'],
                                widget.device['model_number'],
                              ].where((s) => s != null).join(' - '),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Test result selector
              _buildTestResultSelector(),
              
              // Device-specific fields
              _buildDeviceSpecificFields(),
              
              const SizedBox(height: 20),
              
              // Documentation
              const Text('Documentation', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
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
                      onPressed: _takeVideo,
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
                  hintText: 'Any additional notes about this device',
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveTest,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Saving...' : 'Save Test',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}