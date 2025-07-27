import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ip_info.dart';
import '../services/ip_check_service.dart';

/// Screen untuk checking IP address information
class IpCheckScreen extends StatefulWidget {
  const IpCheckScreen({super.key});

  @override
  State<IpCheckScreen> createState() => _IpCheckScreenState();
}

class _IpCheckScreenState extends State<IpCheckScreen> {
  final IpCheckService _ipService = IpCheckService();
  final TextEditingController _ipController = TextEditingController();
  IpInfo? _currentIpInfo;
  String? _currentPublicIp;
  Map<String, dynamic>? _pingResults;
  List<String>? _tracerouteResults;

  @override
  void initState() {
    super.initState();
    _getCurrentPublicIp();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentPublicIp() async {
    final publicIp = await _ipService.getCurrentPublicIp();
    if (publicIp != null) {
      setState(() {
        _currentPublicIp = publicIp;
      });
      _checkIp(publicIp);
    }
  }

  Future<void> _checkIp(String ipAddress) async {
    if (!_ipService.isValidIpAddress(ipAddress)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid IP address format')),
      );
      return;
    }

    final ipInfo = await _ipService.checkIpInfo(ipAddress);
    setState(() {
      _currentIpInfo = ipInfo;
      _pingResults = null;
      _tracerouteResults = null;
    });

    if (ipInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get IP information')),
      );
    }
  }

  Future<void> _performPing() async {
    if (_currentIpInfo == null) return;

    final results = await _ipService.pingIpAddress(_currentIpInfo!.ip);
    setState(() {
      _pingResults = results;
    });
  }

  Future<void> _performTraceroute() async {
    if (_currentIpInfo == null) return;

    final results = await _ipService.performTraceroute(_currentIpInfo!.ip);
    setState(() {
      _tracerouteResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
          ),
        ],
      ),
      body: ChangeNotifierProvider.value(
        value: _ipService,
        child: Consumer<IpCheckService>(
          builder: (context, service, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(),
                  const SizedBox(height: 20),
                  if (_currentPublicIp != null) _buildCurrentIpCard(),
                  const SizedBox(height: 20),
                  if (service.isLoading) _buildLoadingCard(),
                  if (_currentIpInfo != null && !service.isLoading) ...[
                    _buildIpInfoCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    if (_pingResults != null) _buildPingResults(),
                    if (_tracerouteResults != null) _buildTracerouteResults(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check IP Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      hintText: 'Enter IP address (e.g., 8.8.8.8)',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF9929EA)),
                    ),
                    onSubmitted: _checkIp,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _checkIp(_ipController.text.trim()),
                  child: const Text('Check'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentIpCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.public, color: Color(0xFF9929EA)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Public IP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _currentPublicIp!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9929EA),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _currentPublicIp!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('IP copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF9929EA)),
              SizedBox(height: 16),
              Text(
                'Checking IP information...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIpInfoCard() {
    final ipInfo = _currentIpInfo!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Color(0xFF9929EA)),
                const SizedBox(width: 8),
                const Text(
                  'IP Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (ipInfo.isSuspicious)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'SUSPICIOUS',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...ipInfo.allInfo.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        entry.value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ipInfo.securityFlags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ipInfo.securityFlags
                    .map(
                      (flag) => Chip(
                        label: Text(flag),
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        side: const BorderSide(color: Colors.red),
                        labelStyle: const TextStyle(color: Colors.red),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _performPing,
            icon: const Icon(Icons.network_ping),
            label: const Text('Ping'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _performTraceroute,
            icon: const Icon(Icons.route),
            label: const Text('Traceroute'),
          ),
        ),
      ],
    );
  }

  Widget _buildPingResults() {
    final results = _pingResults!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.network_ping, color: Color(0xFF9929EA)),
                SizedBox(width: 8),
                Text(
                  'Ping Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Packets: ${results['packets_sent']} sent, ${results['packets_received']} received, ${results['packets_lost']} lost (${results['packet_loss_percent']}% loss)',
              style: const TextStyle(color: Colors.white),
            ),
            if (results['average_time_ms'] > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Round-trip times: min=${results['min_time_ms']}ms, avg=${results['average_time_ms']}ms, max=${results['max_time_ms']}ms',
                style: const TextStyle(color: Colors.white),
              ),
            ],
            if (results['error'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${results['error']}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTracerouteResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.route, color: Color(0xFF9929EA)),
                SizedBox(width: 8),
                Text(
                  'Traceroute Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._tracerouteResults!.map(
              (hop) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  hop,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    // TODO: Implement history dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History feature coming soon')),
    );
  }
}
