import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/translated_text.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const TranslatedText(
          'Terms & Privacy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, "Terms of Service"),

            _sectionText(
              context,
              "By using Glucora AI Companion, you agree to use the app responsibly "
              "for personal health monitoring and management purposes only.\n\n"
              "The app provides AI-assisted insights and does not replace professional medical advice. "
              "Always consult a licensed healthcare provider for medical decisions.\n\n"
              "We reserve the right to update or modify these terms at any time to improve safety, "
              "compliance, and user experience.",
            ),

            const SizedBox(height: 24),

            _sectionTitle(context, "Medical Disclaimer"),

            _sectionText(
              context,
              "Glucora AI Companion is a supportive health tool designed to help users track glucose trends. "
              "It does not provide diagnoses or emergency medical services.\n\n"
              "In case of critical readings or symptoms, seek immediate medical attention.",
            ),

            const SizedBox(height: 24),

            _sectionTitle(context, "Privacy Policy"),

            _sectionText(
              context,
              "We respect your privacy and are committed to protecting your personal health data.\n\n"
              "• Your data is encrypted and securely stored\n"
              "• Data is only shared with your connected doctors or guardians\n"
              "• We do not sell or share your personal data with third parties\n"
              "• You can request deletion of your data at any time\n\n"
              "We follow industry-standard security practices and comply with applicable data protection laws.",
            ),

            const SizedBox(height: 24),

            _sectionTitle(context, "Data Usage"),

            _sectionText(
              context,
              "We use your data only to:\n"
              "• Provide glucose monitoring insights\n"
              "• Improve AI predictions\n"
              "• Enable doctor and guardian connectivity\n"
              "• Enhance app performance and safety",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final colors = context.colors;

    return TranslatedText(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _sectionText(BuildContext context, String text) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TranslatedText(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}