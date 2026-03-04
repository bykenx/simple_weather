import 'package:flutter/material.dart';
import 'package:simple_weather/models/weather_model.dart';
import 'package:intl/intl.dart';
import 'package:simple_weather/utils/weather_icon_utils.dart';

class WarningDetailScreen extends StatelessWidget {
  final WeatherWarningModel warning;

  const WarningDetailScreen({super.key, required this.warning});

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBackgroundColor =
        isDark
            ? const Color(0xFF2D2E32)
            : _getWarningCardBackgroundColor(warning.severityColor);
    final iconBackgroundColor = _getWarningIconBackgroundColor(
      warning.severityColor,
    );
    return Scaffold(
      backgroundColor: headerBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            backgroundColor: headerBackgroundColor,
            elevation: 0,
            flexibleSpace: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          WeatherIconUtils.getWeatherIcon(
                            warning.type,
                            filled: true,
                          ),
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              warning.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDateTime(warning.pubTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: headerBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: colorScheme.onSurface,
                        ),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconBackgroundColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                warning.typeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: warning.text),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
