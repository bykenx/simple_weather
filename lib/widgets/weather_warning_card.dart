import '../utils/warning_colors.dart';
import 'weather_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'weather_warning_sheet.dart';

class WeatherWarningCard extends StatefulWidget {
  final List<WeatherWarningModel> warnings;

  const WeatherWarningCard({super.key, required this.warnings});

  @override
  State<WeatherWarningCard> createState() => _WeatherWarningCardState();
}

class _WeatherWarningCardState extends State<WeatherWarningCard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (_currentPage != page) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.warnings.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final safePageIndex =
        widget.warnings.isEmpty
            ? 0
            : _currentPage.clamp(0, widget.warnings.length - 1);
    return WeatherCardSurface(
      child: InkWell(
        borderRadius: WeatherCardSurface.borderRadius,
        onTap:
            () => showWeatherWarningSheet(
              context,
              widget.warnings[safePageIndex],
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // The current content supplies the page viewport's natural height.
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0,
                      child: _warningContent(widget.warnings[safePageIndex]),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    physics:
                        widget.warnings.length == 1
                            ? const NeverScrollableScrollPhysics()
                            : const ClampingScrollPhysics(),
                    itemCount: widget.warnings.length,
                    itemBuilder: (context, index) {
                      final warning = widget.warnings[index];
                      return OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: _warningContent(warning),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (widget.warnings.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.warnings.length, (index) {
                    return Container(
                      width: safePageIndex == index ? 16 : 8,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            safePageIndex == index
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _warningContent(WeatherWarningModel warning) {
    final colorScheme = Theme.of(context).colorScheme;
    final severity = warning.severityColor.toLowerCase();
    final accent = WarningColors.background(severity);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warning.typeName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            warning.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            warning.sender.isEmpty ? '气象预警' : warning.sender,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
