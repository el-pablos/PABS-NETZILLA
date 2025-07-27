import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/vps_server.dart';
import 'vps_server_service.dart';

/// Service untuk mengelola Command and Control (CNC) operations
class CncService {
  static final CncService _instance = CncService._internal();
  factory CncService() => _instance;
  CncService._internal();

  final VpsServerService _vpsService = VpsServerService();

  // Status monitoring
  final Map<String, bool> _vpsConnectionStatus = {};
  final Map<String, String> _vpsUserAgents = {};
  final List<String> _proxyList = [];
  final List<String> _userAgentList = [];

  // Stream controllers untuk monitoring
  final StreamController<Map<String, dynamic>> _monitoringController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get monitoringStream =>
      _monitoringController.stream;

  /// Connect to all VPS servers at once
  Future<Map<String, dynamic>> connectAllVps() async {
    debugPrint('🚀 Starting Connect All VPS operation...');

    final results = <String, dynamic>{
      'success': false,
      'connectedCount': 0,
      'totalCount': 0,
      'errors': <String>[],
      'details': <String, dynamic>{},
    };

    try {
      // Step 1: Run scrape.js to get user agents
      await _runScrapeScript();

      // Step 2: Load proxy list
      await _loadProxyList();

      // Step 3: Get all VPS servers
      final servers = _vpsService.servers;
      results['totalCount'] = servers.length;

      if (servers.isEmpty) {
        results['errors'].add('No VPS servers found');
        return results;
      }

      // Step 4: Connect to all VPS servers concurrently
      final connectionFutures = servers.map(
        (server) => _connectSingleVps(server),
      );
      final connectionResults = await Future.wait(connectionFutures);

      // Step 5: Process results
      int connectedCount = 0;
      for (int i = 0; i < servers.length; i++) {
        final server = servers[i];
        final result = connectionResults[i];

        _vpsConnectionStatus[server.id] = result['success'] ?? false;
        if (result['success'] == true) {
          connectedCount++;
          _vpsUserAgents[server.id] = result['userAgent'] ?? 'Unknown';
        } else {
          results['errors'].add(
            '${server.name}: ${result['error'] ?? 'Unknown error'}',
          );
        }

        results['details'][server.id] = result;
      }

      results['connectedCount'] = connectedCount;
      results['success'] = connectedCount > 0;

      // Step 6: Broadcast monitoring update
      _broadcastMonitoringUpdate();

      debugPrint(
        '✅ Connect All VPS completed: $connectedCount/$servers.length connected',
      );
    } catch (e) {
      debugPrint('❌ Connect All VPS failed: $e');
      results['errors'].add('Operation failed: $e');
    }

    return results;
  }

  /// Run scrape scripts to get proxies and user agents
  Future<void> _runScrapeScript() async {
    try {
      debugPrint('🔍 Running scrape scripts...');

      // Get current working directory (project root)
      final currentDir = Directory.current;

      // Run proxy scraper (scrape.js)
      debugPrint('📋 Running proxy scraper...');
      final proxyResult = await Process.run('node', [
        'scrape.js',
      ], workingDirectory: currentDir.path);

      if (proxyResult.exitCode == 0) {
        debugPrint('✅ Proxy scraper executed successfully');
        await _loadProxyList();
      } else {
        debugPrint('❌ Proxy scraper failed: ${proxyResult.stderr}');
        await _createDefaultProxyFile(File('${currentDir.path}/proxy.txt'));
      }

      // Run user agent scraper (scrape_useragents.js)
      debugPrint('🌐 Running user agent scraper...');
      final uaResult = await Process.run('node', [
        'scrape_useragents.js',
      ], workingDirectory: currentDir.path);

      if (uaResult.exitCode == 0) {
        debugPrint('✅ User agent scraper executed successfully');
        await _loadUserAgentList();
      } else {
        debugPrint('❌ User agent scraper failed: ${uaResult.stderr}');
        // Use default user agents if scrape fails
        _userAgentList.addAll(_getDefaultUserAgents());
      }
    } catch (e) {
      debugPrint('❌ Error running scrape scripts: $e');
      // Fallback to defaults
      _userAgentList.addAll(_getDefaultUserAgents());
      await _createDefaultProxyFile(
        File('${Directory.current.path}/proxy.txt'),
      );
    }
  }

