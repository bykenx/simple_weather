import 'package:flutter/material.dart';

class WeatherBottomBar extends StatelessWidget {
  final int cityCount, currentIndex;
  final ValueChanged<int> onCitySelected;
  final VoidCallback onMap, onCities;
  const WeatherBottomBar({
    super.key,
    required this.cityCount,
    required this.currentIndex,
    required this.onCitySelected,
    required this.onMap,
    required this.onCities,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String tooltip, VoidCallback action) =>
        Material(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xED193A50)
                  : const Color(0xEDF3F8FA),
          shape: const CircleBorder(),
          child: IconButton(
            iconSize: 28,
            padding: const EdgeInsets.all(14),
            tooltip: tooltip,
            onPressed: action,
            icon: Icon(
              icon,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF193B50),
            ),
          ),
        );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              button(Icons.map_outlined, '在地图中打开当前城市', onMap),
              const SizedBox(width: 16),
              Expanded(
                child: Center(
                  child: Material(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xED193A50)
                            : const Color(0xEDF3F8FA),
                    borderRadius: BorderRadius.circular(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            cityCount,
                            (index) => Semantics(
                              selected: index == currentIndex,
                              child: IconButton(
                                tooltip: '切换到第 ${index + 1} 个城市',
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 44,
                                ),
                                onPressed: () => onCitySelected(index),
                                icon: Icon(
                                  Icons.circle,
                                  size: 8,
                                  color:
                                      index == currentIndex
                                          ? (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : const Color(0xFF193B50))
                                          : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white38
                                              : const Color(0xFF9BA8AC)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              button(Icons.format_list_bulleted, '城市列表', onCities),
            ],
          ),
        ),
      ),
    );
  }
}
