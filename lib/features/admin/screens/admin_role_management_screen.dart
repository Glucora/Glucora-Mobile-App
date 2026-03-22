import 'package:flutter/material.dart';
import 'admin_models.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class AdminRoleManagementScreen extends StatefulWidget {
  const AdminRoleManagementScreen({super.key});

  @override
  State<AdminRoleManagementScreen> createState() =>
      _AdminRoleManagementScreenState();
}

class _AdminRoleManagementScreenState extends State<AdminRoleManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<AdminUser> get _filtered {
    if (_query.isEmpty) return mockAdminUsers;
    return mockAdminUsers
        .where(
          (u) =>
              u.name.toLowerCase().contains(_query.toLowerCase()) ||
              u.email.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeRole(AdminUser user) {
    UserRole? newRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Change Role: ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<UserRole>(
                groupValue: newRole!,
                onChanged: (v) => setDialogState(() => newRole = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: UserRole.values.map((role) {
                    return RadioListTile<UserRole>(
                      title: Text(_roleName(role)),
                      value: role,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newRole != null) {
                  setState(() => user.role = newRole!);
                }
                Navigator.pop(ctx);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF2BB6A3)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return const Color(0xFF5B8CF5);
      case UserRole.doctor:
        return const Color(0xFF9B59B6);
      case UserRole.admin:
        return const Color(0xFFFF9F40);
    }
  }

  String _roleName(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Role Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: colors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users…',
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
          // Summary chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _countChip(
                  'Patients',
                  mockAdminUsers
                      .where((u) => u.role == UserRole.patient)
                      .length,
                  const Color(0xFF5B8CF5),
                ),
                const SizedBox(width: 8),
                _countChip(
                  'Doctors',
                  mockAdminUsers.where((u) => u.role == UserRole.doctor).length,
                  const Color(0xFF9B59B6),
                ),
                const SizedBox(width: 8),
                _countChip(
                  'Admins',
                  mockAdminUsers.where((u) => u.role == UserRole.admin).length,
                  const Color(0xFFFF9F40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No users found',
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
                        _userRoleCard(context, filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _userRoleCard(BuildContext context, AdminUser user) {
    final colors = context.colors;
    final color = _roleColor(user.role);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _changeRole(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 14, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}