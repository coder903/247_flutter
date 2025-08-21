// lib/screens/inspections/inspection_summary_screen.dart

import 'package:flutter/material.dart';
import '../../models/models.dart';

class InspectionSummaryScreen extends StatelessWidget {
  final Inspection inspection;
  final String propertyName;

  const InspectionSummaryScreen({
    super.key,
    required this.inspection,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Summary'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.summarize,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Inspection Summary Coming Soon!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              propertyName,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Complete inspection
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complete inspection - Coming soon')),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Inspection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}