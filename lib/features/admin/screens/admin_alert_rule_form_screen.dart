import 'package:flutter/material.dart';
import 'admin_models.dart';

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
    await Future.delayed(const Duration(milliseconds: 500));

    final threshold = _showThreshold
        ? double.tryParse(_thresholdController.text)
        : null;
    final duration = _showDuration
        ? int.tryParse(_durationController.text)
        : null;

    if (_isEditing) {
      widget.rule!.name = _nameController.text.trim();
      widget.rule!.conditionType = _conditionType;
      widget.rule!.thresholdValue = threshold;
      widget.rule!.durationMinutes = duration;
      widget.rule!.severity = _severity;
      widget.rule!.isEnabled = _isEnabled;
    } else {
      mockAlertRules.add(
        AdminAlertRule(
          id: 'ar${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          conditionType: _conditionType,
          thresholdValue: threshold,
          durationMinutes: duration,
          severity: _severity,
          isEnabled: _isEnabled,
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Alert Rule' : 'New Alert Rule',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1A7A6E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF4F7FA),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Rule Name'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('e.g. Critical High Glucose'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Condition Type'),
            DropdownButtonFormField<String>(
              initialValue: _conditionType,
              decoration: _inputDecoration('Select condition'),
              items: _conditionTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _conditionType = v);
              },
            ),
            if (_showThreshold) ...[
              const SizedBox(height: 16),
              _label(
                _conditionType == 'Time Out of Range'
                    ? 'Threshold (% time)'
                    : 'Threshold (mg/dL)',
              ),
              TextFormField(
                controller: _thresholdController,
                decoration: _inputDecoration(
                  _conditionType == 'Time Out of Range'
                      ? 'e.g. 30'
                      : 'e.g. 250',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            if (_showDuration) ...[
              const SizedBox(height: 16),
              _label('Duration (minutes)'),
              TextFormField(
                controller: _durationController,
                decoration: _inputDecoration('e.g. 30'),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 16),
            _label('Severity'),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: _inputDecoration('Select severity'),
              items: [
                'Critical',
                'Warning',
                'Info',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _severity = v);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enabled'),
              subtitle: Text(
                _isEnabled ? 'Rule is active' : 'Rule is disabled',
              ),
              value: _isEnabled,
              activeThumbColor: const Color(0xFF2BB6A3),
              onChanged: (v) => setState(() => _isEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2BB6A3),
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
                    : Text(
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A7A6E),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2BB6A3), width: 1.5),
      ),
    );
  }
}
