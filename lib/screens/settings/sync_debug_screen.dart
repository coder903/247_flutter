// lib/screens/settings/sync_debug_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/sync_manager.dart';
import '../../config/app_config.dart';
import '../../repositories/building_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/alarm_panel_repository.dart';

class SyncDebugScreen extends StatefulWidget {
  const SyncDebugScreen({Key? key}) : super(key: key);

  @override
  State<SyncDebugScreen> createState() => _SyncDebugScreenState();
}

class _SyncDebugScreenState extends State<SyncDebugScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _log('Current API URL: ${AppConfig.apiUrl}');
    _log('Is Development: ${AppConfig.isDevelopment}');
    _log('Flask Server: ${AppConfig.flaskDevServerIp}:${AppConfig.flaskDevServerPort}');
  }
  
  void _log(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _logs.insert(0, '[$timestamp] $message');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Debug'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'API: ${AppConfig.apiUrl}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testRawConnection,
                    icon: const Icon(Icons.network_check),
                    label: const Text('Test Raw Connection'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testApiEndpoints,
                    icon: const Icon(Icons.api),
                    label: const Text('Test API Endpoints'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testAuth,
                    icon: const Icon(Icons.lock),
                    label: const Text('Test Authentication'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _performSync,
                    icon: const Icon(Icons.sync),
                    label: const Text('Perform Full Sync'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkLocalData,
                    icon: const Icon(Icons.storage),
                    label: const Text('Check Local Data'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _logs.clear()),
                    child: const Text('Clear Logs'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black12,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(
                  _logs[index],
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _testRawConnection() async {
    setState(() => _isLoading = true);
    _log('Testing raw connection to server...');
    
    try {
      // Test base URL without auth
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);
      
      final response = await dio.get('${AppConfig.apiUrl}/health');
      _log('✅ Server reachable: ${response.statusCode}');
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          _log('⚠️ Server reachable but /health endpoint not found (404)');
          _log('This is OK - Flask server is responding');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          _log('❌ Connection timeout - check IP address');
          _log('Is Flask running with: flask run --host=0.0.0.0 ?');
        } else {
          _log('❌ Connection error: ${e.message}');
        }
      } else {
        _log('❌ Error: $e');
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _testApiEndpoints() async {
    setState(() => _isLoading = true);
    
    final endpoints = [
      '/buildings',
      '/customers', 
      '/systems',
      '/auth/login',
    ];
    
    for (final endpoint in endpoints) {
      try {
        _log('Testing $endpoint...');
        final dio = Dio();
        final response = await dio.get('${AppConfig.apiUrl}$endpoint');
        _log('✅ $endpoint: ${response.statusCode}');
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 401) {
          _log('✅ $endpoint: 401 (auth required - working correctly)');
        } else if (e is DioException && e.response?.statusCode == 405) {
          _log('✅ $endpoint: 405 (method not allowed - endpoint exists)');
        } else {
          _log('❌ $endpoint: $e');
        }
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _testAuth() async {
    setState(() => _isLoading = true);
    _log('Testing authentication...');
    
    try {
      _log('Attempting login as tech1@firetest.com...');
      final response = await ApiService.instance.login(
        'tech1@firetest.com',
        'password123'
      );
      
      if (response['access_token'] != null) {
        _log('✅ Login successful');
        _log('Token received: ${response['access_token'].substring(0, 20)}...');
        
        // Test authenticated request
        _log('Testing authenticated request...');
        final buildingsResponse = await ApiService.instance.get('/buildings');
        _log('✅ Authenticated request successful');
        _log('Response: ${buildingsResponse.data}');
      }
    } catch (e) {
      _log('❌ Auth error: $e');
      if (e.toString().contains('401')) {
        _log('Check Flask user credentials');
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _performSync() async {
    setState(() => _isLoading = true);
    _log('Starting sync process...');
    
    try {
      final syncManager = SyncManager();
      
      // Listen to sync status
      syncManager.statusStream.listen((status) {
        _log('Sync status: $status');
      });
      
      await syncManager.syncNow();
      _log('✅ Sync completed');
      
      // Check what was synced
      await _checkLocalData();
    } catch (e) {
      _log('❌ Sync error: $e');
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _checkLocalData() async {
    _log('Checking local database...');
    
    try {
      final buildings = await BuildingRepository().getAll();
      _log('Buildings in DB: ${buildings.length}');
      if (buildings.isNotEmpty) {
        _log('  First: ${buildings.first.name}');
      }
      
      final customers = await CustomerRepository().getAll();
      _log('Customers in DB: ${customers.length}');
      if (customers.isNotEmpty) {
        _log('  First: ${customers.first.name}');
      }
      
      final alarmPanels = await AlarmPanelRepository().getAll();
      _log('Systems in DB: ${alarmPanels.length}');
      if (alarmPanels.isNotEmpty) {
        _log('  First: ${alarmPanels.first.name}');
      }
    } catch (e) {
      _log('❌ Database error: $e');
    }
  }
}