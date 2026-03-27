import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_models.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

class AdminRoleManagementScreen extends StatefulWidget {
  const AdminRoleManagementScreen({super.key});

  @override
  State<AdminRoleManagementScreen> createState() => _AdminRoleManagementScreenState();
}

class _AdminRoleManagementScreenState extends State<AdminRoleManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<AdminUser> _allUsers = [];
  bool _loading = true;
  String? _error;

  static const _roles = ['patient', 'doctor', 'guardian', 'admin'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email, role, is_active, created_at')
          .order('full_name');

      final users = (response as List)
          .map((row) => AdminUser.fromMap(row as Map<String, dynamic>))
          .toList();

      if (mounted) setState(() { _allUsers = users; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<AdminUser> get _filtered {
    if (_query.isEmpty) return _allUsers;
    return _allUsers.where(
      (u) =>
          u.name.toLowerCase().contains(_query.toLowerCase()) ||
          u.email.toLowerCase().contains(_query.toLowerCase()),
    ).toList();
  }

  void _changeRole(AdminUser user) {
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Change Role: ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _roles.map((role) {
              return RadioListTile<String>(
                title: Text(_roleLabel(role)),
                value: role,
                groupValue: selectedRole,
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveRole(user, selectedRole);
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFF2BB6A3))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRole(AdminUser user, String newRole) async {
    if (newRole == user.role) return;

    // Optimistically update UI
    setState(() {
      final index = _allUsers.indexWhere((u) => u.id == user.id);
      if (index != -1) _allUsers[index].role = newRole;
    });

    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole})
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} is now ${_roleLabel(newRole)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Revert on failure
      setState(() {
        final index = _allUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) _allUsers[index].role = user.role;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'patient':
        return const Color(0xFF5B8CF5);
      case 'doctor':
        return const Color(0xFF9B59B6);
      case 'admin':
        return const Color(0xFFFF9F40);
      case 'guardian':
        return const Color(0xFF2BB6A3);
      default:
        return Colors.grey;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'patient': return 'Patient';
      case 'doctor': return 'Doctor';
      case 'admin': return 'Admin';
      case 'guardian': return 'Guardian';
      default: return role;
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Summary chips
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _countChip('Patients', _allUsers.where((u) => u.role == 'patient').length, const Color(0xFF5B8CF5)),
                  const SizedBox(width: 8),
                  _countChip('Doctors', _allUsers.where((u) => u.role == 'doctor').length, const Color(0xFF9B59B6)),
                  const SizedBox(width: 8),
                  _countChip('Admins', _allUsers.where((u) => u.role == 'admin').length, const Color(0xFFFF9F40)),
                  const SizedBox(width: 8),
                  _countChip('Guardians', _allUsers.where((u) => u.role == 'guardian').length, const Color(0xFF2BB6A3)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Failed to load users', style: TextStyle(color: colors.error)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _fetchUsers, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(child: Text('No users found', style: TextStyle(color: colors.textSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) => _userRoleCard(context, filtered[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(user.email, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.roleLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
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