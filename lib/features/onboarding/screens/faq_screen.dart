import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int _expandedIndex = -1;

  final List<Map<String, dynamic>> _sections = [
    {
      'label': 'Getting Started',
      'color': Color(0xFF2BB6A3),
      'questions': [
        {
          'q': 'What is Glucora?',
          'a': 'Glucora is an AI-powered system that reads your glucose every 5 minutes, predicts where it is heading, and automatically delivers the right insulin dose — so you do not have to calculate anything manually.',
        },
        {
          'q': 'Who can use Glucora?',
          'a': 'Glucora is built for three types of users — patients managing their own diabetes, guardians (family or caregivers) monitoring a patient remotely, and doctors overseeing their patients\'s health data and settings.',
        },
        {
          'q': 'Do I need a doctor to activate Glucora?',
          'a': 'Yes. Connecting with a doctor is required before the system can be activated. Your doctor sets your target glucose range, sensitivity factor, and safe dose limits. Glucora is a medical device and must always be used under medical supervision.',
        },
        {
          'q': 'Can I add a guardian to my account?',
          'a': 'Yes. You can add one or more guardians who will see your glucose data and receive the same alerts you do in real time. Adding a guardian is optional but recommended, especially for younger patients.',
        },
        {
          'q': 'How do I charge the device?',
          'a': 'The device charges via USB. You will receive a low battery alert before it runs out so you always have time to charge it.',
        },
        {
          'q': 'Do I need to log what I eat?',
          'a': 'Yes. You enter your meal calories through the app before or after eating. This helps the system account for your carbohydrate intake when calculating your insulin dose.',
        },
      ],
    },
    {
      'label': 'How It Works',
      'color': Color(0xFF7C4DFF),
      'questions': [
        {
          'q': 'How does Glucora decide how much insulin to give me?',
          'a': 'It looks at your current glucose, where it is heading in the next 30 to 60 minutes, how far you are from your target range, your insulin sensitivity, and how much insulin is still active in your body — then calculates the smallest safe correction dose.',
        },
        {
          'q': 'What are the three safety checks?',
          'a': 'Before any dose is delivered, the system checks three things — is the dose within your personal safe limits, will it cause a predicted low, and is the sensor reading current and valid. All three must pass. If any one fails, the dose is rejected and you get an alert.',
        },
        {
          'q': 'What happens if the pump gets blocked?',
          'a': 'A pressure sensor monitors the infusion in real time. If a blockage or disconnection is detected during delivery, it stops immediately and sends you an urgent alert.',
        },
        {
          'q': 'What happens if my phone loses connection?',
          'a': 'The device works independently from your phone. Glucose monitoring and insulin delivery continue even without a connection. Your phone is used for viewing data and receiving notifications.',
        },
      ],
    },
    {
      'label': 'For Guardians',
      'color': Color(0xFF1976D2),
      'questions': [
        {
          'q': 'What can I see as a guardian?',
          'a': 'You have a dedicated view showing the patient\'s real-time glucose, active insulin, recent doses, and all alerts — synced live.',
        },
        {
          'q': 'Will I be notified if something goes wrong?',
          'a': 'Yes. You receive the same alerts as the patient — predicted highs or lows, hardware faults, missed doses, and any safety check failures.',
        },
        {
          'q': 'Can there be more than one guardian?',
          'a': 'Yes. A patient can add multiple guardians to their account, all of whom receive real-time data and alerts.',
        },
      ],
    },
    {
      'label': 'For Doctors',
      'color': Color(0xFF388E3C),
      'questions': [
        {
          'q': 'What patient data can I access?',
          'a': 'You have access to full glucose history, insulin delivery logs, prediction accuracy over time, alert history, and any safety events — all timestamped.',
        },
        {
          'q': 'Can I adjust a patient\'s settings?',
          'a': 'Yes. You can update a patient\'s target glucose range, insulin sensitivity factor, carbohydrate ratio, and maximum dose limits through the doctor view.',
        },
        {
          'q': 'How accurate are the predictions?',
          'a': 'The model forecasts glucose 30 and 60 minutes ahead. Each prediction includes a confidence score. The model was trained on multiple real patient datasets.',
        },
      ],
    },
    {
      'label': 'Safety & Security',
      'color': Color(0xFFD32F2F),
      'questions': [
        {
          'q': 'Can someone tamper with my doses remotely?',
          'a': 'The system monitors all data for unusual patterns. If anything looks inconsistent with your normal usage, it flags it as a potential threat, locks down, and alerts you immediately.',
        },
        {
          'q': 'Is my data secure?',
          'a': 'All data is encrypted in transit and at rest. Each role — patient, guardian, and doctor — only sees what is relevant to them.',
        },
        {
          'q': 'What if the sensor gives a wrong reading?',
          'a': 'Every reading is validated before being used. If a reading looks abnormal or is outdated, the system will not act on it and will notify you to check your sensor.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    final List<Map<String, dynamic>> items = [];
    int globalIndex = 0;
    for (final section in _sections) {
      items.add({'type': 'header', 'section': section});
      for (final q in (section['questions'] as List)) {
        items.add({
          'type': 'question',
          'section': section,
          'question': q,
          'index': globalIndex,
        });
        globalIndex++;
      }
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        'FAQs',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      TranslatedText(
                        'Everything you need to know.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: items.length + 1,
                itemBuilder: (context, i) {
                  if (i == items.length) return const SizedBox(height: 32);

                  final item = items[i];

                  if (item['type'] == 'header') {
                    final section = item['section'] as Map<String, dynamic>;
                    final sectionColor = section['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: sectionColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TranslatedText(
                            section['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: sectionColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final idx = item['index'] as int;
                  final q = item['question'] as Map<String, dynamic>;
                  final section = item['section'] as Map<String, dynamic>;
                  final isOpen = _expandedIndex == idx;
                  final accent = section['color'] as Color;

                  return GestureDetector(
                    onTap: () => setState(() => _expandedIndex = isOpen ? -1 : idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOpen
                              ? accent.withValues(alpha: 0.4)
                              : colors.textSecondary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TranslatedText(
                                    q['q'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isOpen
                                          ? accent
                                          : colors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isOpen
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: isOpen ? accent : colors.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                            if (isOpen) ...[
                              const SizedBox(height: 12),
                              Divider(height: 1, color: colors.textSecondary.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              TranslatedText(
                                q['a'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                  height: 1.65,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}