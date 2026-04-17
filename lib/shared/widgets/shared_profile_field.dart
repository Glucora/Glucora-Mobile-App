import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

/// A reusable labeled text field used across all role edit-profile screens.
Widget buildProfileField(
  BuildContext context,
  String label,
  TextEditingController controller,
  IconData icon, {
  TextInputType keyboardType = TextInputType.text,
  String? suffix,
}) {
  final colors = context.colors;
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: TextStyle(color: colors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
      suffixText: suffix,
      suffixStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

/// A horizontal row showing icon + label + value, used in profile info cards.
Widget buildInfoRow(
  BuildContext context,
  IconData icon,
  String label,
  String value, {
  double labelWidth = 70,
}) {
  final colors = context.colors;
  return Row(
    children: [
      Icon(icon, size: 16, color: colors.primary),
      const SizedBox(width: 12),
      SizedBox(
        width: labelWidth,
        child: TranslatedText(
          label,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
      ),
      Expanded(
        child: TranslatedText(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
    ],
  );
}

/// A vertical label + value column, used in the guardian profile info card.
Widget buildInfoColumn(BuildContext context, String label, String value) {
  final colors = context.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TranslatedText(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
      const SizedBox(height: 4),
      TranslatedText(
        value,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
      ),
    ],
  );
}