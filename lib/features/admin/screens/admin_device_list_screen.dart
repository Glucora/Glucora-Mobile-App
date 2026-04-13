import 'package:flutter/material.dart';
import '../../../core/models/admin_model.dart';
import 'admin_device_form_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart'; // ← Add this import

class AdminDeviceListScreen extends StatefulWidget {
  const AdminDeviceListScreen({super.key});

  @override
  State<AdminDeviceListScreen> createState() => _AdminDeviceListScreenState();
}

class _AdminDeviceListScreenState extends State<AdminDeviceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _typeFilter = 'All';

  List<AdminDevice> get _filtered {
    return mockAdminDevices.where((d) {
      if (_query.isNotEmpty &&
          !d.deviceName.toLowerCase().contains(_query.toLowerCase()) &&
          !d.assignedToUserName.toLowerCase().contains(_query.toLowerCase()) &&
          !d.serialNumber.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      if (_typeFilter == 'CGM' && d.deviceType != 'CGM') return false;
      if (_typeFilter == 'Micropump' && d.deviceType != 'Micropump') {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteDevice(AdminDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Delete Device'),
        content: TranslatedText(
          'Are you sure you want to delete "${device.deviceName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TranslatedText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => mockAdminDevices.remove(device));
              Navigator.pop(ctx);
            },
            child: const TranslatedText('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText(
          'Devices',
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
                  builder: (_) => const AdminDeviceFormScreen(),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, serial, or user…',
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'CGM', 'Micropump'].map((label) {
                final selected = _typeFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: TranslatedText(label, style: TextStyle(color: colors.textPrimary)),
                    selected: selected,
                    selectedColor: colors.accent.withValues(alpha: 0.2),
                    checkmarkColor: colors.accent,
                    onSelected: (_) => setState(() => _typeFilter = label),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: TranslatedText(
                      'No devices found',
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
                    itemBuilder: (context, index) =>
                        _deviceCard(context, filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard(BuildContext context, AdminDevice device) {
    final colors = context.colors;
    final isCGM = device.deviceType == 'CGM';
    final color = isCGM ? colors.accent : const Color(0xFF9B59B6);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDeviceFormScreen(device: device),
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
                  isCGM ? Icons.sensors : Icons.medical_services,
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
                      device.deviceName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      '${device.model}  •  ${device.serialNumber}',
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      'Assigned to: ${device.assignedToUserName}',
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
                      device.deviceType,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!device.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TranslatedText(
                        'Inactive',
                        style: TextStyle(fontSize: 10, color: colors.error),
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _deleteDevice(device);
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
}