import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:simple_weather/routes/app_routes.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safePageIndex =
        widget.warnings.isEmpty
            ? 0
            : _currentPage.clamp(0, widget.warnings.length - 1);
    final cardBackgroundColor =
        isDark
            ? const Color(0xFF2D2E32)
            : _getWarningCardBackgroundColor(
              widget.warnings.isEmpty
                  ? 'white'
                  : widget.warnings[safePageIndex].severityColor,
            );
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.warningDetail,
            arguments: widget.warnings[_currentPage],
          );
        },
        child: SizedBox(
          height: widget.warnings.length > 1 ? 130 : 110,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.warnings.length,
                  itemBuilder: (context, index) {
                    final warning = widget.warnings[index];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getWarningIconBackgroundColor(
                                    warning.severityColor,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  warning.typeName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  warning.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            warning.text,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (widget.warnings.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.warnings.length, (index) {
                      return Container(
                        width: _currentPage == index ? 16 : 8,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index
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
      ),
    );
  }

  Color _getWarningCardBackgroundColor(String severityColor) {
    switch (severityColor.toLowerCase()) {
      case 'red':
        return const Color(0xFFFFF3F0);
      case 'yellow':
        return const Color(0xFFFFFEEE);
      case 'orange':
        return const Color(0xFFFEF6EA);
      case 'blue':
        return const Color(0xFFECF5FE);
      case 'white':
        return const Color(0xFFFAFBFD);
      default:
        return const Color(0xFFFAFBFD);
    }
  }

  Color _getWarningIconBackgroundColor(String severityColor) {
    switch (severityColor.toLowerCase()) {
      case 'red':
        return const Color(0xFFED2246);
      case 'yellow':
        return const Color(0xFFFFD700);
      case 'orange':
        return const Color(0xFFFF9518);
      case 'blue':
        return const Color(0xFF00A3FF);
      case 'white':
        return const Color(0xFFD3D3D3);
      default:
        return const Color(0xFFD3D3D3);
    }
  }
}
