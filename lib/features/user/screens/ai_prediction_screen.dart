import 'package:flutter/material.dart';

class AIPredictionScreen extends StatelessWidget {
  const AIPredictionScreen({super.key});

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
          "AI Prediction",
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
            // ── Summary Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3FDF7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF199A8E), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Predicted in 30 minutes",
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        "135",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        " mg/dL",
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward,
                          color: Color(0xFFEF1616), size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        "22.73% rise expected",
                        style: TextStyle(
                            color: Color(0xFFEF1616),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Prediction Details",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 14),

            _detailRow("Current Level", "110 mg/dL", const Color(0xFF199A8E)),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow("Predicted (30 min)", "135 mg/dL",
                const Color(0xFFEF1616)),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow("Trend", "Rising", const Color(0xFFEFDD16)),
            const Divider(height: 24, color: Color(0xFFEEEEEE)),
            _detailRow("Last Reading",
                "10:21pm · 15 Jan, 2026", const Color(0xFF888888)),

            const SizedBox(height: 28),

            const Text(
              "What this means",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 10),

            _infoCard(
              Icons.info_outline_rounded,
              "Your glucose is predicted to rise by 25 mg/dL in the next 30 minutes. "
                  "Consider reducing carbohydrate intake and staying active.",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ],
    );
  }

  Widget _infoCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF199A8E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}