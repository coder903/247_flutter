// lib/screens/sync/sync_screen.dart
import 'package:flutter/material.dart';
import '../../services/sync_manager.dart';
import '../../database/database_helper.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({Key? key}) : super(key: key);
  
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _syncManager = SyncManager.instance;
  final _db = DatabaseHelper.instance;
  
  List<Map<String, dynamic>> _pendingItems = [];
  List<Map<String, dynamic>> _syncHistory = [];
  Map<String, dynamic> _syncStats = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSyncData();
  }
  
  Future<void> _loadSyncData() async {
    setState(() => _isLoading = true);
    
    try {
      final db = await _db.database;
      
      // Load pending sync items
      final pending = await db.query(
        'sync_queue',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at DESC',
      );
      
      // Load recent sync history
      final history = await db.query(
        'sync_queue',
        where: 'sync_status != ?',
        whereArgs: ['pending'],
        orderBy: 'last_sync_attempt DESC',
        limit: 50,
      );
      
      // Get sync statistics
      final stats = await _syncManager.getSyncStats();
      
      setState(() {
        _pendingItems = pending;
        _syncHistory = history;
        _syncStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sync data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSyncData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSyncStatusCard(),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Pending'),
                      Tab(text: 'History'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPendingTab(),
                        _buildHistoryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSyncStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<SyncStatus>(
              stream: _syncManager.syncStatusStream,
              initialData: _syncManager.currentStatus,
              builder: (context, statusSnapshot) {
                final status = statusSnapshot.data ?? SyncStatus.idle;
                
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sync Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _getStatusIcon(status),
                                const SizedBox(width: 8),
                                Text(
                                  _getStatusText(status),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: status == SyncStatus.syncing
                              ? null
                              : () async {
                                  await _syncManager.performSync();
                                  _loadSyncData();
                                },
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync Now'),
                        ),
                      ],
                    ),
                    if (status == SyncStatus.syncing)
                      StreamBuilder<SyncProgress>(
                        stream: _syncManager.syncProgressStream,
                        builder: (context, progressSnapshot) {
                          final progress = progressSnapshot.data;
                          if (progress == null) return const SizedBox();
                          
                          return Column(
                            children: [
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: progress.percentage,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${progress.completed} / ${progress.total} - ${progress.currentItem}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Pending', (_syncStats['pending'] ?? 0).toString()),
                _buildStatCard('Synced', (_syncStats['synced'] ?? 0).toString()),
                _buildStatCard('Failed', (_syncStats['failed'] ?? 0).toString()),
                _buildStatCard('Last Sync', _getLastSyncTime()),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
  
  Widget _buildPendingTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_pendingItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_done, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No pending items to sync'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingItems.length,
      itemBuilder: (context, index) {
        final item = _pendingItems[index];
        return Card(
          child: ListTile(
            leading: _getOperationIcon(item['operation_type'] as String),
            title: Text('${item['table_name']} - ${item['operation_type']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Created: ${_formatDateTime(item['created_at'] as String)}'),
                if ((item['sync_attempts'] as int? ?? 0) > 0)
                  Text(
                    'Attempts: ${item['sync_attempts']}',
                    style: const TextStyle(color: Colors.orange),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeSyncItem(item['id'] as int),
              tooltip: 'Remove from sync queue',
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_syncHistory.isEmpty) {
      return const Center(
        child: Text('No sync history available'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _syncHistory.length,
      itemBuilder: (context, index) {
        final item = _syncHistory[index];
        final status = item['sync_status'] as String;
        
        return Card(
          child: ListTile(
            leading: status == 'synced'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.error, color: Colors.red),
            title: Text('${item['table_name']} - ${item['operation_type']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Synced: ${_formatDateTime(item['last_sync_attempt'] as String?)}'),
                if (item['error_message'] != null)
                  Text(
                    'Error: ${item['error_message']}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _removeSyncItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Sync Item'),
        content: const Text('Are you sure you want to remove this item from the sync queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final db = await _db.database;
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
      _loadSyncData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from sync queue'),
          ),
        );
      }
    }
  }
  
  Widget _getOperationIcon(String operation) {
    switch (operation.toUpperCase()) {
      case 'CREATE':
        return const Icon(Icons.add_circle, color: Colors.green);
      case 'UPDATE':
        return const Icon(Icons.edit, color: Colors.blue);
      case 'DELETE':
        return const Icon(Icons.delete, color: Colors.red);
      case 'UPLOAD_PDF':
        return const Icon(Icons.upload_file, color: Colors.orange);
      default:
        return const Icon(Icons.sync);
    }
  }
  
  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.offline:
        return Colors.grey;
    }
  }
  
  Widget _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.error, color: Colors.red);
      case SyncStatus.offline:
        return const Icon(Icons.cloud_off, color: Colors.grey);
    }
  }
  
  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'All data synced';
      case SyncStatus.syncing:
        return 'Syncing in progress...';
      case SyncStatus.success:
        return 'Sync completed successfully';
      case SyncStatus.error:
        return 'Sync error occurred';
      case SyncStatus.offline:
        return 'Offline - waiting for connection';
    }
  }
  
  String _getLastSyncTime() {
    if (_syncHistory.isEmpty) return 'Never';
    
    final lastSync = _syncHistory.first['last_sync_attempt'] as String?;
    if (lastSync == null) return 'Never';
    
    final dateTime = DateTime.parse(lastSync);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';
    
    final dateTime = DateTime.parse(dateTimeStr);
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}