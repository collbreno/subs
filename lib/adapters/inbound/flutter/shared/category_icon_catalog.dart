import 'package:flutter/material.dart';

final class CategoryIconOption {
  const CategoryIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

// Add, remove, or reorder category icons in this list.
// Keys are persisted in SQLite, so avoid renaming an existing key.
const categoryIconOptions = <CategoryIconOption>[
  CategoryIconOption(
    key: 'category',
    label: 'General',
    icon: Icons.category_outlined,
  ),
  CategoryIconOption(key: 'home', label: 'Home', icon: Icons.home_outlined),
  CategoryIconOption(key: 'bolt', label: 'Utilities', icon: Icons.bolt),
  CategoryIconOption(key: 'wifi', label: 'Internet', icon: Icons.wifi),
  CategoryIconOption(
    key: 'movie',
    label: 'Entertainment',
    icon: Icons.movie_outlined,
  ),
  CategoryIconOption(key: 'music', label: 'Music', icon: Icons.music_note),
  CategoryIconOption(key: 'sports', label: 'Sports', icon: Icons.sports_soccer),
  CategoryIconOption(
    key: 'health',
    label: 'Health',
    icon: Icons.health_and_safety_outlined,
  ),
  CategoryIconOption(
    key: 'education',
    label: 'Education',
    icon: Icons.school_outlined,
  ),
  CategoryIconOption(
    key: 'shopping',
    label: 'Shopping',
    icon: Icons.shopping_bag_outlined,
  ),
  CategoryIconOption(
    key: 'food',
    label: 'Food',
    icon: Icons.restaurant_outlined,
  ),
  CategoryIconOption(
    key: 'transport',
    label: 'Transport',
    icon: Icons.directions_car_outlined,
  ),
  CategoryIconOption(key: 'pets', label: 'Pets', icon: Icons.pets_outlined),
  CategoryIconOption(key: 'cloud', label: 'Cloud', icon: Icons.cloud_outlined),
  CategoryIconOption(key: 'phone', label: 'Phone', icon: Icons.phone_android),
  CategoryIconOption(
    key: 'fitness',
    label: 'Fitness',
    icon: Icons.fitness_center,
  ),
];

IconData categoryIconData(String key) {
  for (final option in categoryIconOptions) {
    if (option.key == key) return option.icon;
  }
  return Icons.category_outlined;
}
