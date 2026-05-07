import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// NavTabItem  (Value Object)
//
// Immutable descriptor for a single bottom-navigation tab.
// Separating data from rendering keeps NavTile and PatientNavBar
// free of hard-coded strings / icons.
// ─────────────────────────────────────────────────────────────
@immutable
class NavTabItem {
  final IconData icon;
  final String label;

  const NavTabItem({required this.icon, required this.label});
}
