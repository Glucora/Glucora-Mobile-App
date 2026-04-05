import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/shared/connection_requests_screen.dart';

class GuardianRequestsScreen extends StatelessWidget {
  const GuardianRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConnectionRequestsScreen(role: 'guardian');
  }
}