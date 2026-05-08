import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'nav_tab_item.dart';

// ─────────────────────────────────────────────────────────────
// NavTile  (Stateless Presentational Widget)
//
// Renders a single icon + label inside the bottom nav bar.
// All visual logic lives here; the parent only passes data.
// ─────────────────────────────────────────────────────────────
class NavTile extends StatelessWidget {
  final NavTabItem item;
  final bool active;
  final VoidCallback onTap;

  const NavTile({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.primary : colors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(height: 3),
            TranslatedText(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            // Active indicator dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? colors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
