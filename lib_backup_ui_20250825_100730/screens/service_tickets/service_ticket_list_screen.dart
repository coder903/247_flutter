// lib/screens/service_tickets/service_ticket_list_screen.dart
import 'package:flutter/material.dart';

class ServiceTicketListScreen extends StatelessWidget {
  const ServiceTicketListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Tickets'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Service Tickets',
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
                '• Create tickets from inspection findings\n'
                '• Track parts needed/ordered\n'
                '• Add troubleshooting notes\n'
                '• Link tickets to devices\n'
                '• Manage ticket status',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}