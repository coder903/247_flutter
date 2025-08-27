// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/sync_manager.dart';
import '../../widgets/sync_status_widget.dart';
import '../../repositories/inspection_repository.dart';
import '../../repositories/property_repository.dart';
import '../../repositories/service_ticket_repository.dart';
import '../sync/sync_screen.dart';
import '../properties/property_list_screen.dart';
import '../inspections/property_selection_screen.dart';
import '../devices/device_management_screen.dart';
import '../service_tickets/service_ticket_list_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InspectionRepository _inspectionRepo = InspectionRepository();
  final PropertyRepository _propertyRepo = PropertyRepository();
  final ServiceTicketRepository _ticketRepo = ServiceTicketRepository();
  
  Map<String, int> _stats = {
    'pendingInspections': 0,
    'completedToday': 0,
    'openTickets': 0,
    'totalProperties': 0,
  };
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get pending inspections
      final pendingInspections = await _inspectionRepo.getIncomplete();
      
      // Get today's completed inspections
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final todayInspections = await _inspectionRepo.getInspectionsWithDetails(
        isComplete: true,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      // Get open tickets
      final openTickets = await _ticketRepo.getByStatus('Open');
      
      // Get total properties
      final totalProperties = await _propertyRepo.getAll().then((list) => list.length);

      setState(() {
        _stats = {
          'pendingInspections': pendingInspections.length,
          'completedToday': todayInspections.length,
          'openTickets': openTickets.length,
          'totalProperties': totalProperties,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
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
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(context),
                    const SizedBox(height: 24),
                    _buildActionCards(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Pending',
              _stats['pendingInspections'].toString(),
              Icons.hourglass_empty,
              Colors.orange,
            ),
            _buildStatCard(
              'Completed Today',
              _stats['completedToday'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Open Tickets',
              _stats['openTickets'].toString(),
              Icons.build,
              Colors.blue,
            ),
            _buildStatCard(
              'Fire Alarm Systems',
              _stats['totalProperties'].toString(),
              Icons.business,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                  builder: (context) => const PropertySelectionScreen(),
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
                  builder: (context) => const PropertyListScreen(),
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