import 'package:flutter/material.dart';
import 'package:simple_weather/models/city_model.dart';

class CityCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(city.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (isCurrent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('不能删除当前城市')));
          return false;
        }
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Icon(
              Icons.location_city,
              color: isCurrent ? Colors.blue : Colors.grey,
            ),
            title: Text(
              city.name,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${(city.adm2?.isEmpty ?? true) || city.adm2 == city.name ? '' : '${city.adm2},'}${city.adm1 ?? ''} ${city.country ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing:
                isCurrent
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
          ),
        ),
      ),
    );
  }
}
