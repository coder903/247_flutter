// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../inspections/property_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Inspection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              // TODO: Implement sync
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync not yet implemented')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildModeCard(
            context,
            'Site Survey',
            Icons.search,
            Colors.blue,
            () {
              // TODO: Navigate to Site Survey
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Site Survey - Coming Soon')),
              );
            },
          ),
          _buildModeCard(
            context,
            'Inspection',
            Icons.checklist,
            Colors.green,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertySelectionScreen(),
                ),
              );
            },
          ),
          _buildModeCard(
            context,
            'Service Tickets',
            Icons.build,
            Colors.orange,
            () {
              // TODO: Navigate to Service Tickets
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Service Tickets - Coming Soon')),
              );
            },
          ),
          _buildModeCard(
            context,
            'Reports',
            Icons.description,
            Colors.purple,
            () {
              // TODO: Navigate to Reports
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reports - Coming Soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}