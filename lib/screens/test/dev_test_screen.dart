// lib/screens/test/dev_test_screen.dart
// Add this screen temporarily for testing

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/sync_manager.dart';
import '../../repositories/repositories.dart';
import '../../config/app_config.dart';

class DevTestScreen extends StatefulWidget {
  const DevTestScreen({super.key});

  @override
  State<DevTestScreen> createState() => _DevTestScreenState();
}

class _DevTestScreenState extends State<DevTestScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;
  
  void _log(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('API URL: ${AppConfig.apiBaseUrl}'),
                const Text(
                  'All endpoints are under /inspection-api/',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      child: const Text('Test Connection'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testLogin,
                      child: const Text('Test Login'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _syncData,
                      child: const Text('Sync Data'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _checkData,
                      child: const Text('Check Local'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _logs.length,
              itemBuilder: (context, index) => Text(
                _logs[index],
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    _log('Testing connection...');
    
    try {
      final response = await ApiService.instance.get('/auth/login');
      _log('✅ Server reachable');
    } catch (e) {
      if (e.toString().contains('405')) {
        _log('✅ Server reachable (405 expected)');
      } else {
        _log('❌ Error: $e');
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _testLogin() async {
    setState(() => _isLoading = true);
    _log('Testing login as tech1@firetest.com...');
    
    try {
      final response = await ApiService.instance.login('tech1@firetest.com', 'password123');
      _log('✅ Login successful');
      _log('Token: ${response['access_token']?.substring(0, 20)}...');
    } catch (e) {
      _log('❌ Login failed: $e');
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _syncData() async {
    setState(() => _isLoading = true);
    _log('Starting sync...');
    
    try {
      // Get buildings
      _log('Fetching buildings...');
      final buildingResponse = await ApiService.instance.get('/buildings');
      final buildings = buildingResponse.data['buildings'] as List;
      _log('Found ${buildings.length} buildings');
      
      // Get customers
      _log('Fetching customers...');
      final customerResponse = await ApiService.instance.get('/customers');
      final customers = customerResponse.data['customers'] as List;
      _log('Found ${customers.length} customers');
      
      // Get systems
      _log('Fetching systems...');
      final systemResponse = await ApiService.instance.get('/systems');
      final systems = systemResponse.data['systems'] as List;
      _log('Found ${systems.length} systems');
      
      _log('✅ Sync completed');
    } catch (e) {
      _log('❌ Sync error: $e');
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _checkData() async {
    _log('Checking local database...');
    
    try {
      final buildings = await BuildingRepository().getAll();
      _log('Buildings: ${buildings.length}');
      
      final customers = await CustomerRepository().getAll();
      _log('Customers: ${customers.length}');
      
      final alarmPanels = await AlarmPanelRepository().getAll();
      _log('Systems: ${alarmPanels.length}');
      
      if (alarmPanels.isNotEmpty) {
        _log('First system: ${alarmPanels.first.name}');
      }
    } catch (e) {
      _log('❌ Error: $e');
    }
  }
}