// lib/screens/alarmPanels/building_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/building.dart';
import '../../repositories/building_repository.dart';

class BuildingListScreen extends StatefulWidget {
  const BuildingListScreen({super.key});

  @override
  State<BuildingListScreen> createState() => _BuildingListScreenState();
}

class _BuildingListScreenState extends State<BuildingListScreen> {
  final BuildingRepository _buildingRepo = BuildingRepository();
  List<Building> _buildings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    setState(() => _isLoading = true);
    try {
      final buildings = await _buildingRepo.getAll();
      setState(() {
        _buildings = buildings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading buildings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog([Building? building]) {
    final nameController = TextEditingController(text: building?.buildingName);
    final addressController = TextEditingController(text: building?.address);
    final cityController = TextEditingController(text: building?.city);
    final stateController = TextEditingController(text: building?.state);
    final zipController = TextEditingController(text: building?.zipCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(building == null ? 'Add Building' : 'Edit Building'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Building Name *',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: zipController,
                      decoration: const InputDecoration(
                        labelText: 'ZIP Code',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Building name is required')),
                );
                return;
              }
              
              try {
                final newBuilding = Building(
                  id: building?.id,
                  buildingName: nameController.text.trim(),
                  address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
                  city: cityController.text.trim().isNotEmpty ? cityController.text.trim() : null,
                  state: stateController.text.trim().isNotEmpty ? stateController.text.trim() : null,
                  zipCode: zipController.text.trim().isNotEmpty ? zipController.text.trim() : null,
                  createdAt: building?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                if (building == null) {
                  await _buildingRepo.insert(newBuilding);
                } else {
                  await _buildingRepo.update(newBuilding);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadBuildings();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving building: $e')),
                  );
                }
              }
            },
            child: Text(building == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buildings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No buildings found',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the + button to add your first building',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _buildings.length,
                  itemBuilder: (context, index) {
                    final building = _buildings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            building.buildingName?.substring(0, 1) ?? 'B',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          building.buildingName ?? 'Unnamed Building',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: building.address != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(building.address!),
                                  if (building.city != null || building.state != null || building.zipCode != null)
                                    Text(
                                      [
                                        building.city,
                                        building.state,
                                        building.zipCode,
                                      ].where((e) => e != null).join(', '),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAddEditDialog(building),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: 'Add Building',
        child: const Icon(Icons.add),
      ),
    );
  }
}