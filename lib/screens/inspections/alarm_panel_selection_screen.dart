// lib/screens/inspections/alarm_panel_selection_screen.dart

import 'package:flutter/material.dart';
import '../../repositories/alarm_panel_repository.dart';
import '../../repositories/building_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../models/alarm_panel.dart';
import '../../config/constants.dart';
import 'inspection_start_screen.dart';

class AlarmPanelSelectionScreen extends StatefulWidget {
  const AlarmPanelSelectionScreen({super.key});

  @override
  State<AlarmPanelSelectionScreen> createState() => _AlarmPanelSelectionScreenState();
}

class _AlarmPanelSelectionScreenState extends State<AlarmPanelSelectionScreen> {
  final AlarmPanelRepository _alarmPanelRepo = AlarmPanelRepository();
  final BuildingRepository _buildingRepo = BuildingRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  
  List<Map<String, dynamic>> _alarmPanelsNeedingInspection = [];
  List<Map<String, dynamic>> _allProperties = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    
    try {
      print('DEBUG: Loading properties for inspection screen');
      
      // Get alarmPanels needing inspection
      final needingAnnual = await _alarmPanelRepo.getPropertiesNeedingInspection(
        inspectionType: 'Annual',
      );
      print('DEBUG: Found ${needingAnnual.length} properties needing annual inspection');
      
      final needingSemiAnnual = await _alarmPanelRepo.getPropertiesNeedingInspection(
        inspectionType: 'Semi-Annual',
      );
      print('DEBUG: Found ${needingSemiAnnual.length} properties needing semi-annual inspection');
      
      // Combine and deduplicate
      final Map<int, Map<String, dynamic>> needingInspectionMap = {};
      for (final prop in needingAnnual) {
        // Create a new mutable map from the read-only result
        needingInspectionMap[prop['id']] = Map<String, dynamic>.from(prop)
          ..['needs_type'] = 'Annual';
      }
      for (final prop in needingSemiAnnual) {
        final id = prop['id'] as int;
        if (needingInspectionMap.containsKey(id)) {
          needingInspectionMap[id]!['needs_type'] = 'Multiple';
        } else {
          needingInspectionMap[id] = Map<String, dynamic>.from(prop)
            ..['needs_type'] = 'Semi-Annual';
        }
      }
      
      _alarmPanelsNeedingInspection = needingInspectionMap.values.toList();
      print('DEBUG: Combined ${_alarmPanelsNeedingInspection.length} properties needing inspection');
      
      // Get all alarmPanels with details
      final allPropsReadOnly = await _alarmPanelRepo.getPropertiesWithDetails();
      print('DEBUG: Found ${allPropsReadOnly.length} total properties with details');
      
      // Convert to mutable maps and add device counts
      _allProperties = [];
      for (final prop in allPropsReadOnly) {
        // Create a mutable copy of the property map
        final mutableProp = Map<String, dynamic>.from(prop);
        final deviceCount = await _alarmPanelRepo.getDeviceCount(prop['id']);
        mutableProp['device_count'] = deviceCount;
        _allProperties.add(mutableProp);
      }
      
      print('DEBUG: Final properties count: ${_allProperties.length}');
      if (_allProperties.isNotEmpty) {
        print('DEBUG: First property: ${_allProperties.first}');
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading alarmPanels: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProperties {
    List<Map<String, dynamic>> alarmPanels;
    
    switch (_selectedFilter) {
      case 'Needs Inspection':
        alarmPanels = _alarmPanelsNeedingInspection;
        break;
      case 'All':
      default:
        alarmPanels = _allProperties;
    }
    
    if (_searchQuery.isEmpty) return alarmPanels;
    
    return alarmPanels.where((prop) {
      final name = (prop['name'] ?? '').toString().toLowerCase();
      final building = (prop['building_name'] ?? '').toString().toLowerCase();
      final customer = (prop['company_name'] ?? '').toString().toLowerCase();
      final account = (prop['account_number'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) ||
             building.contains(query) ||
             customer.contains(query) ||
             account.contains(query);
    }).toList();
  }

  bool _propertyNeedsInspection(Map<String, dynamic> property) {
    return _alarmPanelsNeedingInspection.any((p) => p['id'] == property['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select System'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search alarmPanels...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                      const PopupMenuItem(
                        value: 'All',
                        child: Text('All Properties'),
                      ),
                      PopupMenuItem(
                        value: 'Needs Inspection',
                        child: Row(
                          children: [
                            const Text('Needs Inspection'),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_alarmPanelsNeedingInspection.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list),
                          const SizedBox(width: 4),
                          Text(_selectedFilter),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProperties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No systems found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredProperties.length,
                    itemBuilder: (context, index) {
                      final property = _filteredProperties[index];
                      return _buildAlarmPanelCard(property);
                    },
                  ),
                ),
    );
  }

  Widget _buildAlarmPanelCard(Map<String, dynamic> property) {
    final needsInspection = _propertyNeedsInspection(property);
    final lastInspectionDate = property['last_inspection_date'] as String?;
    final daysSinceInspection = property['days_since_inspection'] as double?;
    final deviceCount = property['device_count'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectionStartScreen(
                alarmPanelId: property['id'],
                alarmPanelName: property['name'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property['name'] ?? 'Unknown AlarmPanel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (property['account_number'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Account: ${property['account_number']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (needsInspection) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _alarmPanelsNeedingInspection
                                .firstWhere((p) => p['id'] == property['id'])['needs_type'] ?? 'Inspection Due',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              
              // Building and Customer info
              if (property['building_name'] != null ||
                  property['company_name'] != null) ...[
                Row(
                  children: [
                    if (property['building_name'] != null) ...[
                      Icon(Icons.business, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property['building_name'],
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (property['company_name'] != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property['company_name'],
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              // Address
              if (property['building_address'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property['building_address'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Stats row
              Row(
                children: [
                  // Device count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.devices, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          '$deviceCount devices',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Last inspection
                  if (lastInspectionDate != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: needsInspection ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: needsInspection ? Colors.red[700] : Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            daysSinceInspection != null
                                ? '${daysSinceInspection.toInt()} days ago'
                                : 'Last inspection',
                            style: TextStyle(
                              fontSize: 12,
                              color: needsInspection ? Colors.red[700] : Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Never inspected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}