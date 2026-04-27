import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/app_theme.dart';

class CategoryAvatar extends StatelessWidget {
  final Category category;
  final double radius;

  const CategoryAvatar({
    super.key,
    required this.category,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.hexToColor(category.color);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withAlpha(40),
      child: Icon(
        AppTheme.getIconByName(category.icon),
        color: color,
        size: radius,
      ),
    );
  }
}
