// lib\shared\widgets\settings_navigation_tile.dart
import 'package:flutter/material.dart';
import 'settings_tile.dart';

class SettingsNavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const SettingsNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      onTap: onTap,
    );
  }
}