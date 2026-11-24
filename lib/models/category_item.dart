import 'package:flutter/material.dart';

class CategoryItem {
  final int id;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon;
  final String colorHex;
  final bool isDefault;

  CategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorHex,
    this.isDefault = true,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.indigo;
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'payments':
      case 'salary':
        return Icons.payments_rounded;
      case 'business_center':
        return Icons.business_center_rounded;
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'local_gas_station':
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'shopping_cart':
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'home':
      case 'rent':
        return Icons.home_rounded;
      case 'bolt':
      case 'electricity':
        return Icons.bolt_rounded;
      case 'local_hospital':
      case 'medical':
        return Icons.local_hospital_rounded;
      case 'directions_car':
      case 'travel':
        return Icons.directions_car_rounded;
      case 'account_balance':
      case 'emi':
        return Icons.account_balance_rounded;
      case 'movie':
      case 'entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      icon: json['icon'] ?? 'category',
      colorHex: json['color'] ?? json['colorHex'] ?? '#6366F1',
      isDefault: json['is_default'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': colorHex,
      'is_default': isDefault,
    };
  }
}
