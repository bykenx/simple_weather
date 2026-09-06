import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/weather_scene.dart';
import '../widgets/moon_renderers.dart';
import '../utils/moon_orientation_utils.dart';

/// Local-only controls using the same painter as the weather home screen.
class WeatherPreviewScreen extends StatefulWidget {
  const WeatherPreviewScreen({super.key});

  @override
  State<WeatherPreviewScreen> createState() => _WeatherPreviewScreenState();
}

class _WeatherPreviewScreenState extends State<WeatherPreviewScreen> {
  SkyKind _kind = SkyKind.clear;
  bool _night = false;
  bool _paused = false;
  bool _reduced = false;
  bool _showContent = true;
  bool _showControls = true;
  bool _moonPreview = false;
  double _moonPhase = .39;
  int _moonDayOffset = 0;
  int _restart = 0;
  static const _labels = {
    SkyKind.clear: '晴天',
    SkyKind.clouds: '多云',
    SkyKind.overcast: '阴天',
    SkyKind.rain: '雨天',
    SkyKind.snow: '雪天',
    SkyKind.sleet: '雨夹雪',
    SkyKind.thunder: '雷暴',
    SkyKind.fog: '雾',
    SkyKind.dust: '沙尘',
    SkyKind.wind: '大风',
    SkyKind.unknown: '未知天气',
  };
  static const _moonPhases = [
    (0.0, '新月'),
    (.125, '蛾眉月'),
    (.25, '上弦月'),
    (.375, '盈凸月'),
    (.5, '满月'),
    (.625, '亏凸月'),
    (.75, '下弦月'),
    (.875, '残月'),
  ];

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final systemReduced = MediaQuery.disableAnimationsOf(context);
    final scene = WeatherScene(_kind, _night);
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: systemReduced || _reduced),
              child: WeatherSceneBackground(
                key: ValueKey(_restart),
                scene: scene,
                paused: _paused,
                showDecorativeMoon: !_moonPreview,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        BackButton(onPressed: () => Navigator.pop(context)),
                        const Expanded(child: Text('天气效果预览 · DEBUG')),
                        IconButton(
                          tooltip: _showControls ? '隐藏控制面板' : '显示控制面板',
                          onPressed:
                              () => setState(
                                () => _showControls = !_showControls,
                              ),
                          icon: Icon(
                            _showControls ? Icons.tune : Icons.tune_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _showContent
                            ? SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child:
                                  _moonPreview
                                      ? _moonPreviewContent()
                                      : Column(
                                        children: [
                                          const Text(
                                            '预览城市',
                                            style: TextStyle(
                                              fontSize: 28,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Text(
                                            '24°',
                                            style: TextStyle(
                                              fontSize: 80,
                                              fontWeight: FontWeight.w200,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            '${_labels[_kind]} · ${_night ? '夜间' : '白天'}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            '最高 28°  最低 19° · 示例数据',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: const Color(0xD9294663),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: const Text(
                                              '体感温度 24°\n\n相对湿度 65%\n\n用于检查动态背景上的文字和卡片对比度',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                            )
                            : const SizedBox.expand(),
                  ),
                  if (_showControls)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .45,
                      ),
                      child: Card(
                        margin: const EdgeInsets.all(12),
                        color: const Color(0xEE162638),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final kind in SkyKind.values)
                                    ChoiceChip(
                                      label: Text(_labels[kind]!),
                                      selected: _kind == kind,
                                      onSelected:
                                          (_) => setState(() => _kind = kind),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  FilterChip(
                                    label: const Text('月相预览'),
                                    selected: _moonPreview,
                                    onSelected:
                                        (value) => setState(
                                          () => _moonPreview = value,
                                        ),
                                  ),
                                  FilterChip(
                                    label: const Text('夜间'),
                                    selected: _night,
                                    onSelected:
                                        (v) => setState(() => _night = v),
                                  ),
                                  FilterChip(
                                    label: const Text('示例内容'),
                                    selected: _showContent,
                                    onSelected:
                                        (v) => setState(() => _showContent = v),
                                  ),
                                  FilterChip(
                                    label: const Text('减少动态效果'),
                                    selected: _reduced || systemReduced,
                                    onSelected:
                                        systemReduced
                                            ? null
                                            : (v) =>
                                                setState(() => _reduced = v),
                                  ),
                                  TextButton.icon(
                                    onPressed:
                                        () =>
                                            setState(() => _paused = !_paused),
                                    icon: Icon(
                                      _paused ? Icons.play_arrow : Icons.pause,
                                    ),
                                    label: Text(_paused ? '播放' : '暂停'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => setState(() => _restart++),
                                    icon: const Icon(Icons.replay),
                                    label: const Text('从头播放'),
                                  ),
                                ],
                              ),
                              if (_moonPreview) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text('月相进度'),
                                    Expanded(
                                      child: Slider(
                                        value: _moonPhase,
                                        divisions: 100,
                                        label: _moonPhase.toStringAsFixed(2),
                                        onChanged:
                                            (value) => setState(
                                              () => _moonPhase = value,
                                            ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 42,
                                      child: Text(
                                        _moonPhase.toStringAsFixed(2),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text('日期偏移'),
                                    Expanded(
                                      child: Slider(
                                        value: _moonDayOffset.toDouble(),
                                        min: -15,
                                        max: 15,
                                        divisions: 30,
                                        label:
                                            '${_moonDayOffset >= 0 ? '+' : ''}$_moonDayOffset 天',
                                        onChanged:
                                            (value) => setState(
                                              () =>
                                                  _moonDayOffset =
                                                      value.round(),
                                            ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        '${_moonDayOffset >= 0 ? '+' : ''}$_moonDayOffset 天',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final phase in _moonPhases)
                                      ChoiceChip(
                                        label: Text(phase.$2),
                                        selected:
                                            (_moonPhase - phase.$1).abs() <
                                            .001,
                                        onSelected:
                                            (_) => setState(
                                              () => _moonPhase = phase.$1,
                                            ),
                                      ),
                                  ],
                                ),
                              ],
                              if (systemReduced)
                                const Text(
                                  '系统已开启减少动态效果',
                                  style: TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moonPreviewContent() {
    final previewTime = DateTime.now().add(Duration(days: _moonDayOffset));
    final orientation = approximateMoonOrientation(
      time: previewTime,
      latitude: 22.54,
      longitude: 114.06,
    );
    final illumination =
        (50 * (1 - math.cos(_moonPhase * 2 * math.pi))).round();
    final closest = _moonPhases.reduce(
      (a, b) => (_moonPhase - a.$1).abs() <= (_moonPhase - b.$1).abs() ? a : b,
    );
    return Column(
      children: [
        const Text(
          '月相渲染预览',
          style: TextStyle(fontSize: 28, color: Colors.white),
        ),
        const SizedBox(height: 24),
        SizedBox.square(
          dimension: 280,
          child: MoonPhaseSphere(
            phase: _moonPhase,
            librationLongitude: orientation.longitude,
            librationLatitude: orientation.latitude,
            orientation: orientation.rotation,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${closest.$2} · 照射范围 $illumination%',
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'phase ${_moonPhase.toStringAsFixed(3)}',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
