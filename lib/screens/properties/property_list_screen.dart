// lib/screens/properties/property_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../inspections/inspection_start_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProperties();
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
        
        _properties.add({
          'property': property,
          'building': building,
          'lastInspection': lastInspection,
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading properties: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToInspection(Map<String, dynamic> propertyData) {
    final property = propertyData['property'] as Property;
    final building = propertyData['building'] as Building?;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionStartScreen(
          propertyId: property.id!,
          propertyName: building?.buildingName ?? 'Property #${property.id}',
        ),
      ),
    ).then((_) => _loadProperties()); // Reload on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Property'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? const Center(
                  child: Text('No properties found'),
                )
              : ListView.builder(
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final data = _properties[index];
                    final property = data['property'] as Property;
                    final building = data['building'] as Building?;
                    final lastInspection = data['lastInspection'] as Inspection?;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            building?.buildingName?.substring(0, 1) ?? 'P',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          building?.buildingName ?? 'Property #${property.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (building != null) ...[
                              Text(building.address ?? 'No address'),
                              if (building.city != null && building.state != null)
                                Text('${building.city}, ${building.state}'),
                            ],
                            const SizedBox(height: 4),
                            if (lastInspection != null)
                              Text(
                                'Last inspection: ${_formatDate(lastInspection.inspectionDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              )
                            else
                              const Text(
                                'No previous inspections',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _navigateToInspection(data),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    if (difference < 365) return '${(difference / 30).floor()} months ago';
    return '${(difference / 365).floor()} years ago';
  }
}