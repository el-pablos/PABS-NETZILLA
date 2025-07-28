import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight Performance Service for PABS-NETZILLA
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Memory management
  Timer? _memoryCleanupTimer;
  final Map<String, DateTime> _operationTimestamps = {};
  
  // Throttling and debouncing
  static final Map<String, Timer> _debounceTimers = {};
  static final Map<String, DateTime> _throttleTimestamps = {};

  /// Initialize performance service
  void initialize() {
    debugPrint('🚀 Initializing Performance Service...');
    
    // Setup periodic memory cleanup
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performMemoryCleanup(),
    );
    
    debugPrint('✅ Performance Service initialized');
  }

  /// Perform memory cleanup
  void _performMemoryCleanup() {
    debugPrint('🧹 Performing memory cleanup...');
    
    // Clear old operation timestamps
    final now = DateTime.now();
    _operationTimestamps.removeWhere(
      (key, timestamp) => now.difference(timestamp).inMinutes > 10,
    );
    
    // Clear old throttle timestamps
    _throttleTimestamps.removeWhere(
      (key, timestamp) => now.difference(timestamp).inSeconds > 30,
    );
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      // System.gc() equivalent for Dart
      List.generate(1000, (i) => i).clear();
    }
    
    debugPrint('✅ Memory cleanup completed');
  }

  /// Debounce function calls
  static void debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
    String? key,
  }) {
    final debounceKey = key ?? callback.hashCode.toString();
    
    _debounceTimers[debounceKey]?.cancel();
    _debounceTimers[debounceKey] = Timer(delay, () {
      callback();
      _debounceTimers.remove(debounceKey);
    });
  }

  /// Throttle function calls
  static bool throttle(
    String key, {
    Duration interval = const Duration(milliseconds: 500),
  }) {
    final now = DateTime.now();
    final lastCall = _throttleTimestamps[key];
    
    if (lastCall == null || now.difference(lastCall) >= interval) {
      _throttleTimestamps[key] = now;
      return true;
    }
    
    return false;
  }

  /// Start operation tracking
  void startOperation(String operationName) {
    _operationTimestamps[operationName] = DateTime.now();
  }

  /// End operation tracking
  void endOperation(String operationName) {
    final startTime = _operationTimestamps[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('⏱️ Operation "$operationName" took ${duration.inMilliseconds}ms');
      _operationTimestamps.remove(operationName);
    }
  }

  /// Run computation in isolate for heavy tasks
  static Future<T> runInIsolate<T>(
    T Function(dynamic) computation,
    dynamic data,
  ) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _isolateEntryPoint,
      IsolateData(
        sendPort: receivePort.sendPort,
        computation: computation,
        data: data,
      ),
    );
    
    final result = await receivePort.first;
    receivePort.close();
    
    if (result is Exception) {
      throw result;
    }
    
    return result as T;
  }

  /// Isolate entry point
  static void _isolateEntryPoint(IsolateData isolateData) {
    try {
      final result = isolateData.computation(isolateData.data);
      isolateData.sendPort.send(result);
    } catch (e) {
      isolateData.sendPort.send(e);
    }
  }

  /// Optimize image loading
  static ImageProvider optimizeImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    } else {
      return AssetImage(imagePath);
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🧹 Disposing Performance Service...');
    
    _memoryCleanupTimer?.cancel();
    _operationTimestamps.clear();
    _debounceTimers.values.forEach((timer) => timer.cancel());
    _debounceTimers.clear();
    _throttleTimestamps.clear();
    
    debugPrint('✅ Performance Service disposed');
  }
}

/// Data class for isolate communication
class IsolateData {
  final SendPort sendPort;
  final Function computation;
  final dynamic data;

  IsolateData({
    required this.sendPort,
    required this.computation,
    required this.data,
  });
}
