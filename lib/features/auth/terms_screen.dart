import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms & Privacy',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'This is a placeholder for the Terms of Service. '
                'In a real app, this would contain detailed legal terms about '
                'how your medical data is handled, stored, and shared.\n\n'
                'We take your privacy seriously and comply with all applicable '
                'health data regulations (e.g., HIPAA, GDPR). Your glucose '
                'readings and personal information will be encrypted and never '
                'shared without your explicit consent.\n\n',
                style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF555555)),
              ),
              SizedBox(height: 30),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'easrfewsfwsgfbkiwsygfbikseygrfsedrikygfergerg '
                'ceasrfewsfwsgfbkiwsygfbikseygrfsedrikygfergerg '
                'easrfewsfwsgfbkiwsygfbikseygrfsedrikygfergerg\n\n'
                'easrfewsfwsgfbkiwsygfbikseygrfsedrikygfergerg',
                style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF555555)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}