import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/theme_provider.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/setting_switch_tile.dart';
import 'package:glucora_ai_companion/shared/widgets/settings_navigation_tile.dart';
import 'package:glucora_ai_companion/shared/widgets/delete_account_tile.dart';
import 'package:glucora_ai_companion/shared/screens/language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final List<Widget>? additionalSettings;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onLogout,
    this.additionalSettings,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        // ✅ Add LayoutBuilder to get constraints
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // ✅ Force scrollable
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Roaa
           /*          SettingsSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Receive system alerts and updates',
                      color: colors.primary,
                      value: _notifications,
                      onChanged: (val) {
                        setState(() => _notifications = val);
                        widget.onNotificationsChanged(_notifications);
                      },
                    ),
                    const SizedBox(height: 16), */
                    SettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'Switch to dark theme',
                      color: const Color(0xFF5B8CF5),
                      value: isDarkMode,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                    const SizedBox(height: 16),
                    SettingsNavigationTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'Choose your preferred language',
                      color: const Color(0xFF2BB6A3),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LanguageSelectionScreen(),
                          ),
                        );
                      },
                    ),
                    // Additional settings from patient/doctor/guardian
                    if (widget.additionalSettings != null) ...[
                      const SizedBox(height: 16),
                      ...widget.additionalSettings!,
                    ],
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: widget.onLogout,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.textSecondary.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.logout_rounded,
                                color: colors.error,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TranslatedText(
                                    'Log Out',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  TranslatedText(
                                    'Sign out of your account',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.error,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const DeleteAccountTile(),
                    const SizedBox(height: 32), // ✅ Extra padding at bottom
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
