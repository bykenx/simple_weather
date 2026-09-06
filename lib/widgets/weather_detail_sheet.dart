import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

Future<void> showWeatherDetailSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Widget child,
}) {
  final theme = AppTheme.build(Theme.of(context).brightness);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    clipBehavior: Clip.antiAlias,
    builder:
        (_) => Theme(
          data: theme,
          child: Material(
            color: theme.colorScheme.surface,
            textStyle: theme.textTheme.bodyLarge,
            child: DraggableScrollableSheet(
              initialChildSize: .97,
              maxChildSize: .97,
              minChildSize: .45,
              expand: false,
              builder:
                  (context, controller) => CustomScrollView(
                    controller: controller,
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        automaticallyImplyLeading: false,
                        backgroundColor: theme.colorScheme.surface,
                        surfaceTintColor: Colors.transparent,
                        toolbarHeight:
                            64 + MediaQuery.textScalerOf(context).scale(16),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        centerTitle: true,
                        actions: [
                          IconButton.filledTonal(
                            tooltip: '关闭',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          24 + MediaQuery.paddingOf(context).bottom,
                        ),
                        sliver: SliverToBoxAdapter(child: child),
                      ),
                    ],
                  ),
            ),
          ),
        ),
  );
}

class DetailPanel extends StatelessWidget {
  final Widget child;
  const DetailPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  const DetailSection({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DetailPanel(child: child),
      ],
    ),
  );
}

String detailNumber(double? value, String unit) =>
    value != null && value.isFinite
        ? '${value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1)}$unit'
        : '暂无数据';
String detailText(String? value) =>
    value == null || value.trim().isEmpty ? '暂无数据' : value;
