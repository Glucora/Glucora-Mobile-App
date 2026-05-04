import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/models/admin_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/providers/admin_provider.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _roleFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminProvider>().loadUsers());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim());
  }

  List<AdminUser> _filtered(List<AdminUser> users) {
    return users.where((u) {
      final matchesQuery = _query.isEmpty ||
          u.name.toLowerCase().contains(_query.toLowerCase()) ||
          u.email.toLowerCase().contains(_query.toLowerCase());
      final matchesRole = _roleFilter == 'All' ||
          u.role.toLowerCase() == _roleFilter.toLowerCase();
      return matchesQuery && matchesRole;
    }).toList();
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Delete User'),
        content: TranslatedText(
            'Are you sure you want to delete "${user.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const TranslatedText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const TranslatedText('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<AdminProvider>().deleteUser(user.id, user.role);

    if (mounted) {
      final error = context.read<AdminProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText(error ?? '${user.name} deleted'),
          backgroundColor: error != null ? Colors.red : Colors.green,
        ),
      );
      if (error != null) context.read<AdminProvider>().clearError();
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
                style: TextStyle(
                    fontSize: 12, color: ctx.colors.textSecondary),
              ),
              const SizedBox(height: 16),
              TranslatedText('Role',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ctx.colors.primaryDark)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: ['patient', 'doctor', 'guardian', 'admin']
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: TranslatedText(_roleLabel(r))))
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
                await context
                    .read<AdminProvider>()
                    .updateUserRoleAndStatus(user.id, selectedRole, isActive);
                if (mounted) {
                  final error =
                      context.read<AdminProvider>().errorMessage;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          TranslatedText(error ?? 'User updated'),
                      backgroundColor:
                          error != null ? Colors.red : Colors.green,
                    ),
                  );
                  if (error != null) {
                    context.read<AdminProvider>().clearError();
                  }
                }
              },
              child: const TranslatedText('Save',
                  style: TextStyle(color: Color(0xFF2BB6A3))),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'patient': return 'Patient';
      case 'doctor':  return 'Doctor';
      case 'admin':   return 'Admin';
      case 'guardian': return 'Guardian';
      default:        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'patient':  return const Color(0xFF5B8CF5);
      case 'doctor':   return const Color(0xFF9B59B6);
      case 'admin':    return const Color(0xFFFF9F40);
      case 'guardian': return const Color(0xFF2BB6A3);
      default:         return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final filtered = _filtered(provider.users);

        return Scaffold(
          appBar: AppBar(
            title: const TranslatedText('Users',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: colors.primaryDark,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadUsers(),
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
                    hintText: 'Search by name or email…',
                    hintStyle:
                        TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(Icons.search,
                        color: colors.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: colors.textSecondary),
                            onPressed: () =>
                                _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    'All',
                    'Patient',
                    'Doctor',
                    'Admin',
                    'Guardian'
                  ].map((label) {
                    final selected = _roleFilter == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: TranslatedText(label,
                            style: TextStyle(
                                color: colors.textPrimary)),
                        selected: selected,
                        selectedColor:
                            colors.accent.withValues(alpha: 0.2),
                        checkmarkColor: colors.accent,
                        onSelected: (_) =>
                            setState(() => _roleFilter = label),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TranslatedText('Failed to load users',
                                    style: TextStyle(
                                        color: colors.error)),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    provider.clearError();
                                    provider.loadUsers();
                                  },
                                  child:
                                      const TranslatedText('Retry'),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: TranslatedText('No users found',
                                    style: TextStyle(
                                        color: colors.textSecondary)))
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) =>
                                    _userCard(
                                        context, filtered[index]),
                              ),
              ),
            ],
          ),
        );
      },
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
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ProfilePicture(
                userId: user.id,
                imageUrl: user.profilePictureUrl,
                size: 44,
                isEditable: false,
                showInitials: true,
                displayName: user.name,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(user.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    TranslatedText(user.email,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TranslatedText(user.roleLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: roleColor)),
              ),
              const SizedBox(width: 4),
              if (!user.isActive)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TranslatedText('Inactive',
                      style:
                          TextStyle(fontSize: 10, color: colors.error)),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _deleteUser(user);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: TranslatedText('Delete',
                        style: TextStyle(color: Colors.red)),
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