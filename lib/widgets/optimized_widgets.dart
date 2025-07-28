import 'package:flutter/material.dart';
import '../services/performance_service.dart';

/// Optimized StatefulWidget that reduces unnecessary rebuilds
abstract class OptimizedStatefulWidget extends StatefulWidget {
  const OptimizedStatefulWidget({super.key});
}

/// Optimized State that implements performance best practices
abstract class OptimizedState<T extends OptimizedStatefulWidget>
    extends State<T>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Performance service instance
  final PerformanceService _performanceService = PerformanceService();

  /// Track widget lifecycle for performance monitoring
  @override
  void initState() {
    super.initState();
    _performanceService.startOperation('${widget.runtimeType}_init');
    onInitState();
    _performanceService.endOperation('${widget.runtimeType}_init');
  }

  @override
  void dispose() {
    _performanceService.startOperation('${widget.runtimeType}_dispose');
    onDispose();
    _performanceService.endOperation('${widget.runtimeType}_dispose');
    super.dispose();
  }

  /// Override these methods instead of initState/dispose
  void onInitState() {}
  void onDispose() {}

  /// Optimized setState with debouncing
  void optimizedSetState(
    VoidCallback fn, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    PerformanceService.debounce(() {
      if (mounted) {
        setState(fn);
      }
    }, delay: delay);
  }

  /// Throttled setState for high-frequency updates
  void throttledSetState(
    VoidCallback fn,
    String key, {
    Duration interval = const Duration(milliseconds: 500),
  }) {
    if (PerformanceService.throttle(key, interval: interval)) {
      if (mounted) {
        setState(fn);
      }
    }
  }
}

/// Optimized Card widget with lazy loading
class OptimizedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool lazy;

  const OptimizedCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
    this.lazy = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Card(
      margin: margin ?? const EdgeInsets.all(8),
      color: color,
      elevation: elevation ?? 2,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (lazy) {
      return FutureBuilder<Widget>(
        future: Future.delayed(
          const Duration(milliseconds: 100),
          () => cardWidget,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          }
          return Container(
            margin: margin ?? const EdgeInsets.all(8),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
          );
        },
      );
    }

    return cardWidget;
  }
}

/// Optimized ListView with performance enhancements
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Optimized Image widget with caching and lazy loading
class OptimizedImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool lazy;

  const OptimizedImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.lazy = true,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (imagePath.startsWith('http')) {
      imageProvider = NetworkImage(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      imageProvider = AssetImage(imagePath);
    } else {
      imageProvider = AssetImage(imagePath);
    }

    final imageWidget = Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.withValues(alpha: 0.3),
              child: const Icon(Icons.error),
            );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
    );

    if (lazy) {
      return FutureBuilder<Widget>(
        future: Future.delayed(
          const Duration(milliseconds: 100),
          () => imageWidget,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          }
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.withValues(alpha: 0.1),
              );
        },
      );
    }

    return imageWidget;
  }
}

/// Optimized AnimatedContainer with performance controls
class OptimizedAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Decoration? decoration;
  final bool enableAnimation;

  const OptimizedAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableAnimation) {
      return Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        color: color,
        decoration: decoration,
        child: child,
      );
    }

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      child: child,
    );
  }
}

/// Optimized StreamBuilder with error handling and performance monitoring
class OptimizedStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const OptimizedStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.initialData,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        // Performance monitoring
        final performanceService = PerformanceService();
        performanceService.startOperation('StreamBuilder_${T.toString()}');

        Widget result;

        if (snapshot.hasError) {
          result =
              errorWidget ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
        } else if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          result =
              loadingWidget ?? const Center(child: CircularProgressIndicator());
        } else {
          result = builder(context, snapshot);
        }

        performanceService.endOperation('StreamBuilder_${T.toString()}');
        return result;
      },
    );
  }
}

/// Optimized FutureBuilder with caching
class OptimizedFutureBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final T? initialData;
  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool cacheResult;

  const OptimizedFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.initialData,
    this.loadingWidget,
    this.errorWidget,
    this.cacheResult = true,
  });

  @override
  State<OptimizedFutureBuilder<T>> createState() =>
      _OptimizedFutureBuilderState<T>();
}

class _OptimizedFutureBuilderState<T> extends State<OptimizedFutureBuilder<T>> {
  static final Map<String, dynamic> _cache = {};
  late String _cacheKey;
  AsyncSnapshot<T>? _cachedSnapshot;

  @override
  void initState() {
    super.initState();
    _cacheKey = widget.future.hashCode.toString();

    if (widget.cacheResult && _cache.containsKey(_cacheKey)) {
      _cachedSnapshot = _cache[_cacheKey] as AsyncSnapshot<T>?;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedSnapshot != null && widget.cacheResult) {
      return widget.builder(context, _cachedSnapshot!);
    }

    return FutureBuilder<T>(
      future: widget.future,
      initialData: widget.initialData,
      builder: (context, snapshot) {
        // Cache successful results
        if (widget.cacheResult && snapshot.hasData) {
          _cache[_cacheKey] = snapshot;
          _cachedSnapshot = snapshot;
        }

        if (snapshot.hasError) {
          return widget.errorWidget ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        return widget.builder(context, snapshot);
      },
    );
  }
}
