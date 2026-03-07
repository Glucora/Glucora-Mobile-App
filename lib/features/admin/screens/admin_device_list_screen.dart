import 'package:flutter/material.dart';
import 'admin_models.dart';
import 'admin_device_form_screen.dart';

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
      if (_typeFilter == 'Micropump' && d.deviceType != 'Micropump')
        return false;
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
        title: const Text('Delete Device'),
        content: Text(
          'Are you sure you want to delete "${device.deviceName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => mockAdminDevices.remove(device));
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Devices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A7A6E),
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
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, serial, or user…',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
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
                    label: Text(label),
                    selected: selected,
                    selectedColor: const Color(
                      0xFF2BB6A3,
                    ).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF2BB6A3),
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
                    child: Text(
                      'No devices found',
                      style: TextStyle(color: Colors.grey[500]),
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
                        _deviceCard(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard(AdminDevice device) {
    final isCGM = device.deviceType == 'CGM';
    final color = isCGM ? const Color(0xFF2BB6A3) : const Color(0xFF9B59B6);

    return Material(
      color: Colors.white,
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
                    Text(
                      device.deviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device.model}  •  ${device.serialNumber}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Assigned to: ${device.assignedToUserName}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                    child: Text(
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
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(fontSize: 10, color: Colors.red),
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
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
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
