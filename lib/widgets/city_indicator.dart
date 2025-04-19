import 'package:flutter/material.dart';

class CityIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final Function(int) onDotTap;
  final double dotSize;
  final double spacing;

  const CityIndicator({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.onDotTap,
    this.dotSize = 8.0,
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalCount,
        (index) => GestureDetector(
          onTap: () => onDotTap(index),
          child: Container(
            width: dotSize,
            height: dotSize,
            margin: EdgeInsets.symmetric(horizontal: spacing),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentIndex == index 
                  ? Colors.blue 
                  : Colors.blue.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
} 