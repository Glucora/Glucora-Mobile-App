import 'package:flutter/material.dart';
import '../../../core/models/admin_model.dart';
import '../../../services/admin_service.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

class AdminAlertRuleFormScreen extends StatefulWidget {
  final AdminAlertRule? rule;

  const AdminAlertRuleFormScreen({super.key, this.rule});

  @override
  State<AdminAlertRuleFormScreen> createState() =>
      _AdminAlertRuleFormScreenState();
}

class _AdminAlertRuleFormScreenState extends State<AdminAlertRuleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _durationController;
  late String _conditionType;
  late String _severity;
  late bool _isEnabled;
  bool _saving = false;

  bool get _isEditing => widget.rule != null;

  static const _conditionTypes = [
    'Glucose High',
    'Glucose Low',
    'Sensor Disconnect',
    'Pump Failure',
    'Missed Dose',
    'Time Out of Range',
  ];

  bool get _showThreshold =>
      _conditionType == 'Glucose High' ||
      _conditionType == 'Glucose Low' ||
      _conditionType == 'Time Out of Range';
  bool get _showDuration => _conditionType != 'Pump Failure';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name ?? '');
    _thresholdController = TextEditingController(
      text: widget.rule?.thresholdValue?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.rule?.durationMinutes?.toString() ?? '',
    );
    _conditionType = widget.rule?.conditionType ?? _conditionTypes.first;
    _severity = widget.rule?.severity ?? 'Warning';
    _isEnabled = widget.rule?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thresholdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final threshold = _showThreshold
        ? double.tryParse(_thresholdController.text)
        : null;
    final duration = _showDuration
        ? int.tryParse(_durationController.text)
        : null;

    bool success = false;

    if (_isEditing) {
      // Update existing rule
      final updatedRule = AdminAlertRule(
        id: widget.rule!.id,
        name: _nameController.text.trim(),
        conditionType: _conditionType,
        thresholdValue: threshold,
        durationMinutes: duration,
        severity: _severity,
        isEnabled: _isEnabled,
        appliesToRole: widget.rule!.appliesToRole,
      );
      success = await AdminService.updateAlertRule(updatedRule);
    } else {
      // Create new rule
      final newRule = AdminAlertRule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        conditionType: _conditionType,
        thresholdValue: threshold,
        durationMinutes: duration,
        severity: _severity,
        isEnabled: _isEnabled,
        appliesToRole: 'All Patients',
      );
      success = await AdminService.addAlertRule(newRule);
    }

    if (mounted) {
      setState(() => _saving = false);
      
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText(
              _isEditing ? 'Rule updated successfully!' : 'Rule created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Failed to save rule. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          _isEditing ? 'Edit Alert Rule' : 'New Alert Rule',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: colors.background,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(context, 'Rule Name'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(context, 'e.g. Critical High Glucose'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label(context, 'Condition Type'),
            DropdownButtonFormField<String>(
              initialValue: _conditionType,
              decoration: _inputDecoration(context, 'Select condition'),
              items: _conditionTypes
                  .map((t) => DropdownMenuItem(value: t, child: TranslatedText(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _conditionType = v);
              },
            ),
            if (_showThreshold) ...[
              const SizedBox(height: 16),
              _label(
                context,
                _conditionType == 'Time Out of Range'
                    ? 'Threshold (% time)'
                    : 'Threshold (mg/dL)',
              ),
              TextFormField(
                controller: _thresholdController,
                decoration: _inputDecoration(
                  context,
                  _conditionType == 'Time Out of Range'
                      ? 'e.g. 30'
                      : 'e.g. 250',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            if (_showDuration) ...[
              const SizedBox(height: 16),
              _label(context, 'Duration (minutes)'),
              TextFormField(
                controller: _durationController,
                decoration: _inputDecoration(context, 'e.g. 30'),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 16),
            _label(context, 'Severity'),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: _inputDecoration(context, 'Select severity'),
              items: [
                'Critical',
                'Warning',
                'Info',
              ].map((s) => DropdownMenuItem(value: s, child: TranslatedText(s))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _severity = v);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: TranslatedText('Enabled', style: TextStyle(color: colors.textPrimary)),
              subtitle: TranslatedText(
                _isEnabled ? 'Rule is active' : 'Rule is disabled',
                style: TextStyle(color: colors.textSecondary),
              ),
              value: _isEnabled,
              activeThumbColor: colors.accent,
              onChanged: (v) => setState(() => _isEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : TranslatedText(
                        _isEditing ? 'Save Changes' : 'Create Rule',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TranslatedText(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.primaryDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.textSecondary.withValues(alpha:0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.textSecondary.withValues(alpha:0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.accent, width: 1.5),
      ),
    );
  }
}