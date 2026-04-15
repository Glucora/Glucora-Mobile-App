import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/models/admin_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart'; 
class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _roleFilter = 'All';

  List<AdminUser> _allUsers = [];
  bool _loading = true;
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email, role, is_active, created_at')
          .order('created_at', ascending: false);

      final users = (response as List)
          .map((row) => AdminUser.fromMap(row as Map<String, dynamic>))
          .toList();

      if (mounted) setState(() { _allUsers = users; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<AdminUser> get _filtered {
    return _allUsers.where((u) {
      if (_query.isNotEmpty &&
          !u.name.toLowerCase().contains(_query.toLowerCase()) &&
          !u.email.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      if (_roleFilter != 'All' && u.role != _roleFilter.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

Future<void> _deleteUser(AdminUser user) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const TranslatedText('Delete User'),
      content: TranslatedText('Are you sure you want to delete "${user.name}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const TranslatedText('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const TranslatedText('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final supabase = Supabase.instance.client;

  try {
    if (user.role == 'doctor') {
      try { await supabase.from('care_plans').delete().eq('doctor_id', user.id); } catch (_) {}
      try { await supabase.from('doctor_patient_connections').delete().eq('doctor_id', user.id); } catch (_) {}
      try { await supabase.from('doctor_profile').delete().eq('user_id', user.id); } catch (_) {}

    } else if (user.role == 'patient') {
      // Get bigint profile id for glucose/insulin
      try {
        final profileResponse = await supabase
            .from('patient_profile')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (profileResponse != null) {
          try { await supabase.from('glucose_readings').delete().eq('patient_id', profileResponse['id']); } catch (_) {}
          try { await supabase.from('insulin_doses').delete().eq('patient_id', profileResponse['id']); } catch (_) {}
        }
      } catch (_) {}

      try { await supabase.from('patient_profile').delete().eq('user_id', user.id); } catch (_) {}
      try { await supabase.from('guardian_patient_connections').delete().eq('patient_id', user.id); } catch (_) {}
      try { await supabase.from('doctor_patient_connections').delete().eq('patient_id', user.id); } catch (_) {}
      try { await supabase.from('patient_locations').delete().eq('patient_id', user.id); } catch (_) {}
      try { await supabase.from('devices').delete().eq('patient_id', user.id); } catch (_) {}

    } else if (user.role == 'guardian') {
      try { await supabase.from('guardian_patient_connections').delete().eq('guardian_id', user.id); } catch (_) {}

    } else if (user.role == 'norole' || user.role == 'admin') {
    }

    await supabase.from('users').delete().eq('id', user.id);

    if (mounted) {
      setState(() => _allUsers.removeWhere((u) => u.id == user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText('${user.name} deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  void _editUser(AdminUser user) {
    String selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: TranslatedText('Edit: ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'Email: ${user.email}',
                style: TextStyle(fontSize: 12, color: ctx.colors.textSecondary),
              ),
              const SizedBox(height: 16),
              TranslatedText(
                'Role',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ctx.colors.primaryDark),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: ['patient', 'doctor', 'guardian', 'admin']
                    .map((r) => DropdownMenuItem(value: r, child: TranslatedText(_roleLabel(r))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const TranslatedText('Active'),
                value: isActive,
                onChanged: (v) => setDialogState(() => isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const TranslatedText('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveUserEdits(user, selectedRole, isActive);
              },
              child: const TranslatedText('Save', style: TextStyle(color: Color(0xFF2BB6A3))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUserEdits(AdminUser user, String newRole, bool newActive) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole, 'is_active': newActive})
          .eq('id', user.id);

      setState(() {
        final index = _allUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _allUsers[index].role = newRole;
          _allUsers[index].isActive = newActive;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: TranslatedText('User updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
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
        title: const TranslatedText(
          'Users',
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
                hintText: 'Search by name or email…',
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
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Patient', 'Doctor', 'Admin', 'Guardian'].map((label) {
                final selected = _roleFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: TranslatedText(label, style: TextStyle(color: colors.textPrimary)),
                    selected: selected,
                    selectedColor: colors.accent.withValues(alpha: 0.2),
                    checkmarkColor: colors.accent,
                    onSelected: (_) => setState(() => _roleFilter = label),
                  ),
                );
              }).toList(),
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
                            TranslatedText('Failed to load users', style: TextStyle(color: colors.error)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _fetchUsers, child: const TranslatedText('Retry')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(child: TranslatedText('No users found', style: TextStyle(color: colors.textSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) => _userCard(context, filtered[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, AdminUser user) {
    final colors = context.colors;
    final roleColor = _roleColor(user.role);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _editUser(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: TranslatedText(
                  user.initials,
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      user.name,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(user.email, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TranslatedText(
                  user.roleLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor),
                ),
              ),
              const SizedBox(width: 4),
              if (!user.isActive)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TranslatedText('Inactive', style: TextStyle(fontSize: 10, color: colors.error)),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _deleteUser(user);
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

  Color _roleColor(String role) {
    switch (role) {
      case 'patient': return const Color(0xFF5B8CF5);
      case 'doctor': return const Color(0xFF9B59B6);
      case 'admin': return const Color(0xFFFF9F40);
      case 'guardian': return const Color(0xFF2BB6A3);
      default: return Colors.grey;
    }
  }
}