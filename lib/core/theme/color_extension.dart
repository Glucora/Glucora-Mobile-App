import 'package:flutter/material.dart';
import 'app_theme.dart'; 

extension GlucoraColorsExt on BuildContext {
  GlucoraColors get colors => Theme.of(this).extension<GlucoraColors>()!;
}