import 'package:flutter/material.dart';
import 'package:simple_weather/models/city_model.dart';

class CityCard extends StatefulWidget {
  final CityModel city;
  final VoidCallback onDelete;
  final bool isCurrent;
  final VoidCallback onTap;

  const CityCard({
    super.key,
    required this.city,
    required this.onDelete,
    this.isCurrent = false,
    required this.onTap,
  });

  @override
  State<CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<CityCard> {
  bool _isSwipingToDelete = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const outerBorderRadius = BorderRadius.all(Radius.circular(15));
    final borderRadius =
        _isSwipingToDelete
            ? const BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            )
            : BorderRadius.circular(15);
    return ClipRRect(
      borderRadius: outerBorderRadius,
      child: Dismissible(
        key: Key(widget.city.id.toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          if (widget.isCurrent) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('不能删除当前城市')));
            return false;
          }
          return true;
        },
        onUpdate: (details) {
          final isSwiping =
              details.direction == DismissDirection.endToStart &&
              details.progress > 0;
          if (_isSwipingToDelete != isSwiping) {
            setState(() {
              _isSwipingToDelete = isSwiping;
            });
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: const BoxDecoration(
            color: Colors.red,
            borderRadius: outerBorderRadius,
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => widget.onDelete(),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color:
              isDark
                  ? const Color(0xFF2D2E32)
                  : Theme.of(context).cardColor.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: widget.onTap,
            child: ListTile(
              leading: Icon(
                Icons.location_city,
                color:
                    widget.isCurrent
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              title: Text(
                widget.city.name,
                style: TextStyle(
                  fontWeight:
                      widget.isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                '${(widget.city.adm2?.isEmpty ?? true) || widget.city.adm2 == widget.city.name ? '' : '${widget.city.adm2},'}${widget.city.adm1 ?? ''} ${widget.city.country ?? ''}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing:
                  widget.isCurrent
                      ? Icon(Icons.check_circle, color: colorScheme.primary)
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}
