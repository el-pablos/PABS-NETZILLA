import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vps_server.dart';
import '../services/vps_server_service.dart';

/// Screen untuk mengelola VPS servers
class VpsManagementScreen extends StatefulWidget {
  const VpsManagementScreen({super.key});

  @override
  State<VpsManagementScreen> createState() => _VpsManagementScreenState();
}

class _VpsManagementScreenState extends State<VpsManagementScreen> {
  final VpsServerService _vpsService = VpsServerService();

  @override
  void initState() {
    super.initState();
    _vpsService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VPS Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _vpsService.loadVpsAndSetupCnc(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddServerDialog(),
          ),
        ],
      ),
      body: ChangeNotifierProvider.value(
        value: _vpsService,
        child: Consumer<VpsServerService>(
          builder: (context, service, child) {
            if (service.servers.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildStatsCard(service),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: service.servers.length,
                    itemBuilder: (context, index) {
                      final server = service.servers[index];
                      final connectionInfo = service.getConnectionInfo(
                        server.id,
                      );
                      return _buildServerCard(server, connectionInfo);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServerDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No VPS Servers',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first VPS server to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddServerDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add VPS Server'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(VpsServerService service) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF9929EA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9929EA).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Servers',
              service.servers.length.toString(),
              Icons.dns,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF9929EA).withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Active',
              service.activeServersCount.toString(),
              Icons.check_circle,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF9929EA).withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Connected',
              service.connectedServersCount.toString(),
              Icons.link,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF9929EA)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildServerCard(VpsServer server, VpsConnectionInfo? connectionInfo) {
    final isConnected = connectionInfo?.isConnected ?? false;
    final isConnecting = connectionInfo?.isConnecting ?? false;
    final hasError = connectionInfo?.hasError ?? false;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.circle;
    String statusText = 'Unknown';

    if (isConnecting) {
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
      statusText = 'Connecting...';
    } else if (isConnected) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Connected';
    } else if (hasError) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Error';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.circle;
      statusText = 'Disconnected';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        server.connectionString,
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnecting
                        ? null
                        : () => _vpsService.testConnection(server.id),
                    icon: isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link, size: 16),
                    label: Text(isConnecting ? 'Connecting...' : 'Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9929EA),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showEditServerDialog(server),
                  icon: const Icon(Icons.edit, color: Colors.white),
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(server),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            if (connectionInfo?.systemInfo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9929EA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...connectionInfo!.systemInfo!.entries.map(
                      (entry) => Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddServerDialog() {
    _showServerDialog();
  }

  void _showEditServerDialog(VpsServer server) {
    _showServerDialog(server: server);
  }

  void _showServerDialog({VpsServer? server}) {
    final isEdit = server != null;
    final nameController = TextEditingController(text: server?.name ?? '');
    final hostController = TextEditingController(text: server?.host ?? '');
    final portController = TextEditingController(
      text: server?.port.toString() ?? '22',
    );
    final usernameController = TextEditingController(
      text: server?.username ?? '',
    );
    final passwordController = TextEditingController(
      text: server?.password ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          isEdit ? 'Edit VPS Server' : 'Add VPS Server',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Server Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hostController,
                decoration: const InputDecoration(labelText: 'Host/IP Address'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final host = hostController.text.trim();
              final port = int.tryParse(portController.text.trim()) ?? 22;
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();

              if (name.isEmpty ||
                  host.isEmpty ||
                  username.isEmpty ||
                  password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              bool success;
              if (isEdit) {
                success = await _vpsService.updateServer(
                  server!.id,
                  name: name,
                  host: host,
                  port: port,
                  username: username,
                  password: password,
                );
              } else {
                success = await _vpsService.addServer(
                  name: name,
                  host: host,
                  port: port,
                  username: username,
                  password: password,
                );
              }

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit
                          ? 'Server updated successfully'
                          : 'Server added successfully',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit
                          ? 'Failed to update server'
                          : 'Failed to add server',
                    ),
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(VpsServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Delete Server',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${server.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _vpsService.deleteServer(server.id);
              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Server deleted successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete server')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
