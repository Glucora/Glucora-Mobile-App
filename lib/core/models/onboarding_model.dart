import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.color,
  });
}

final List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    title: 'Track Your Glucose',
    description: 'Easily log your blood glucose readings and track patterns over time',
    imagePath: 'assets/images/onboarding/glucose_track.png',
    color: const Color(0xFF2BB6A3),
  ),
  OnboardingPage(
    title: 'AI Predictions',
    description: 'Get personalized predictions for your glucose levels using advanced AI',
    imagePath: 'assets/images/onboarding/ai_predict.png',
    color: const Color(0xFF4A90E2),
  ),
  OnboardingPage(
    title: 'Smart Recommendations',
    description: 'Receive personalized diet and lifestyle recommendations',
    imagePath: 'assets/images/onboarding/recommendations.png',
    color: const Color(0xFFE24A4A),
  ),
  OnboardingPage(
    title: 'Connect with Care Team',
    description: 'Share your data with doctors and guardians for better care',
    imagePath: 'assets/images/onboarding/connect.png',
    color: const Color(0xFF9B59B6),
  ),
];