import 'package:flutter/material.dart';
import 'admin_models.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/services/translated_text.dart'; // ← Add this import

class AdminDeviceFormScreen extends StatefulWidget {
  final AdminDevice? device;

  const AdminDeviceFormScreen({super.key, this.device});

  @override
  State<AdminDeviceFormScreen> createState() => _AdminDeviceFormScreenState();
}

class _AdminDeviceFormScreenState extends State<AdminDeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialController;
  late String _deviceType;
  late String _assignedToUserId;
  late bool _isActive;
  bool _saving = false;

  bool get _isEditing => widget.device != null;

  List<AdminUser> get _patients =>
      mockAdminUsers.where((u) => u.role == UserRole.patient).toList();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.device?.deviceName ?? '',
    );
    _modelController = TextEditingController(text: widget.device?.model ?? '');
    _serialController = TextEditingController(
      text: widget.device?.serialNumber ?? '',
    );
    _deviceType = widget.device?.deviceType ?? 'CGM';
    _assignedToUserId =
        widget.device?.assignedToUserId ??
        (_patients.isNotEmpty ? _patients.first.id : '');
    _isActive = widget.device?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final assignedUser = mockAdminUsers.firstWhere(
      (u) => u.id == _assignedToUserId,
    );

    if (_isEditing) {
      widget.device!.deviceName = _nameController.text.trim();
      widget.device!.model = _modelController.text.trim();
      widget.device!.serialNumber = _serialController.text.trim();
      widget.device!.deviceType = _deviceType;
      widget.device!.assignedToUserId = _assignedToUserId;
      widget.device!.assignedToUserName = assignedUser.name;
      widget.device!.isActive = _isActive;
    } else {
      mockAdminDevices.add(
        AdminDevice(
          id: 'dev${DateTime.now().millisecondsSinceEpoch}',
          deviceName: _nameController.text.trim(),
          deviceType: _deviceType,
          model: _modelController.text.trim(),
          serialNumber: _serialController.text.trim(),
          assignedToUserId: _assignedToUserId,
          assignedToUserName: assignedUser.name,
          isActive: _isActive,
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          _isEditing ? 'Edit Device' : 'Add Device',
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
            _label(context, 'Device Name'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(context, 'e.g. Dexcom G7 #4'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label(context, 'Device Type'),
            DropdownButtonFormField<String>(
              initialValue: _deviceType,
              decoration: _inputDecoration(context, 'Select type'),
              items: const [
                DropdownMenuItem(value: 'CGM', child: Text('CGM')),
                DropdownMenuItem(value: 'Micropump', child: Text('Micropump')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _deviceType = v);
              },
            ),
            const SizedBox(height: 16),
            _label(context, 'Model'),
            TextFormField(
              controller: _modelController,
              decoration: _inputDecoration(context, 'e.g. Dexcom G7'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label(context, 'Serial Number'),
            TextFormField(
              controller: _serialController,
              decoration: _inputDecoration(context, 'e.g. DX7-2025-0004'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label(context, 'Assigned To (Patient)'),
            DropdownButtonFormField<String>(
              initialValue: _assignedToUserId,
              decoration: _inputDecoration(context, 'Select patient'),
              items: _patients
                  .map(
                    (p) => DropdownMenuItem(value: p.id, child: TranslatedText(p.name)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _assignedToUserId = v);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const TranslatedText('Active'),
              subtitle: TranslatedText(
                _isActive ? 'Device is operating' : 'Device is deactivated',
              ),
              value: _isActive,
              activeThumbColor: colors.accent,
              onChanged: (v) => setState(() => _isActive = v),
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
                        _isEditing ? 'Save Changes' : 'Add Device',
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
      hintStyle: TextStyle(color: colors.textSecondary),
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