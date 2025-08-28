// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/sync_status_widget.dart';
import '../../services/sync_manager.dart';

import '../sync/sync_screen.dart';
import '../alarm_panels/alarm_panel_list_screen.dart';
import '../inspections/alarm_panel_selection_screen.dart';
import '../devices/device_management_screen.dart';
import '../service_tickets/service_ticket_list_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger sync when home screen loads
    _performInitialSync();
  }
  
  Future<void> _performInitialSync() async {
    try {
      await SyncManager.instance.syncNow();
      print('Home screen initial sync completed');
    } catch (e) {
      print('Home screen sync error: $e');
      // App can still function in offline mode
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Inspection'),
        actions: const [
          SyncStatusWidget(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildActionCards(context),
      ),
    );
  }



  Widget _buildActionCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildActionCard(
              context,
              'Start Inspection',
              Icons.assignment_turned_in,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlarmPanelSelectionScreen(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'Fire Alarm Systems',
              Icons.home_work,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlarmPanelListScreen(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'Devices',
              Icons.devices,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceManagementScreen(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'Service Tickets',
              Icons.build_circle,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceTicketListScreen(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'Sync Data',
              Icons.sync,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SyncScreen(),
                ),
              ),
            ),
            _buildActionCard(
              context,
              'Settings',
              Icons.settings,
              Colors.grey,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}