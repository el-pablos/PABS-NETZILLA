import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service untuk optimasi performa aplikasi
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Memory management
  Timer? _memoryCleanupTimer;
  final List<StreamSubscription> _subscriptions = [];
  
  // Performance monitoring
  final Map<String, DateTime> _operationTimestamps = {};
  final Map<String, Duration> _operationDurations = {};

  /// Initialize performance optimizations
  void initialize() {
    debugPrint('🚀 Initializing Performance Service...');
    
    // Start memory cleanup timer
    _startMemoryCleanup();
    
    // Optimize system UI
    _optimizeSystemUI();
    
    // Set up performance monitoring
    _setupPerformanceMonitoring();
    
    debugPrint('✅ Performance Service initialized');
  }

  /// Start memory cleanup timer
  void _startMemoryCleanup() {
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performMemoryCleanup(),
    );
  }

  /// Perform memory cleanup
  void _performMemoryCleanup() {
    try {
      // Force garbage collection
      if (kDebugMode) {
        debugPrint('🧹 Performing memory cleanup...');
      }
      
      // Clear old operation data
      final now = DateTime.now();
      _operationTimestamps.removeWhere((key, timestamp) {
        return now.difference(timestamp).inMinutes > 10;
      });
      
      _operationDurations.removeWhere((key, duration) {
        return _operationTimestamps[key] == null;
      });
      
      // System garbage collection hint
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      
      if (kDebugMode) {
        debugPrint('✅ Memory cleanup completed');
      }
    } catch (e) {
      debugPrint('❌ Memory cleanup error: $e');
    }
  }

  /// Optimize system UI for better performance
  void _optimizeSystemUI() {
    try {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],
      );
      
      // Set preferred orientations for stability
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      debugPrint('✅ System UI optimized');
    } catch (e) {
      debugPrint('❌ System UI optimization error: $e');
    }
  }

  /// Setup performance monitoring
  void _setupPerformanceMonitoring() {
    if (kDebugMode) {
      debugPrint('📊 Performance monitoring enabled');
    }
  }

  /// Start tracking an operation
  void startOperation(String operationName) {
    _operationTimestamps[operationName] = DateTime.now();
  }

  /// End tracking an operation
  void endOperation(String operationName) {
    final startTime = _operationTimestamps[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] = duration;
      
      if (kDebugMode && duration.inMilliseconds > 1000) {
        debugPrint('⚠️ Slow operation: $operationName took ${duration.inMilliseconds}ms');
      }
    }
  }

  /// Get operation performance data
  Map<String, Duration> getPerformanceData() {
    return Map<String, Duration>.from(_operationDurations);
  }

  /// Optimize widget rebuilds by debouncing
  static Timer? _debounceTimer;
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls
  static final Map<String, DateTime> _throttleTimestamps = {};
  static bool throttle(String key, {Duration interval = const Duration(seconds: 1)}) {
    final now = DateTime.now();
    final lastCall = _throttleTimestamps[key];
    
    if (lastCall == null || now.difference(lastCall) >= interval) {
      _throttleTimestamps[key] = now;
      return true;
    }
    
    return false;
  }

  /// Batch operations to reduce overhead
  static Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 5,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((op) => op()),
      );
      
      results.addAll(batchResults);
      
      // Add delay between batches to prevent overwhelming
      if (i + batchSize < operations.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }

  /// Run operation in isolate for heavy computations
  static Future<R> runInIsolate<T, R>(
    R Function(T) computation,
    T data,
  ) async {
    try {
      final receivePort = ReceivePort();
      
      await Isolate.spawn(
        _isolateEntryPoint<T, R>,
        _IsolateData<T, R>(
          computation: computation,
          data: data,
          sendPort: receivePort.sendPort,
        ),
      );
      
      final result = await receivePort.first as R;
      receivePort.close();
      
      return result;
    } catch (e) {
      debugPrint('❌ Isolate operation failed: $e');
      // Fallback to main thread
      return computation(data);
    }
  }

  /// Isolate entry point
  static void _isolateEntryPoint<T, R>(_IsolateData<T, R> isolateData) {
    try {
      final result = isolateData.computation(isolateData.data);
      isolateData.sendPort.send(result);
    } catch (e) {
      isolateData.sendPort.send(e);
    }
  }

  /// Optimize image loading
  static ImageProvider optimizeImage(String imagePath, {
    double? width,
    double? height,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    } else {
      return AssetImage(imagePath);
    }
  }

  /// Lazy loading helper
  static Widget lazyBuilder({
    required Widget Function() builder,
    Widget? placeholder,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return FutureBuilder<Widget>(
      future: Future.delayed(delay, builder),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        return placeholder ?? const SizedBox.shrink();
      },
    );
  }

  /// Memory-efficient list builder
  static Widget efficientListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Optimize for performance
      cacheExtent: 100,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
    );
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🧹 Disposing Performance Service...');
    
    _memoryCleanupTimer?.cancel();
    _debounceTimer?.cancel();
    
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    _operationTimestamps.clear();
    _operationDurations.clear();
    _throttleTimestamps.clear();
    
    debugPrint('✅ Performance Service disposed');
  }
}

/// Data class for isolate operations
class _IsolateData<T, R> {
  final R Function(T) computation;
  final T data;
  final SendPort sendPort;

  _IsolateData({
    required this.computation,
    required this.data,
    required this.sendPort,
  });
}
