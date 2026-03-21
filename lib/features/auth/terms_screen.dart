import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Privacy',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This is a placeholder for the Terms of Service. '
                'In a real app, this would contain detailed legal terms about '
                'how your medical data is handled, stored, and shared.\n\n'
                'We take your privacy seriously and comply with all applicable '
                'health data regulations (e.g., HIPAA, GDPR). Your glucose '
                'readings and personal information will be encrypted and never '
                'shared without your explicit consent.\n\n',
                style: TextStyle(fontSize: 14, height: 1.5, color: colors.textSecondary),
              ),
              const SizedBox(height: 30),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'easrfewsfwsgfbkiwsygfbikseygrfsedrikygfergerg '
                'ceasrfewsfwsgfbkiwsygfbikseygrfsedrikygfergerg '
                'easrfewsfwsgfbkiwsygfbikseygrfsedrikygfergerg\n\n'
                'easrfewsfwsgfbkiwsygfbikseygrfsedrikygfergerg',
                style: TextStyle(fontSize: 14, height: 1.5, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}