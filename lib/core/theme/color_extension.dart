import 'package:flutter/material.dart';
import 'app_theme.dart'; // Provides GlucoraColors

extension GlucoraColorsExt on BuildContext {
  GlucoraColors get colors => Theme.of(this).extension<GlucoraColors>()!;
}