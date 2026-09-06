import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A top-edge pull gesture with five dots; unrelated loads never show it.
class WeatherRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const WeatherRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<WeatherRefreshIndicator> createState() =>
      _WeatherRefreshIndicatorState();
}

class _WeatherRefreshIndicatorState extends State<WeatherRefreshIndicator> {
  double _pullDistance = 0;
  bool _startedAtTop = false;
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _pullDistance = 0;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  bool _notification(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axisDirection != AxisDirection.down ||
        _refreshing) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _startedAtTop =
          notification.dragDetails != null &&
          notification.metrics.extentBefore == 0;
      if (_pullDistance != 0) setState(() => _pullDistance = 0);
    } else if (notification is OverscrollNotification &&
        _startedAtTop &&
        notification.dragDetails != null) {
      if (notification.metrics.extentBefore == 0) {
        setState(
          () =>
              _pullDistance = (_pullDistance - notification.overscroll).clamp(
                0.0,
                160.0,
              ),
        );
      }
    } else if (notification is ScrollUpdateNotification &&
        _startedAtTop &&
        notification.dragDetails != null) {
      if (notification.metrics.extentBefore > 0) {
        _startedAtTop = false;
        setState(() => _pullDistance = 0);
      } else if (notification.metrics.pixels <
              notification.metrics.minScrollExtent ||
          _pullDistance > 0) {
        setState(
          () =>
              _pullDistance = (_pullDistance - (notification.scrollDelta ?? 0))
                  .clamp(0.0, 160.0),
        );
      }
    } else if (notification is ScrollEndNotification) {
      final shouldRefresh = _startedAtTop && _pullDistance >= 80;
      _startedAtTop = false;
      if (shouldRefresh) {
        _refresh();
      } else if (_pullDistance != 0) {
        setState(() => _pullDistance = 0);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _refreshing || _pullDistance > 0;
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _notification,
          child: widget.child,
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child:
                  visible
                      ? const Center(child: WeatherLoadingDots())
                      : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class WeatherLoadingDots extends StatefulWidget {
  const WeatherLoadingDots({super.key});

  @override
  State<WeatherLoadingDots> createState() => _WeatherLoadingDotsState();
}

class _WeatherLoadingDotsState extends State<WeatherLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
      _animation.value = 0;
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '正在加载天气',
      liveRegion: true,
      child: SizedBox(
        width: 76,
        height: 28,
        child: AnimatedBuilder(
          animation: _animation,
          builder:
              (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final phase = (_animation.value - index * 0.12 + 1) % 1;
                  final lift =
                      phase < 0.4 ? math.sin(phase / 0.4 * math.pi) : 0.0;
                  return Transform.translate(
                    offset: Offset(0, -7 * lift),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          Color.lerp(colors.primary, colors.surface, 0.30),
                          colors.primary,
                          index / 4,
                        ),
                      ),
                    ),
                  );
                }),
              ),
        ),
      ),
    );
  }
}
