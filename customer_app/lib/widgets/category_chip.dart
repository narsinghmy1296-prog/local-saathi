import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/category.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : Colors.black12),
        ),
        child: Text(
          category.displayName(AppStrings.lang),
          style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
