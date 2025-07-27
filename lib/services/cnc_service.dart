import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
  
  Stream<Map<String, dynamic>> get monitoringStream => _monitoringController.stream;

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
      final connectionFutures = servers.map((server) => _connectSingleVps(server));
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
          results['errors'].add('${server.name}: ${result['error'] ?? 'Unknown error'}');
        }
        
        results['details'][server.id] = result;
      }
      
      results['connectedCount'] = connectedCount;
      results['success'] = connectedCount > 0;
      
      // Step 6: Broadcast monitoring update
      _broadcastMonitoringUpdate();
      
      debugPrint('✅ Connect All VPS completed: $connectedCount/$servers.length connected');
      
    } catch (e) {
      debugPrint('❌ Connect All VPS failed: $e');
      results['errors'].add('Operation failed: $e');
    }
    
    return results;
  }

  /// Run scrape.js script to get user agents
  Future<void> _runScrapeScript() async {
    try {
      debugPrint('🔍 Running scrape.js script...');
      
      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final projectDir = Directory('${directory.path}/PABS-NETZILLA');
      
      // Check if scrape.js exists
      final scrapeFile = File('${projectDir.path}/scrape.js');
      if (!await scrapeFile.exists()) {
        // Create default scrape.js if not exists
        await _createDefaultScrapeScript(scrapeFile);
      }
      
      // Run node scrape.js
      final result = await Process.run(
        'node',
        ['scrape.js'],
        workingDirectory: projectDir.path,
      );
      
      if (result.exitCode == 0) {
        debugPrint('✅ scrape.js executed successfully');
        await _loadUserAgentList();
      } else {
        debugPrint('❌ scrape.js failed: ${result.stderr}');
        // Use default user agents if scrape fails
        _userAgentList.addAll(_getDefaultUserAgents());
      }
      
    } catch (e) {
      debugPrint('❌ Error running scrape.js: $e');
      // Fallback to default user agents
      _userAgentList.addAll(_getDefaultUserAgents());
    }
  }

  /// Load proxy list from proxy.txt
  Future<void> _loadProxyList() async {
    try {
      debugPrint('📋 Loading proxy list...');
      
      final directory = await getApplicationDocumentsDirectory();
      final projectDir = Directory('${directory.path}/PABS-NETZILLA');
      final proxyFile = File('${projectDir.path}/proxy.txt');
      
      if (await proxyFile.exists()) {
        final content = await proxyFile.readAsString();
        _proxyList.clear();
        _proxyList.addAll(
          content.split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
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
          result['userAgent'] = _userAgentList[
            DateTime.now().millisecond % _userAgentList.length
          ];
        }
        
        if (_proxyList.isNotEmpty) {
          result['proxy'] = _proxyList[
            DateTime.now().millisecond % _proxyList.length
          ];
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
      final directory = await getApplicationDocumentsDirectory();
      final projectDir = Directory('${directory.path}/PABS-NETZILLA');
      final uaFile = File('${projectDir.path}/user_agents.json');
      
      if (await uaFile.exists()) {
        final content = await uaFile.readAsString();
        final data = jsonDecode(content) as List;
        _userAgentList.clear();
        _userAgentList.addAll(data.cast<String>());
        debugPrint('✅ Loaded ${_userAgentList.length} user agents');
      }
    } catch (e) {
      debugPrint('❌ Error loading user agents: $e');
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
      'connectedVpsCount': _vpsConnectionStatus.values.where((status) => status).length,
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
      'connectedVpsCount': _vpsConnectionStatus.values.where((status) => status).length,
      'totalVpsCount': _vpsConnectionStatus.length,
      'proxyList': List<String>.from(_proxyList),
      'userAgentList': List<String>.from(_userAgentList),
    };
  }

  /// Create default scrape.js script
  Future<void> _createDefaultScrapeScript(File file) async {
    const script = '''
const fs = require('fs');
const https = require('https');

// Default user agents list
const defaultUserAgents = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/121.0',
  'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/121.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0'
];

// Save user agents to file
fs.writeFileSync('user_agents.json', JSON.stringify(defaultUserAgents, null, 2));
console.log('User agents saved successfully');
''';
    
    await file.parent.create(recursive: true);
    await file.writeAsString(script);
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
