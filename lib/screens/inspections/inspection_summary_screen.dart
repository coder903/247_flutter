// lib/screens/inspections/inspection_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../services/pdf_service.dart';
import '../properties/property_list_screen.dart';

class InspectionSummaryScreen extends StatefulWidget {
  final Inspection inspection;
  final String propertyName;

  const InspectionSummaryScreen({
    super.key,
    required this.inspection,
    required this.propertyName,
  });

  @override
  State<InspectionSummaryScreen> createState() => _InspectionSummaryScreenState();
}

class _InspectionSummaryScreenState extends State<InspectionSummaryScreen> {
  final InspectionRepository _inspectionRepo = InspectionRepository();
  final BatteryTestRepository _batteryRepo = BatteryTestRepository();
  final ComponentTestRepository _componentRepo = ComponentTestRepository();
  final DeviceRepository _deviceRepo = DeviceRepository();
  final _notesController = TextEditingController();
  final _defectsController = TextEditingController();
  
  List<BatteryTest> _batteryTests = [];
  List<Map<String, dynamic>> _componentTests = [];
  bool _isLoading = true;
  
  // Statistics
  int _batteryPassCount = 0;
  int _batteryFailCount = 0;
  int _batteryNotTestedCount = 0;
  int _componentPassCount = 0;
  int _componentFailCount = 0;
  int _componentNotTestedCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadInspectionData();
    _notesController.text = widget.inspection.notes ?? '';
    _defectsController.text = widget.inspection.defects ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _defectsController.dispose();
    super.dispose();
  }

  Future<void> _loadInspectionData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load battery tests
      _batteryTests = await _batteryRepo.getByInspection(widget.inspection.id!);
      
      // Calculate battery statistics
      _batteryPassCount = _batteryTests.where((t) => t.passed == true).length;
      _batteryFailCount = _batteryTests.where((t) => t.passed == false).length;
      _batteryNotTestedCount = _batteryTests.where((t) => t.passed == null).length;
      
      // Load component tests with device details
      final componentTests = await _componentRepo.getByInspection(widget.inspection.id!);
      _componentTests = [];
      
      for (final test in componentTests) {
        final device = await _deviceRepo.getWithDetails(test.deviceId);
        if (device != null) {
          _componentTests.add({
            'test': test,
            'device': device,
          });
        }
      }
      
      // Calculate component statistics
      _componentPassCount = componentTests.where((t) => t.testResult == 'Pass').length;
      _componentFailCount = componentTests.where((t) => t.testResult == 'Fail').length;
      _componentNotTestedCount = componentTests.where((t) => t.testResult == 'Not Tested').length;
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading inspection data: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pass':
        return Colors.green;
      case 'Fail':
        return Colors.red;
      case 'Not Tested':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(String title, int passCount, int failCount, int notTestedCount) {
    final total = passCount + failCount + notTestedCount;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Pass', passCount, Colors.green),
                _buildStatItem('Fail', failCount, Colors.red),
                _buildStatItem('Not Tested', notTestedCount, Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total > 0 ? passCount / total : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                failCount > 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: $total devices',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFailedItemsList() {
    final failedBatteries = _batteryTests.where((t) => t.passed == false).toList();
    final failedComponents = _componentTests.where((t) => t['test'].testResult == 'Fail').toList();
    
    if (failedBatteries.isEmpty && failedComponents.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No failed items',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Failed Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            
            // Failed batteries
            if (failedBatteries.isNotEmpty) ...[
              const Text(
                'Batteries:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...failedBatteries.map((battery) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.battery_alert, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${battery.position} - ${battery.ratedAmpHours}Ah '
                        '(Current: ${battery.currentReading}A, Required: ${battery.minRequired}A)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],
            
            // Failed components
            if (failedComponents.isNotEmpty) ...[
              const Text(
                'Components:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...failedComponents.map((item) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item['device']['barcode']} - ${item['device']['device_type_name']} '
                        '(${item['device']['location'] ?? 'No location'})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completeInspection() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Inspection?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to complete this inspection?'),
            const SizedBox(height: 16),
            Text('Battery Tests: $_batteryPassCount passed, $_batteryFailCount failed'),
            Text('Component Tests: $_componentPassCount passed, $_componentFailCount failed'),
            if (_batteryFailCount > 0 || _componentFailCount > 0)
              const Text(
                '\nWarning: This inspection has failed items!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: (_batteryFailCount > 0 || _componentFailCount > 0) 
                  ? Colors.red 
                  : Colors.green,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      // Update inspection
      final updatedInspection = widget.inspection.copyWith(
        completionDatetime: DateTime.now(),
        isComplete: true,
        status: 'Completed',
        overallResult: (_batteryFailCount == 0 && _componentFailCount == 0) ? 'Pass' : 'Fail',
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        defects: _defectsController.text.isEmpty ? null : _defectsController.text,
        batteryCount: _batteryTests.length,
        batteryPassed: _batteryPassCount,
        componentCount: _componentTests.length,
        componentPassed: _componentPassCount,
      );
      
      await _inspectionRepo.update(updatedInspection);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Inspection completed - ${updatedInspection.overallResult}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: updatedInspection.overallResult == 'Pass' ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Navigate back to property list
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PropertyListScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Error completing inspection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error completing inspection'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection Summary')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final overallResult = (_batteryFailCount == 0 && _componentFailCount == 0) ? 'Pass' : 'Fail';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Summary'),
        backgroundColor: overallResult == 'Pass' ? Colors.green : Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Property info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.propertyName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${widget.inspection.inspectionType}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Type: ${widget.inspection.inspectionType}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Overall result
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: overallResult == 'Pass' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    overallResult == 'Pass' ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overall Result: $overallResult',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistics
            _buildStatCard(
              'Battery Tests',
              _batteryPassCount,
              _batteryFailCount,
              _batteryNotTestedCount,
            ),
            
            const SizedBox(height: 8),
            
            _buildStatCard(
              'Component Tests',
              _componentPassCount,
              _componentFailCount,
              _componentNotTestedCount,
            ),
            
            const SizedBox(height: 16),
            
            // Failed items
            if (_batteryFailCount > 0 || _componentFailCount > 0)
              _buildFailedItemsList(),
            
            const SizedBox(height: 16),
            
            // Notes and defects
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'General Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add any general notes about the inspection...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Defects Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _defectsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'List any defects or issues found...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            ElevatedButton(
              onPressed: _completeInspection,
              style: ElevatedButton.styleFrom(
                backgroundColor: overallResult == 'Pass' ? Colors.green : Colors.red,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Complete Inspection',
                style: TextStyle(fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 8),
            
            OutlinedButton(
              onPressed: () {
                // TODO: Generate PDF report
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF generation coming soon')),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text('Generate PDF Report'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}