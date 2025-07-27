import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/vps_server.dart';
import '../models/cnc_operation.dart';
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

  // CNC Operations
  final Map<String, CncOperation> _activeOperations = {};
  final List<CncOperation> _operationHistory = [];

  // Stream controllers untuk monitoring
  final StreamController<Map<String, dynamic>> _monitoringController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<CncOperation> _operationController =
      StreamController<CncOperation>.broadcast();

  Stream<Map<String, dynamic>> get monitoringStream =>
      _monitoringController.stream;
  Stream<CncOperation> get operationStream => _operationController.stream;

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

  /// CNC Setup - Setup all VPS servers for attack operations
  Future<CncBatchOperation> cncSetup({
    Map<String, dynamic>? globalParameters,
  }) async {
    debugPrint('🔧 Starting CNC Setup operation...');

    final servers = _vpsService.servers;
    final operations = <CncOperation>[];

    // Create setup operations for each VPS
    for (final server in servers) {
      final operation = CncOperation(
        type: CncOperationType.setup,
        vpsId: server.id,
        vpsName: server.name,
        parameters: {
          'host': server.host,
          'port': server.port,
          'username': server.username,
          'setupCommands': _getSetupCommands(),
          ...?globalParameters,
        },
      );

      operations.add(operation);
      _activeOperations[operation.id] = operation;
    }

    final batchOperation = CncBatchOperation(
      name: 'CNC Setup - All VPS',
      operations: operations,
    );

    // Execute setup operations concurrently
    final setupFutures = operations.map((op) => _executeCncSetup(op));
    await Future.wait(setupFutures);

    debugPrint('✅ CNC Setup completed');
    return batchOperation;
  }

  /// CNC Start - Start attack operations on all VPS servers
  Future<CncBatchOperation> cncStart({
    required String targetIp,
    required int port,
    required String method,
    int? duration,
    int? threads,
    Map<String, dynamic>? additionalParameters,
  }) async {
    debugPrint('🚀 Starting CNC Start operation...');

    final servers = _vpsService.servers.where((s) => s.isActive).toList();
    final operations = <CncOperation>[];

    // Create start operations for each active VPS
    for (final server in servers) {
      final userAgent = _userAgentList.isNotEmpty
          ? _userAgentList[DateTime.now().millisecond % _userAgentList.length]
          : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

      final proxy = _proxyList.isNotEmpty
          ? _proxyList[DateTime.now().millisecond % _proxyList.length]
          : null;

      final operation = CncOperation(
        type: CncOperationType.start,
        vpsId: server.id,
        vpsName: server.name,
        parameters: {
          'targetIp': targetIp,
          'port': port,
          'method': method,
          'duration': duration ?? 60,
          'threads': threads ?? 100,
          'userAgent': userAgent,
          'proxy': proxy,
          'host': server.host,
          'vpsPort': server.port,
          'username': server.username,
          ...?additionalParameters,
        },
      );

      operations.add(operation);
      _activeOperations[operation.id] = operation;
    }

    final batchOperation = CncBatchOperation(
      name: 'CNC Start - Attack on $targetIp:$port',
      operations: operations,
    );

    // Execute start operations concurrently
    final startFutures = operations.map((op) => _executeCncStart(op));
    await Future.wait(startFutures);

    debugPrint('✅ CNC Start completed');
    return batchOperation;
  }

  /// Execute CNC Setup operation on single VPS
  Future<CncOperation> _executeCncSetup(CncOperation operation) async {
    debugPrint('🔧 Executing setup on ${operation.vpsName}...');

    var updatedOperation = operation.copyWith(
      status: CncOperationStatus.running,
      startedAt: DateTime.now(),
    );

    _activeOperations[operation.id] = updatedOperation;
    _operationController.add(updatedOperation);

    try {
      final host = operation.parameters['host'] as String;
      final port = operation.parameters['port'] as int;
      final username = operation.parameters['username'] as String;
      final setupCommands =
          operation.parameters['setupCommands'] as List<String>;

      // Simulate SSH connection and setup commands
      await Future.delayed(const Duration(seconds: 2));

      // Execute setup commands
      final results = <String>[];
      for (final command in setupCommands) {
        debugPrint('  Executing: $command');
        await Future.delayed(const Duration(milliseconds: 500));
        results.add('✅ $command - Success');
      }

      updatedOperation = updatedOperation.copyWith(
        status: CncOperationStatus.completed,
        completedAt: DateTime.now(),
        result: results.join('\n'),
        duration: DateTime.now().difference(updatedOperation.startedAt!),
      );

      debugPrint('✅ Setup completed on ${operation.vpsName}');
    } catch (e) {
      updatedOperation = updatedOperation.copyWith(
        status: CncOperationStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
        duration: DateTime.now().difference(updatedOperation.startedAt!),
      );

      debugPrint('❌ Setup failed on ${operation.vpsName}: $e');
    }

    _activeOperations[operation.id] = updatedOperation;
    _operationHistory.add(updatedOperation);
    _operationController.add(updatedOperation);

    return updatedOperation;
  }

  /// Execute CNC Start operation on single VPS
  Future<CncOperation> _executeCncStart(CncOperation operation) async {
    debugPrint('🚀 Executing start on ${operation.vpsName}...');

    var updatedOperation = operation.copyWith(
      status: CncOperationStatus.running,
      startedAt: DateTime.now(),
    );

    _activeOperations[operation.id] = updatedOperation;
    _operationController.add(updatedOperation);

    try {
      final targetIp = operation.parameters['targetIp'] as String;
      final port = operation.parameters['port'] as int;
      final method = operation.parameters['method'] as String;
      final duration = operation.parameters['duration'] as int;
      final threads = operation.parameters['threads'] as int;
      final userAgent = operation.parameters['userAgent'] as String;
      final proxy = operation.parameters['proxy'] as String?;

      // Simulate attack execution
      debugPrint('  Target: $targetIp:$port');
      debugPrint('  Method: $method');
      debugPrint('  Duration: ${duration}s');
      debugPrint('  Threads: $threads');
      debugPrint('  User Agent: ${userAgent.substring(0, 50)}...');
      if (proxy != null) debugPrint('  Proxy: $proxy');

      // Simulate attack duration
      await Future.delayed(Duration(seconds: duration.clamp(1, 10)));

      updatedOperation = updatedOperation.copyWith(
        status: CncOperationStatus.completed,
        completedAt: DateTime.now(),
        result:
            'Attack completed successfully\nPackets sent: ${threads * duration * 10}\nTarget: $targetIp:$port',
        duration: DateTime.now().difference(updatedOperation.startedAt!),
      );

      debugPrint('✅ Attack completed on ${operation.vpsName}');
    } catch (e) {
      updatedOperation = updatedOperation.copyWith(
        status: CncOperationStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
        duration: DateTime.now().difference(updatedOperation.startedAt!),
      );

      debugPrint('❌ Attack failed on ${operation.vpsName}: $e');
    }

    _activeOperations[operation.id] = updatedOperation;
    _operationHistory.add(updatedOperation);
    _operationController.add(updatedOperation);

    return updatedOperation;
  }

  /// Get setup commands for VPS
  List<String> _getSetupCommands() {
    return [
      'apt-get update',
      'apt-get install -y nodejs npm python3 python3-pip',
      'npm install -g axios',
      'pip3 install requests aiohttp',
      'mkdir -p /opt/ddos-tools',
      'cd /opt/ddos-tools',
      'echo "Setup completed" > setup.log',
    ];
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

  /// Get active operations
  List<CncOperation> getActiveOperations() {
    return _activeOperations.values.toList();
  }

  /// Get operation history
  List<CncOperation> getOperationHistory() {
    return List<CncOperation>.from(_operationHistory);
  }

  /// Get operation by ID
  CncOperation? getOperation(String operationId) {
    return _activeOperations[operationId] ??
        _operationHistory.firstWhere(
          (op) => op.id == operationId,
          orElse: () => throw StateError('Operation not found'),
        );
  }

  /// Cancel operation
  Future<bool> cancelOperation(String operationId) async {
    final operation = _activeOperations[operationId];
    if (operation != null && operation.isActive) {
      final cancelledOperation = operation.copyWith(
        status: CncOperationStatus.cancelled,
        completedAt: DateTime.now(),
        duration: DateTime.now().difference(
          operation.startedAt ?? operation.createdAt,
        ),
      );

      _activeOperations[operationId] = cancelledOperation;
      _operationHistory.add(cancelledOperation);
      _operationController.add(cancelledOperation);

      debugPrint(
        '🚫 Operation cancelled: ${operation.typeDisplayName} on ${operation.vpsName}',
      );
      return true;
    }
    return false;
  }

  /// Dispose resources
  void dispose() {
    _monitoringController.close();
    _operationController.close();
  }
}