  /// Load proxy list from proxy.txt
  Future<void> _loadProxyList() async {
    try {
      debugPrint('📋 Loading proxy list...');

      final currentDir = Directory.current;
      final proxyFile = File('${currentDir.path}/proxy.txt');

      if (await proxyFile.exists()) {
        final content = await proxyFile.readAsString();
        _proxyList.clear();
        _proxyList.addAll(
          content
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty && line.contains(':'))
              .toList(),
        );
        debugPrint('✅ Loaded ${_proxyList.length} proxies');
      } else {
        debugPrint('⚠️ proxy.txt not found, creating default...');
        await _createDefaultProxyFile(proxyFile);
      }
    } catch (e) {
      debugPrint('❌ Error loading proxy list: $e');
    }
  }

  /// Connect to single VPS server
  Future<Map<String, dynamic>> _connectSingleVps(VpsServer server) async {
    final result = <String, dynamic>{
      'success': false,
      'userAgent': '',
      'proxy': '',
      'error': '',
    };

    try {
      debugPrint('🔗 Connecting to VPS: ${server.name}');

      // Test connection
      final connectionInfo = await _vpsService.testConnection(server.id);

      if (connectionInfo.status == VpsConnectionStatus.connected) {
        // Assign random user agent and proxy
        if (_userAgentList.isNotEmpty) {
          result['userAgent'] =
              _userAgentList[DateTime.now().millisecond %
                  _userAgentList.length];
        }

        if (_proxyList.isNotEmpty) {
          result['proxy'] =
              _proxyList[DateTime.now().millisecond % _proxyList.length];
        }

        result['success'] = true;
        debugPrint('✅ Connected to VPS: ${server.name}');
      } else {
        result['error'] = connectionInfo.errorMessage ?? 'Connection failed';
        debugPrint('❌ Failed to connect to VPS: ${server.name}');
      }
    } catch (e) {
      result['error'] = e.toString();
      debugPrint('❌ Error connecting to VPS ${server.name}: $e');
    }

    return result;
  }

  /// Load user agent list from scraped data
  Future<void> _loadUserAgentList() async {
    try {
      final currentDir = Directory.current;
      final uaFile = File('${currentDir.path}/user_agents.json');

      if (await uaFile.exists()) {
        final content = await uaFile.readAsString();
        final data = jsonDecode(content) as List;
        _userAgentList.clear();
        _userAgentList.addAll(data.cast<String>());
        debugPrint('✅ Loaded ${_userAgentList.length} user agents');
      } else {
        debugPrint('⚠️ user_agents.json not found, using defaults...');
        _userAgentList.addAll(_getDefaultUserAgents());
      }
    } catch (e) {
      debugPrint('❌ Error loading user agents: $e');
      _userAgentList.addAll(_getDefaultUserAgents());
    }
  }

  /// Broadcast monitoring update
  void _broadcastMonitoringUpdate() {
    final monitoringData = {
      'timestamp': DateTime.now().toIso8601String(),
      'vpsStatus': Map<String, dynamic>.from(_vpsConnectionStatus),
      'userAgents': Map<String, dynamic>.from(_vpsUserAgents),
      'proxyCount': _proxyList.length,
      'userAgentCount': _userAgentList.length,
      'connectedVpsCount': _vpsConnectionStatus.values
          .where((status) => status)
          .length,
      'totalVpsCount': _vpsConnectionStatus.length,
    };

    _monitoringController.add(monitoringData);
  }

  /// Get monitoring data
  Map<String, dynamic> getMonitoringData() {
    return {
      'vpsStatus': Map<String, dynamic>.from(_vpsConnectionStatus),
      'userAgents': Map<String, dynamic>.from(_vpsUserAgents),
      'proxyCount': _proxyList.length,
      'userAgentCount': _userAgentList.length,
      'connectedVpsCount': _vpsConnectionStatus.values
          .where((status) => status)
          .length,
      'totalVpsCount': _vpsConnectionStatus.length,
      'proxyList': List<String>.from(_proxyList),
      'userAgentList': List<String>.from(_userAgentList),
    };
  }

  /// Create default proxy file
  Future<void> _createDefaultProxyFile(File file) async {
    const proxies = '''8.8.8.8:80
1.1.1.1:80
208.67.222.222:80
208.67.220.220:80
9.9.9.9:80''';

    await file.parent.create(recursive: true);
    await file.writeAsString(proxies);
    _proxyList.addAll(proxies.split('\n'));
  }

  /// Get default user agents
  List<String> _getDefaultUserAgents() {
    return [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/121.0',
    ];
  }

  /// Dispose resources
  void dispose() {
    _monitoringController.close();
  }
}
