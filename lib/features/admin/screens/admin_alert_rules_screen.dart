import 'package:flutter/material.dart';
import '../../../core/models/admin_model.dart';
import 'admin_alert_rule_form_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart'; // ← Add this import

class AdminAlertRulesScreen extends StatefulWidget {
  const AdminAlertRulesScreen({super.key});

  @override
  State<AdminAlertRulesScreen> createState() => _AdminAlertRulesScreenState();
}

class _AdminAlertRulesScreenState extends State<AdminAlertRulesScreen> {
  String _severityFilter = 'All';

  List<AdminAlertRule> get _filtered {
    if (_severityFilter == 'All') return mockAlertRules;
    return mockAlertRules.where((r) => r.severity == _severityFilter).toList();
  }

  void _deleteRule(AdminAlertRule rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Delete Alert Rule'),
        content: TranslatedText('Are you sure you want to delete "${rule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TranslatedText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => mockAlertRules.remove(rule));
              Navigator.pop(ctx);
            },
            child: const TranslatedText('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFFD32F2F);
      case 'Warning':
        return const Color(0xFFFF9F40);
      case 'Info':
        return const Color(0xFF5B8CF5);
      default:
        return Colors.grey;
    }
  }

  IconData _conditionIcon(String conditionType) {
    switch (conditionType) {
      case 'Glucose High':
        return Icons.arrow_upward;
      case 'Glucose Low':
        return Icons.arrow_downward;
      case 'Sensor Disconnect':
        return Icons.sensors_off;
      case 'Pump Failure':
        return Icons.warning_amber;
      case 'Missed Dose':
        return Icons.schedule;
      case 'Time Out of Range':
        return Icons.timer;
      default:
        return Icons.rule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText(
          'Alert Rules',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAlertRuleFormScreen(),
                ),
              );
              if (result == true) setState(() {});
            },
          ),
        ],
      ),
      backgroundColor: colors.background,
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', 'Critical', 'Warning', 'Info'].map((label) {
                final selected = _severityFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: TranslatedText(label, style: TextStyle(color: colors.textPrimary)),
                    selected: selected,
                    selectedColor: colors.accent.withValues(alpha: 0.2),
                    checkmarkColor: colors.accent,
                    onSelected: (_) => setState(() => _severityFilter = label),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: TranslatedText(
                      'No alert rules',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, a2) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _ruleCard(context, filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _ruleCard(BuildContext context, AdminAlertRule rule) {
    final colors = context.colors;
    final color = _severityColor(rule.severity);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AdminAlertRuleFormScreen(rule: rule),
            ),
          );
          if (result == true) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _conditionIcon(rule.conditionType),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      rule.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      _ruleDescription(rule),
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TranslatedText(
                      rule.severity,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Switch(
                    value: rule.isEnabled,
                    activeThumbColor: colors.accent,
                    onChanged: (v) => setState(() => rule.isEnabled = v),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _deleteRule(rule);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: TranslatedText('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ruleDescription(AdminAlertRule rule) {
    final parts = <String>[];
    parts.add(rule.conditionType);
    if (rule.thresholdValue != null) {
      parts.add('Threshold: ${rule.thresholdValue!.toInt()} mg/dL');
    }
    if (rule.durationMinutes != null) {
      parts.add('Duration: ${rule.durationMinutes} min');
    }
    return parts.join('  •  ');
  }
}