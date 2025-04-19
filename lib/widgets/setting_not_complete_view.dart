import 'package:flutter/material.dart';

class SettingNotCompleteView extends StatelessWidget {
  final VoidCallback onSettings;

  const SettingNotCompleteView({super.key, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('未完成API配置'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onSettings,
            icon: const Icon(Icons.settings),
            label: const Text('去设置'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
