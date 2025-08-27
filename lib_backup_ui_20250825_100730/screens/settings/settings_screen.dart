// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _offlineMode = AppConfig.enableOfflineMode;
  bool _autoSync = true;
  String _syncInterval = '5 minutes';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _offlineMode = prefs.getBool('offline_mode') ?? AppConfig.enableOfflineMode;
      _autoSync = prefs.getBool('auto_sync') ?? true;
      _syncInterval = prefs.getString('sync_interval') ?? '5 minutes';
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', _offlineMode);
    await prefs.setBool('auto_sync', _autoSync);
    await prefs.setString('sync_interval', _syncInterval);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'General',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Offline Mode'),
            subtitle: const Text('Work without internet connection'),
            value: _offlineMode,
            onChanged: (value) {
              setState(() {
                _offlineMode = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          
          const ListTile(
            title: Text(
              'Sync Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Auto Sync'),
            subtitle: const Text('Automatically sync when online'),
            value: _autoSync,
            onChanged: (value) {
              setState(() {
                _autoSync = value;
              });
              _saveSettings();
            },
          ),
          ListTile(
            title: const Text('Sync Interval'),
            subtitle: Text(_syncInterval),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showSyncIntervalDialog(),
          ),
          const Divider(),
          
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            trailing: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('API URL'),
            subtitle: Text(AppConfig.apiUrl),
          ),
          const Divider(),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _clearCache,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Clear Cache'),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSyncIntervalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('5 minutes'),
              value: '5 minutes',
              groupValue: _syncInterval,
              onChanged: (value) {
                setState(() {
                  _syncInterval = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('15 minutes'),
              value: '15 minutes',
              groupValue: _syncInterval,
              onChanged: (value) {
                setState(() {
                  _syncInterval = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('30 minutes'),
              value: '30 minutes',
              groupValue: _syncInterval,
              onChanged: (value) {
                setState(() {
                  _syncInterval = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('1 hour'),
              value: '1 hour',
              groupValue: _syncInterval,
              onChanged: (value) {
                setState(() {
                  _syncInterval = value!;
                });
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear cache logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}