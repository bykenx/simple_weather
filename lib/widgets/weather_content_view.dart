import '../utils/url_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/city_weather_data.dart';
import '../models/weather_module.dart';
import 'air_quality_card.dart';
import 'forecast_detail_sheet.dart';
import 'weather_detail_sheet.dart';
import 'daily_forecast_card.dart';
import 'hourly_forecast_card.dart';
import 'weather_details_card.dart';
import 'weather_warning_card.dart';

class WeatherContentView extends StatelessWidget {
  final CityWeatherData data;
  final VoidCallback onMap;
  final Future<void> Function(WeatherModule) onRetry;
  const WeatherContentView({
    super.key,
    required this.data,
    required this.onMap,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    final states = WeatherModule.values.map(data.module).toList();
    final updates =
        states.map((state) => state.updatedAt).whereType<DateTime>().toList()
          ..sort();
    final hasExpired = states.any(
      (state) => state.data != null && state.isExpired,
    );
    final hasCached = states.any(
      (state) => state.data != null && (state.fromCache || state.error != null),
    );
    final timestamp =
        updates.isEmpty
            ? '尚未更新'
            : '最近更新于 ${DateFormat('MM-dd HH:mm').format(updates.last.toLocal())}';
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      sliver: SliverList.list(
        children: [
          ...[
            WeatherModule.warnings,
            WeatherModule.airQuality,
            WeatherModule.hourly,
            WeatherModule.daily,
            WeatherModule.live,
          ].map((module) => _section(context, module)),
          const Divider(height: 24),
          TextButton.icon(
            onPressed: onMap,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('在地图中打开'),
          ),
          const Divider(height: 24),
          Text(
            '${data.city.country ?? ''}${data.city.adm1 ?? ''}${data.city.name}的天气',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () async {
              try {
                await UrlUtils.launchUrlInBrowser('https://www.qweather.com/');
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('暂时无法打开天气数据来源')));
                }
              }
            },
            child: const Text('天气数据由和风天气提供'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '$timestamp${hasExpired
                  ? ' · 部分数据已过期'
                  : hasCached
                  ? ' · 含已保存数据'
                  : ''}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _openForecast(BuildContext context, DateTime date) {
    showWeatherDetailSheet(
      context,
      title: '天气状况',
      icon: Icons.cloud_outlined,
      child: ForecastDetailSheet(
        days: data.dailyForecast ?? [],
        hours: data.hourlyForecast ?? [],
        initialDate: date,
        cityName: data.city.name,
      ),
    );
  }

  Widget _section(BuildContext context, WeatherModule module) {
    final state = data.module(module);
    final error =
        state.error == '网络不可用' && state.data != null
            ? '网络不可用，显示已保存数据'
            : state.error;
    Widget? content;
    switch (module) {
      case WeatherModule.live:
        if (data.weather != null) {
          content = WeatherDetailsCard(
            weather: data.weather!,
            daily: data.dailyForecast?.firstOrNull,
            dailyForecast: data.dailyForecast ?? const [],
            latitude: data.city.lat,
            longitude: data.city.lon,
          );
        }
      case WeatherModule.daily:
        if (data.dailyForecast?.isNotEmpty == true) {
          content = DailyForecastCard(
            dailyForecast: data.dailyForecast!,
            currentCity: data.city,
            onDayTap: (date) => _openForecast(context, date),
          );
        }
      case WeatherModule.hourly:
        final hours = data.hourlyForecast;
        if (hours?.isNotEmpty == true) {
          content = HourlyForecastCard(
            hourlyForecast: hours!,
            onTap: () => _openForecast(context, hours.first.time),
          );
        }
      case WeatherModule.warnings:
        final active =
            data.warnings
                ?.where((w) => w.endTime.isAfter(DateTime.now()))
                .toList();
        if (active?.isNotEmpty == true) {
          content = WeatherWarningCard(warnings: active!);
        }
      case WeatherModule.airQuality:
        if (data.airQuality?.code == 'cn-mee') {
          content = AirQualityCard(airQuality: data.airQuality!);
        }
    }
    if (content == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(error),
                TextButton(
                  onPressed: state.isLoading ? null : () => onRetry(module),
                  child: const Text('重试'),
                ),
              ],
            ),
          if (error != null) const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
