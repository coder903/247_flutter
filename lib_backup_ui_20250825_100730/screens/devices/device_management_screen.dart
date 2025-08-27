// lib/screens/devices/device_management_screen.dart
import 'package:flutter/material.dart';

class DeviceManagementScreen extends StatelessWidget {
  const DeviceManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Management'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Device Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This feature will allow you to:\n'
                '• Add new devices to properties\n'
                '• Scan/generate barcodes\n'
                '• Bulk device entry\n'
                '• Edit device information\n'
                '• Mark devices for replacement',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}