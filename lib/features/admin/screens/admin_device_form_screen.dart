import 'package:flutter/material.dart';
import 'admin_models.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Device' : 'Add Device',
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
            _label('Device Name'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('e.g. Dexcom G7 #4'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Device Type'),
            DropdownButtonFormField<String>(
              initialValue: _deviceType,
              decoration: _inputDecoration('Select type'),
              items: const [
                DropdownMenuItem(value: 'CGM', child: Text('CGM')),
                DropdownMenuItem(value: 'Micropump', child: Text('Micropump')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _deviceType = v);
              },
            ),
            const SizedBox(height: 16),
            _label('Model'),
            TextFormField(
              controller: _modelController,
              decoration: _inputDecoration('e.g. Dexcom G7'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Serial Number'),
            TextFormField(
              controller: _serialController,
              decoration: _inputDecoration('e.g. DX7-2025-0004'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Assigned To (Patient)'),
            DropdownButtonFormField<String>(
              initialValue: _assignedToUserId,
              decoration: _inputDecoration('Select patient'),
              items: _patients
                  .map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _assignedToUserId = v);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: Text(
                _isActive ? 'Device is operating' : 'Device is deactivated',
              ),
              value: _isActive,
              activeThumbColor: const Color(0xFF2BB6A3),
              onChanged: (v) => setState(() => _isActive = v),
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
