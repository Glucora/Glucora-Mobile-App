import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/screens/settings_screen.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';

/// Configuration model for a single FAQ entry.
class FaqEntry {
  final String question;
  final String answer;
  const FaqEntry(this.question, this.answer);
}

/// A reusable profile shell widget shared across Admin, Doctor, Guardian,
/// and Patient roles. Role-specific sections are injected via slots.
///
/// Usage:
/// ```dart
/// BaseProfileTab(
///   name: _name,
///   age: _age,
///   roleBadge: 'Administrator',        // optional — shown below age
///   infoCard: Column(...),             // your info rows/columns
///   faqs: [...],
///   onEditProfile: _editProfile,
///   onLogout: () => _showLogoutDialog(context),
///   profilePictureUrl: _profilePictureUrl,
///   notificationsEnabled: _notificationsEnabled,
///   onNotificationsChanged: (v) => setState(() => _notificationsEnabled = v),
///   extraSettingsWidgets: [...],       // optional — appended inside SettingsScreen
///   aboveLogout: [...],               // optional widgets before Logout button
/// )
/// ```
class BaseProfileTab extends StatefulWidget {
  final String name;
  final int age;

  /// Optional role badge shown below age (e.g. "Administrator").
  final String? roleBadge;

  final String profilePictureUrl;

  /// The info card widget (email, phone, address, etc.) shown below the avatar.
  final Widget infoCard;

  final List<FaqEntry> faqs;

  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  /// Called when the profile picture is tapped and changed — typically reloads data.
  final VoidCallback onPictureChanged;

  /// Extra widgets appended after the standard notification toggle inside SettingsScreen.
  final List<Widget> extraSettingsWidgets;

  /// Optional widgets inserted between the FAQs and the Logout button
  /// (e.g. "Switch to Guardian" button for patient, "Switch to Patient" for guardian).
  final List<Widget> aboveLogout;

  const BaseProfileTab({
    super.key,
    required this.name,
    required this.age,
    this.roleBadge,
    required this.profilePictureUrl,
    required this.infoCard,
    required this.faqs,
    required this.onEditProfile,
    required this.onLogout,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onPictureChanged,
    this.extraSettingsWidgets = const [],
    this.aboveLogout = const [],
  });

  @override
  State<BaseProfileTab> createState() => _BaseProfileTabState();
}

class _BaseProfileTabState extends State<BaseProfileTab> {
  int? _openFaqIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TranslatedText(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        notificationsEnabled: widget.notificationsEnabled,
                        onNotificationsChanged: widget.onNotificationsChanged,
                        additionalSettings: widget.extraSettingsWidgets,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Avatar + name + age + optional badge ────────────
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  ProfilePicture(
                    userId: userId,
                    imageUrl: widget.profilePictureUrl,
                    size: 90,
                    isEditable: true,
                    onPictureChanged: widget.onPictureChanged,
                    displayName: widget.name,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TranslatedText(
                        widget.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onEditProfile,
                        child: Icon(Icons.edit, size: 18, color: colors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    '${widget.age} years',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                  if (widget.roleBadge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TranslatedText(
                        widget.roleBadge!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Info card ────────────────────────────────────────
            const SizedBox(height: 24),
            widget.infoCard,

            // ── FAQs ─────────────────────────────────────────────
            const SizedBox(height: 24),
            TranslatedText(
              'FAQs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.faqs.asMap().entries.map(
              (e) => _faqItem(context, e.key, e.value.question, e.value.answer),
            ),

            // ── Role-specific widgets above logout ───────────────
            if (widget.aboveLogout.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...widget.aboveLogout,
            ],

            // ── Logout button ─────────────────────────────────────
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: widget.onLogout,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: TranslatedText(
                  'Log Out',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(BuildContext context, int index, String question, String answer) {
    final colors = context.colors;
    final isOpen = _openFaqIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _openFaqIndex = isOpen ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen
                ? colors.primary.withValues(alpha: 0.3)
                : colors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TranslatedText(
                    question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 10),
              TranslatedText(
                answer,
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared logout dialog — call this from any role profile tab.
void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent accidental dismissal during logout
    builder: (ctx) {
      final colors = context.colors;
      return AlertDialog(
        title: const TranslatedText('Log Out'),
        content: const TranslatedText('Are you sure to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: TranslatedText('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Store the original context before closing dialog
              final originalContext = context;
              
              // Close the dialog
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              
              // Small delay to ensure dialog is fully dismissed
              await Future.delayed(const Duration(milliseconds: 50));
              
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
                debugPrint('Sign out error: $e');
              }
              
              // Use the original context for navigation
              if (originalContext.mounted) {
                Navigator.of(originalContext).pushNamedAndRemoveUntil(
                  '/login-screen',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const TranslatedText('Logout'),
          ),
        ],
      );
    },
  );
}

/// Shared styled info card container — wraps your info rows/columns.
Widget buildInfoCard(BuildContext context, {required Widget child}) {
  final colors = context.colors;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: colors.textSecondary.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}