// lib/screens/properties/property_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../inspections/inspection_start_screen.dart';
import 'property_add_edit_screen.dart';
import 'building_list_screen.dart';
import 'customer_list_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final PropertyRepository _propertyRepo = PropertyRepository();
  final BuildingRepository _buildingRepo = BuildingRepository();
  final InspectionRepository _inspectionRepo = InspectionRepository();
  
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;
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
      // Get all properties
      final properties = await _propertyRepo.getAll();
      _properties = [];
      
      // Get building info and last inspection for each property
      for (final property in properties) {
        // Get building details
        Building? building;
        if (property.buildingId != null) {
          building = await _buildingRepo.getById(property.buildingId!);
        }
        
        // Get last inspection
        final inspections = await _inspectionRepo.getByProperty(property.id!);
        final lastInspection = inspections.isNotEmpty ? inspections.first : null;
        
        // Get device count
        final deviceCount = await _propertyRepo.getDeviceCount(property.id!);
        
        _properties.add({
          'property': property,
          'building': building,
          'lastInspection': lastInspection,
          'deviceCount': deviceCount,
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading properties: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProperties {
    if (_searchQuery.isEmpty) return _properties;
    
    return _properties.where((data) {
      final property = data['property'] as Property;
      final building = data['building'] as Building?;
      
      final propertyName = property.name.toLowerCase();
      final buildingName = (building?.buildingName ?? '').toLowerCase();
      final accountNumber = (property.accountNumber ?? '').toLowerCase();
      final address = (building?.address ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return propertyName.contains(query) ||
             buildingName.contains(query) ||
             accountNumber.contains(query) ||
             address.contains(query);
    }).toList();
  }

  void _navigateToInspection(Map<String, dynamic> propertyData) {
    final property = propertyData['property'] as Property;
    final building = propertyData['building'] as Building?;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionStartScreen(
          propertyId: property.id!,
          propertyName: building?.buildingName ?? property.name,
        ),
      ),
    ).then((_) => _loadProperties()); // Reload on return
  }

  void _navigateToAddProperty() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PropertyAddEditScreen(),
      ),
    );
    
    if (result == true) {
      _loadProperties();
    }
  }

  void _navigateToEditProperty(Property property) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyAddEditScreen(property: property),
      ),
    );
    
    if (result == true) {
      _loadProperties();
    }
  }

  void _showPropertyOptions(Map<String, dynamic> propertyData) {
    final property = propertyData['property'] as Property;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Start Inspection'),
              onTap: () {
                Navigator.pop(context);
                _navigateToInspection(propertyData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit System'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditProperty(property);
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('View Devices'),
              subtitle: Text('${propertyData['deviceCount']} devices'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to device list for this property
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device management coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Service Tickets'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to service tickets for this property
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service tickets coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showManagementMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Management Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Manage Buildings'),
              subtitle: const Text('Add or edit building information'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuildingListScreen(),
                  ),
                ).then((_) => _loadProperties());
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Customers'),
              subtitle: const Text('Add or edit customer information'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerListScreen(),
                  ),
                ).then((_) => _loadProperties());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProperties = _filteredProperties;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Alarm Systems'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showManagementMenu,
            tooltip: 'Management Options',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search systems...',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.background,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Property List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProperties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_work_outlined,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'No systems found' 
                                  : 'No systems match your search',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first system',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredProperties.length,
                        itemBuilder: (context, index) {
                          final data = filteredProperties[index];
                          final property = data['property'] as Property;
                          final building = data['building'] as Building?;
                          final lastInspection = data['lastInspection'] as Inspection?;
                          final deviceCount = data['deviceCount'] as int;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  building?.buildingName?.substring(0, 1) ?? 
                                  property.name.substring(0, 1),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                building?.buildingName ?? property.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (building != null && building.address != null)
                                    Text(
                                      building.address!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (property.accountNumber != null)
                                    Text(
                                      'Account: ${property.accountNumber}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.devices,
                                        size: 16,
                                        color: Theme.of(context).disabledColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$deviceCount devices',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).disabledColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (lastInspection != null) ...[
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Theme.of(context).disabledColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Last: ${_formatDate(lastInspection.inspectionDate ?? lastInspection.createdAt ?? DateTime.now())}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).disabledColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _navigateToInspection(data),
                              onLongPress: () => _showPropertyOptions(data),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProperty,
        tooltip: 'Add System',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    if (difference < 365) return '${(difference / 30).floor()} months ago';
    
    return '${date.month}/${date.day}/${date.year}';
  }
}