// lib/screens/inspections/component_test_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import 'component_test_form_screen.dart';
import 'inspection_summary_screen.dart';

class ComponentTestListScreen extends StatefulWidget {
  final Inspection inspection;
  final String propertyName;

  const ComponentTestListScreen({
    super.key,
    required this.inspection,
    required this.propertyName,
  });

  @override
  State<ComponentTestListScreen> createState() => _ComponentTestListScreenState();
}

class _ComponentTestListScreenState extends State<ComponentTestListScreen> {
  final DeviceRepository _deviceRepo = DeviceRepository();
  final ComponentTestRepository _componentTestRepo = ComponentTestRepository();
  final ReferenceDataRepository _refDataRepo = ReferenceDataRepository();
  
  List<Map<String, dynamic>> _devices = [];
  Map<int, ComponentTest> _existingTests = {};
  Map<int, DeviceType> _deviceTypes = {};
  Map<int, DeviceCategory> _categories = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    
    try {
      // Load devices with details
      _devices = await _deviceRepo.getDevicesWithDetails(
        propertyId: widget.inspection.propertyId,
      );
      
      // Load existing tests for this inspection
      final tests = await _componentTestRepo.getByInspection(widget.inspection.id!);
      _existingTests = {for (var test in tests) test.deviceId: test};
      
      // Load device types and categories for display
      final types = await _refDataRepo.getDeviceTypes();
      _deviceTypes = {for (var type in types) type.id: type};
      
      final categories = await _refDataRepo.getCategories();
      _categories = {for (var cat in categories) cat.id: cat};
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading devices: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDevices {
    var devices = _devices;
    
    // Apply status filter
    switch (_selectedFilter) {
      case 'Tested':
        devices = devices.where((d) => _existingTests.containsKey(d['id'])).toList();
        break;
      case 'Not Tested':
        devices = devices.where((d) => !_existingTests.containsKey(d['id'])).toList();
        break;
      case 'Failed':
        devices = devices.where((d) {
          final test = _existingTests[d['id']];
          return test != null && test.testResult == 'Fail';
        }).toList();
        break;
    }
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      devices = devices.where((d) {
        final barcode = (d['barcode'] ?? '').toString().toLowerCase();
        final location = (d['location_description'] ?? '').toString().toLowerCase();
        final type = (d['device_type_name'] ?? '').toString().toLowerCase();
        final model = (d['model_number'] ?? '').toString().toLowerCase();
        
        return barcode.contains(query) ||
               location.contains(query) ||
               type.contains(query) ||
               model.contains(query);
      }).toList();
    }
    
    return devices;
  }

  Color _getStatusColor(Map<String, dynamic> device) {
    final test = _existingTests[device['id']];
    if (test == null) return Colors.grey;
    
    switch (test.testResult) {
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

  String _getStatusText(Map<String, dynamic> device) {
    final test = _existingTests[device['id']];
    if (test == null) return 'Not Tested';
    return test.testResult ?? 'Not Tested';
  }

  IconData _getDeviceIcon(String? categoryName) {
    switch (categoryName) {
      case 'Initiating':
        return Icons.sensors;
      case 'Indicating':
      case 'Alarm':
        return Icons.campaign;
      case 'Fire':
        return Icons.fire_extinguisher;
      case 'Lighting':
        return Icons.light;
      case 'Control':
        return Icons.settings_remote;
      case 'Monitor':
        return Icons.monitor;
      case 'Safety':
        return Icons.health_and_safety;
      default:
        return Icons.devices_other;
    }
  }

  Future<void> _navigateToTest(Map<String, dynamic> device) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentTestFormScreen(
          inspection: widget.inspection,
          device: device,
          existingTest: _existingTests[device['id']],
        ),
      ),
    );
    
    if (result == true) {
      await _loadDevices();
    }
  }

  void _navigateToSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionSummaryScreen(
          inspection: widget.inspection,
          propertyName: widget.propertyName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final testedCount = _existingTests.length;
    final totalCount = _devices.length;
    final failedCount = _existingTests.values.where((t) => t.testResult == 'Fail').length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Tests'),
        actions: [
          if (testedCount > 0)
            TextButton.icon(
              onPressed: _navigateToSummary,
              icon: const Icon(Icons.summarize, color: Colors.white),
              label: const Text('Summary', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Property info and stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.propertyName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      'Total',
                      totalCount.toString(),
                      Colors.blue,
                    ),
                    _buildStatChip(
                      'Tested',
                      '$testedCount',
                      Colors.orange,
                    ),
                    _buildStatChip(
                      'Passed',
                      '${testedCount - failedCount}',
                      Colors.green,
                    ),
                    _buildStatChip(
                      'Failed',
                      failedCount.toString(),
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search devices...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  initialValue: _selectedFilter,
                  onSelected: (value) {
                    setState(() => _selectedFilter = value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'All', child: Text('All Devices')),
                    const PopupMenuItem(value: 'Not Tested', child: Text('Not Tested')),
                    const PopupMenuItem(value: 'Tested', child: Text('Tested')),
                    const PopupMenuItem(value: 'Failed', child: Text('Failed Only')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 20),
                        const SizedBox(width: 4),
                        Text(_selectedFilter, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Device list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No devices match your search'
                                  : 'No devices to test',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredDevices.length,
                        itemBuilder: (context, index) {
                          final device = _filteredDevices[index];
                          return _buildDeviceCard(device);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final statusColor = _getStatusColor(device);
    final statusText = _getStatusText(device);
    final test = _existingTests[device['id']];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _navigateToTest(device),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Device icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDeviceIcon(device['category_name']),
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              
              // Device details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device['device_type_name'] ?? 'Unknown Device',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (device['barcode'] != null) ...[
                          Icon(Icons.qr_code, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            device['barcode'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device['location_description'] ?? 'No location specified',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (device['manufacturer_name'] != null ||
                        device['model_number'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          device['manufacturer_name'],
                          device['model_number'],
                        ].where((s) => s != null).join(' - '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (test != null && test.notes != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.note, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              test.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status indicator
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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