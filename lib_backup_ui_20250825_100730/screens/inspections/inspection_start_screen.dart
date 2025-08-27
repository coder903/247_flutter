// lib/screens/inspections/inspection_start_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/property_repository.dart';
import '../../repositories/inspection_repository.dart';
import '../../models/property.dart';
import '../../models/inspection.dart';
import '../../services/auth_service.dart';
import '../../config/constants.dart';
import 'battery_test_screen.dart';

class InspectionStartScreen extends StatefulWidget {
  final int propertyId;
  final String propertyName;

  const InspectionStartScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<InspectionStartScreen> createState() => _InspectionStartScreenState();
}

class _InspectionStartScreenState extends State<InspectionStartScreen> {
  final PropertyRepository _propertyRepo = PropertyRepository();
  final InspectionRepository _inspectionRepo = InspectionRepository();
  
  final _temperatureController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  Property? _property;
  Map<String, dynamic>? _propertyDetails;
  Map<String, dynamic>? _lastInspectionStats;
  bool _isLoading = true;
  String _selectedInspectionType = 'Annual';
  
  @override
  void initState() {
    super.initState();
    _loadPropertyDetails();
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    super.dispose();
  }

  Future<void> _loadPropertyDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // Load property details
      _property = await _propertyRepo.getById(widget.propertyId);
      _propertyDetails = await _propertyRepo.getPropertyWithRelatedData(widget.propertyId);
      
      // Get last inspection stats
      final lastInspection = await _inspectionRepo.getLatestForProperty(widget.propertyId);
      if (lastInspection != null) {
        _lastInspectionStats = await _inspectionRepo.getInspectionStats(lastInspection.id!);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading property: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startInspection() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final inspectorName = authService.userName ?? 'Unknown Inspector';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Parse temperature
      final temperature = double.tryParse(_temperatureController.text);
      
      // Create new inspection
      final inspection = await _inspectionRepo.startInspection(
        propertyId: widget.propertyId,
        inspectorName: inspectorName,
        inspectorUserId: int.tryParse(authService.userId ?? ''),
        inspectionType: _selectedInspectionType,
        panelTemperatureF: temperature,
      );
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Navigate to battery test screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BatteryTestScreen(
            inspection: inspection,
            propertyName: widget.propertyName,
          ),
        ),
      );
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting inspection: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Inspection'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.propertyName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (_property?.accountNumber != null) ...[
                              _buildInfoRow(
                                Icons.tag,
                                'Account',
                                _property!.accountNumber!,
                              ),
                            ],
                            
                            if (_propertyDetails?['building_name'] != null) ...[
                              _buildInfoRow(
                                Icons.business,
                                'Building',
                                _propertyDetails!['building_name'],
                              ),
                            ],
                            
                            if (_propertyDetails?['building_address'] != null) ...[
                              _buildInfoRow(
                                Icons.location_on,
                                'Address',
                                _propertyDetails!['building_address'],
                              ),
                            ],
                            
                            if (_property?.panelDescription != 'Unknown Panel') ...[
                              _buildInfoRow(
                                Icons.electrical_services,
                                'Panel',
                                _property!.panelDescription,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Last inspection info
                    if (_lastInspectionStats != null) ...[
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.history, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Last Inspection Results',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn(
                                    'Batteries',
                                    '${_lastInspectionStats!['battery_passed'] ?? 0}/${_lastInspectionStats!['battery_count'] ?? 0}',
                                    'passed',
                                  ),
                                  _buildStatColumn(
                                    'Devices',
                                    '${_lastInspectionStats!['component_passed'] ?? 0}/${_lastInspectionStats!['component_count'] ?? 0}',
                                    'passed',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Inspection type selection
                    Text(
                      'Inspection Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedInspectionType,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.checklist),
                      ),
                      items: AppConstants.inspectionTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedInspectionType = value);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Temperature reading
                    Text(
                      'Panel Temperature',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _temperatureController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Enter temperature reading',
                        prefixIcon: Icon(Icons.thermostat),
                        suffixText: '°F',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter panel temperature';
                        }
                        final temp = double.tryParse(value);
                        if (temp == null) {
                          return 'Please enter a valid number';
                        }
                        if (temp < 32 || temp > 150) {
                          return 'Temperature seems unusual (32-150°F expected)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_temperatureController.text.isNotEmpty) ...[
                      _buildTemperatureWarning(),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _startInspection,
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text(
                          'Start Inspection',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Take temperature reading immediately after opening panel. '
                              'High temperatures (>95°F) may indicate ventilation issues affecting battery life.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String sublabel) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureWarning() {
    final temp = double.tryParse(_temperatureController.text);
    if (temp == null) return const SizedBox.shrink();
    
    if (temp > 95) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, size: 16, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'High temperature detected. Check ventilation and note in defects.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}