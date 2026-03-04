import 'package:flutter/material.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  static const _items = [
    _RecItem(
      icon: Icons.no_food_rounded,
      title: "Avoid high-carbohydrate meals",
      subtitle:
          "High carbs can spike your glucose. Opt for proteins and vegetables instead.",
      color: Color(0xFFEF1616),
    ),
    _RecItem(
      icon: Icons.directions_walk_rounded,
      title: "Take a short walk",
      subtitle:
          "Even 10–15 minutes of light walking helps lower blood sugar levels.",
      color: Color(0xFF199A8E),
    ),
    _RecItem(
      icon: Icons.loop_rounded,
      title: "Recheck glucose in 30 minutes",
      subtitle:
          "Monitor your levels after 30 minutes to track the predicted rise.",
      color: Color(0xFFEFDD16),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E), size: 20),
        ),
        title: const Text(
          "Recommendations",
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Based on your current glucose level of 110 mg/dL and the predicted rise, here's what we suggest:",
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[600], height: 1.5),
            ),

            const SizedBox(height: 20),

            ..._items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _recCard(item),
                )),

            const SizedBox(height: 10),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Recommendations are supportive and not a medical diagnosis. Always consult your healthcare provider.",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _recCard(_RecItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _RecItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color});
}