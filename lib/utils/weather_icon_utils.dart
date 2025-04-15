import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherIconUtils {
  static IconData getWeatherIcon(String iconCode) {
    // 将和风天气的图标代码映射到weather_icons的图标
    switch (iconCode) {
      case '100': // 晴
      case '150': // 晴（夜）
        return WeatherIcons.day_sunny;
      case '101': // 多云
      case '151': // 多云（夜）
        return WeatherIcons.day_cloudy;
      case '102': // 少云
      case '152': // 少云（夜）
        return WeatherIcons.day_cloudy_high;
      case '103': // 晴间多云
      case '153': // 晴间多云（夜）
        return WeatherIcons.day_cloudy;
      case '104': // 阴
        return WeatherIcons.cloudy;
      case '200': // 有风
        return WeatherIcons.windy;
      case '201': // 平静
        return WeatherIcons.wind_beaufort_0;
      case '202': // 微风
        return WeatherIcons.wind_beaufort_1;
      case '203': // 和风
        return WeatherIcons.wind_beaufort_2;
      case '204': // 清风
        return WeatherIcons.wind_beaufort_3;
      case '205': // 强风/劲风
        return WeatherIcons.wind_beaufort_4;
      case '206': // 疾风
        return WeatherIcons.wind_beaufort_5;
      case '207': // 大风
        return WeatherIcons.wind_beaufort_6;
      case '208': // 烈风
        return WeatherIcons.wind_beaufort_7;
      case '209': // 风暴
        return WeatherIcons.wind_beaufort_8;
      case '210': // 狂爆风
        return WeatherIcons.wind_beaufort_9;
      case '211': // 飓风
        return WeatherIcons.wind_beaufort_10;
      case '212': // 龙卷风
        return WeatherIcons.tornado;
      case '213': // 热带风暴
        return WeatherIcons.hurricane;
      case '300': // 阵雨
      case '350': // 阵雨（夜）
        return WeatherIcons.showers;
      case '301': // 强阵雨
      case '351': // 强阵雨（夜）
        return WeatherIcons.rain;
      case '302': // 雷阵雨
      case '303': // 强雷阵雨
      case '304': // 雷阵雨伴有冰雹
        return WeatherIcons.thunderstorm;
      case '305': // 小雨
      case '306': // 中雨
      case '307': // 大雨
      case '308': // 极端降雨
      case '309': // 毛毛雨/细雨
      case '310': // 暴雨
      case '311': // 大暴雨
      case '312': // 特大暴雨
      case '313': // 冻雨
      case '314': // 小到中雨
      case '315': // 中到大雨
      case '316': // 大到暴雨
      case '317': // 暴雨到大暴雨
      case '318': // 大暴雨到特大暴雨
      case '399': // 雨
        return WeatherIcons.rain;
      case '400': // 小雪
      case '401': // 中雪
      case '402': // 大雪
      case '403': // 暴雪
      case '404': // 雨夹雪
      case '405': // 雨雪天气
      case '406': // 阵雨夹雪
      case '407': // 阵雪
      case '408': // 小到中雪
      case '409': // 中到大雪
      case '410': // 大到暴雪
      case '456': // 阵雨夹雪（夜）
      case '457': // 阵雪（夜）
      case '499': // 雪
        return WeatherIcons.snow;
      case '500': // 薄雾
      case '501': // 雾
      case '502': // 霾
      case '503': // 扬沙
      case '504': // 浮尘
      case '507': // 沙尘暴
      case '508': // 强沙尘暴
      case '509': // 浓雾
      case '510': // 强浓雾
      case '511': // 中度霾
      case '512': // 重度霾
      case '513': // 严重霾
      case '514': // 大雾
      case '515': // 特强浓雾
        return WeatherIcons.fog;
      case '900': // 热
        return WeatherIcons.hot;
      case '901': // 冷
        return WeatherIcons.snowflake_cold;
      case '999': // 未知
        return WeatherIcons.na;
      default:
        return WeatherIcons.na;
    }
  }

  static String getIconDescription(String iconCode) {
    // 根据图标代码返回对应的天气描述
    switch (iconCode) {
      case '100':
      case '150':
        return '晴';
      case '101':
      case '151':
        return '多云';
      case '102':
      case '152':
        return '少云';
      case '103':
      case '153':
        return '晴间多云';
      case '104':
        return '阴';
      case '200':
        return '有风';
      case '201':
        return '平静';
      case '202':
        return '微风';
      case '203':
        return '和风';
      case '204':
        return '清风';
      case '205':
        return '强风/劲风';
      case '206':
        return '疾风';
      case '207':
        return '大风';
      case '208':
        return '烈风';
      case '209':
        return '风暴';
      case '210':
        return '狂爆风';
      case '211':
        return '飓风';
      case '212':
        return '龙卷风';
      case '213':
        return '热带风暴';
      case '300':
      case '350':
        return '阵雨';
      case '301':
      case '351':
        return '强阵雨';
      case '302':
        return '雷阵雨';
      case '303':
        return '强雷阵雨';
      case '304':
        return '雷阵雨伴有冰雹';
      case '305':
        return '小雨';
      case '306':
        return '中雨';
      case '307':
        return '大雨';
      case '308':
        return '极端降雨';
      case '309':
        return '毛毛雨/细雨';
      case '310':
        return '暴雨';
      case '311':
        return '大暴雨';
      case '312':
        return '特大暴雨';
      case '313':
        return '冻雨';
      case '314':
        return '小到中雨';
      case '315':
        return '中到大雨';
      case '316':
        return '大到暴雨';
      case '317':
        return '暴雨到大暴雨';
      case '318':
        return '大暴雨到特大暴雨';
      case '399':
        return '雨';
      case '400':
        return '小雪';
      case '401':
        return '中雪';
      case '402':
        return '大雪';
      case '403':
        return '暴雪';
      case '404':
        return '雨夹雪';
      case '405':
        return '雨雪天气';
      case '406':
      case '456':
        return '阵雨夹雪';
      case '407':
      case '457':
        return '阵雪';
      case '408':
        return '小到中雪';
      case '409':
        return '中到大雪';
      case '410':
        return '大到暴雪';
      case '499':
        return '雪';
      case '500':
        return '薄雾';
      case '501':
        return '雾';
      case '502':
        return '霾';
      case '503':
        return '扬沙';
      case '504':
        return '浮尘';
      case '507':
        return '沙尘暴';
      case '508':
        return '强沙尘暴';
      case '509':
        return '浓雾';
      case '510':
        return '强浓雾';
      case '511':
        return '中度霾';
      case '512':
        return '重度霾';
      case '513':
        return '严重霾';
      case '514':
        return '大雾';
      case '515':
        return '特强浓雾';
      case '900':
        return '热';
      case '901':
        return '冷';
      case '999':
        return '未知';
      default:
        return '未知';
    }
  }
}
