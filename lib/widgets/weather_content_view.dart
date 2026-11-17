import '../utils/url.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/city_weather_data.dart';
import '../models/weather_model.dart';
import '../models/weather_module.dart';
import '../models/precipitation_summary.dart';
import '../utils/weather_time.dart';
import 'air_quality_card.dart';
import 'forecast_detail_sheet.dart';
import 'weather_detail_sheet.dart';
import 'daily_forecast_card.dart';
import 'hourly_forecast_card.dart';
import 'weather_details_card.dart';
import 'weather_warning_card.dart';
import 'weather_card_surface.dart';

class WeatherContentView extends StatelessWidget {
  final CityWeatherData data;
  final VoidCallback onMap;
  final Future<void> Function(WeatherModule) onRetry;
  final Listenable? updates;
  const WeatherContentView({
    super.key,
    required this.data,
    required this.onMap,
    required this.onRetry,
    this.updates,
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
            : '最近更新于 ${DateFormat('MM-dd HH:mm').format(WeatherTimeUtils.atOffset(updates.last, data.utcOffset))}';
    // The clipped card surfaces do not overlap, so their identical blur can
    // share one backdrop input. Keep each city's content in its own group.
    return BackdropGroup(
      child: SliverPadding(
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
                  await UrlUtils.launchUrlInBrowser(
                    'https://www.qweather.com/',
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('暂时无法打开天气数据来源')),
                    );
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
      ),
    );
  }

  void _openForecast(BuildContext context, DateTime date) {
    Widget detail() => ForecastDetailSheet(
      days: data.detailDays,
      hours: data.detailHours,
      startDate: data.detailStartDate,
      initialDate: date,
      cityName: data.city.name,
      utcOffset: data.utcOffset,
      weather: data.weather,
    );
    showWeatherDetailSheet(
      context,
      title: '天气状况',
      icon: Icons.cloud_outlined,
      child:
          updates == null
              ? detail()
              : ListenableBuilder(
                listenable: updates!,
                builder: (context, _) => detail(),
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
          final precipitation = PrecipitationSummary.fromHours(
            data.hourlyForecast ?? const [],
            utcOffset: data.utcOffset,
          );
          content = WeatherDetailsCard(
            weather: data.weather!,
            daily: data.detailDays.firstOrNull,
            precipitation: precipitation,
            onPrecipitationTap:
                () => _openForecast(
                  context,
                  precipitation.highProbabilityHours.firstOrNull?.time ??
                      precipitation.hours.firstOrNull?.time ??
                      data.detailStartDate,
                ),
          );
        }
      case WeatherModule.daily:
        final days = data.detailDays;
        if (days.isNotEmpty) {
          content = DailyForecastCard(
            dailyForecast: days,
            currentCity: data.city,
            now: WeatherTimeUtils.atOffset(DateTime.now(), data.utcOffset),
            onDayTap: (date) => _openForecast(context, date),
          );
        }
      case WeatherModule.hourly:
        final upcoming = data.detailHours;
        if (upcoming.isNotEmpty) {
          content = HourlyForecastCard(
            hourlyForecast: upcoming,
            onTap: () => _openForecast(context, upcoming.first.time),
          );
        }
      case WeatherModule.warnings:
        final active = activeWeatherWarnings(data.warnings ?? []);
        if (active.isNotEmpty) {
          content = WeatherWarningCard(
            warnings: active,
            utcOffset: data.utcOffset,
          );
        }
      case WeatherModule.airQuality:
        if (data.airQuality?.code == 'cn-mee') {
          content = AirQualityCard(airQuality: data.airQuality!);
        }
    }
    if (content == null) {
      if (error == null) return const SizedBox.shrink();
      final title = switch (module) {
        WeatherModule.live => '实时天气',
        WeatherModule.daily => '每日预报',
        WeatherModule.hourly => '逐小时预报',
        WeatherModule.warnings => '天气预警',
        WeatherModule.airQuality => '空气质量',
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: WeatherCardSurface(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title暂时无法加载',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(error),
                TextButton(
                  onPressed: state.isLoading ? null : () => onRetry(module),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
          if (module == WeatherModule.hourly &&
              !hasTenDayHourlyCoverage(data.hourlyForecast!))
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('逐小时预报不足10天，显示已获取时段'),
            ),
          content,
        ],
      ),
    );
  }
}
