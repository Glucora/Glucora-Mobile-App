// =============================================================================
// AdminUserListScreen
// =============================================================================
// Displays all registered system users (patients, doctors, guardians, admins)
// with real-time search filtering and role-based chip filtering. The admin can
// edit a user's role / active status or permanently delete them.
//
// State split:
//   • User data (list, loading, error, totalUsers) lives in `adminUsersProvider`
//     (Riverpod) so it's shared and survives navigation.
//   • _query and _roleFilter are local widget state because they are purely
//     client-side UI concerns that never affect what's fetched from the server.
//
// Edit flow:
//   Tapping a user card opens an inline AlertDialog (no separate route) with
//   a role dropdown and an active-status toggle. This keeps the edit action
//   lightweight — it only changes two fields that don't need a full form.
//
// Delete flow:
//   Tapping the ⋮ menu → Delete shows a two-step confirmation dialog to
//   prevent accidental permanent deletions.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glucora_ai_companion/core/models/admin_model.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/providers/admin_riverpod_providers.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';

class AdminUserListScreen extends ConsumerStatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  ConsumerState<AdminUserListScreen> createState() =>
      _AdminUserListScreenState();
}

class _AdminUserListScreenState extends ConsumerState<AdminUserListScreen> {
  // Controller for the search text field; lets us call .clear() imperatively
  // from the X button without holding a reference to the field itself.
  final TextEditingController _searchController = TextEditingController();

  // The trimmed text currently typed in the search field.
  String _query = '';

  // The currently selected role filter chip value. 'All' disables filtering.
  // Values match the role strings stored in Supabase: 'Patient', 'Doctor',
  // 'Admin', 'Guardian' (capitalised for display, compared case-insensitively).
  String _roleFilter = 'All';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Load users after the first frame via microtask (safe Riverpod pattern).
    Future.microtask(() {
      if (!mounted) return;
      ref.read(adminUsersProvider.notifier).loadUsers();
    });
    // Listen to the controller so _query stays in sync without requiring the
    // TextField to call setState itself; onChanged would work too but this
    // ensures the query updates even when the text is changed programmatically.
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.trim()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filter logic ───────────────────────────────────────────────────────────

  /// Returns users that match BOTH the active search query AND the role chip.
  /// Both checks are case-insensitive. The result is used directly in the
  /// ListView — no caching needed at this scale.
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

  // ── Delete handler ─────────────────────────────────────────────────────────

  /// Two-step deletion: shows a confirmation dialog, then calls the provider
  /// notifier. On completion, reports success or error via a SnackBar.
  ///
  /// Both the role and ID are passed to the notifier so it can apply any
  /// role-specific cleanup logic (e.g. removing doctor–patient assignments).
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
              child: const TranslatedText('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const TranslatedText('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    // Guard: user cancelled, or widget unmounted while the dialog was open.
    if (confirmed != true || !mounted) return;

    await ref
        .read(adminUsersProvider.notifier)
        .deleteUser(user.id, user.role);

    if (mounted) {
      final error = ref.read(adminUsersProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TranslatedText(error ?? '${user.name} deleted'),
        backgroundColor: error != null ? Colors.red : Colors.green,
      ));
      if (error != null) ref.read(adminUsersProvider.notifier).clearError();
    }
  }

  // ── Edit handler ───────────────────────────────────────────────────────────

  /// Opens an in-place AlertDialog that lets the admin change the user's role
  /// (via a DropdownButtonFormField) and toggle their active status (via a
  /// SwitchListTile). Changes are applied only when the admin taps "Save".
  ///
  /// StatefulBuilder is used inside the dialog so the dropdown and switch can
  /// update independently without rebuilding the whole screen.
  void _editUser(AdminUser user) {
    // Local copies inside the dialog closure; don't mutate the original user
    // until the save is confirmed.
    String selectedRole = user.role;
    bool   isActive     = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: TranslatedText('Edit: ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read-only email reminder so the admin knows which account
              // they're editing (useful when the name is ambiguous).
              TranslatedText('Email: ${user.email}',
                  style: TextStyle(
                      fontSize: 12, color: ctx.colors.textSecondary)),
              const SizedBox(height: 16),

              // Role selector — enumerates all four system roles.
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
                  // setDialogState rebuilds only the dialog, not the whole
                  // screen, keeping the dropdown selection change snappy.
                  if (v != null) setDialogState(() => selectedRole = v);
                },
              ),
              const SizedBox(height: 12),

              // Active toggle — deactivating a user blocks their login without
              // permanently deleting their data.
              SwitchListTile(
                title:    const TranslatedText('Active'),
                value:    isActive,
                onChanged: (v) => setDialogState(() => isActive = v),
                contentPadding: EdgeInsets.zero, // Remove default left indent.
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const TranslatedText('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx); // Dismiss dialog before async work.
                await ref
                    .read(adminUsersProvider.notifier)
                    .updateUserRoleAndStatus(user.id, selectedRole, isActive);
                if (mounted) {
                  final error = ref.read(adminUsersProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: TranslatedText(error ?? 'User updated'),
                    backgroundColor: error != null ? Colors.red : Colors.green,
                  ));
                  if (error != null) {
                    ref.read(adminUsersProvider.notifier).clearError();
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

  // ── Visual helpers ─────────────────────────────────────────────────────────

  /// Converts a lowercase database role string into a human-readable label
  /// for display in the role dropdown and filter chips.
  String _roleLabel(String role) {
    switch (role) {
      case 'patient':  return 'Patient';
      case 'doctor':   return 'Doctor';
      case 'admin':    return 'Admin';
      case 'guardian': return 'Guardian';
      default:         return role; // Fallback for any unexpected role values.
    }
  }

  /// Each role is assigned a distinct colour used for the badge background/text
  /// in user cards and the filter chip selection highlight. Consistent colour
  /// coding means admins can recognise roles at a glance across the whole app.
  Color _roleColor(String role) {
    switch (role) {
      case 'patient':  return const Color(0xFF5B8CF5); // Blue
      case 'doctor':   return const Color(0xFF9B59B6); // Purple
      case 'admin':    return const Color(0xFFFF9F40); // Amber/orange
      case 'guardian': return const Color(0xFF2BB6A3); // Teal
      default:         return Colors.grey;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors   = context.colors;
    final state    = ref.watch(adminUsersProvider);
    final filtered = _filtered(state.users);

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Users',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: colors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon:     const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(adminUsersProvider.notifier).loadUsers(),
          ),
        ],
      ),
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:  'Search by name or email…',
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                // X button clears the field. Using .clear() on the controller
                // triggers the listener we set up in initState, which sets
                // _query = '' and rebuilds the filtered list.
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colors.textSecondary),
                        onPressed: () => _searchController.clear())
                    : null,
                filled:         true,
                fillColor:      colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:   BorderSide.none),
              ),
            ),
          ),

          // ── Role filter chips ─────────────────────────────────────────────
          // Horizontal scroll allows adding more roles in the future without
          // wrapping or shrinking the chip labels.
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Patient', 'Doctor', 'Admin', 'Guardian']
                  .map((label) {
                final selected = _roleFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: TranslatedText(label,
                        style: TextStyle(color: colors.textPrimary)),
                    selected: selected,
                    selectedColor: colors.accent.withValues(alpha: 0.2),
                    checkmarkColor: colors.accent,
                    onSelected: (_) =>
                        setState(() => _roleFilter = label),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // ── User list (or loading / error / empty states) ─────────────────
          Expanded(
            child: state.isLoading
                // Full-area spinner while data is fetching.
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    // Error state with clear error message and retry button.
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TranslatedText('Failed to load users',
                                style: TextStyle(color: colors.error)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Clear the stale error before retrying so
                                // the list rebuilds cleanly.
                                ref
                                    .read(adminUsersProvider.notifier)
                                    .clearError();
                                ref
                                    .read(adminUsersProvider.notifier)
                                    .loadUsers();
                              },
                              child: const TranslatedText('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        // Empty state — shows when either the data is truly
                        // empty or the search/filter returned no results.
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
                                _userCard(context, filtered[index]),
                          ),
          ),
        ],
      ),
    );
  }

  // ── User card ──────────────────────────────────────────────────────────────

  /// Builds a single user row card. Layout:
  ///   [avatar] | [name / email] | [role badge, inactive badge] | [⋮]
  ///
  /// The whole card is tappable (InkWell via onTap) to open the edit dialog,
  /// while the overflow menu (⋮) is the sole entry point for destructive
  /// actions, reducing the chance of accidental deletes.
  Widget _userCard(BuildContext context, AdminUser user) {
    final colors    = context.colors;
    final roleColor = _roleColor(user.role);

    return Material(
      color:        colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _editUser(user), // Tap anywhere on the card to edit.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ── Avatar ───────────────────────────────────────────────────
              // ProfilePicture shows the user's uploaded image if available,
              // or a coloured initials circle as a fallback. isEditable: false
              // means the admin cannot change this user's picture from here.
              ProfilePicture(
                userId:      user.id,
                imageUrl:    user.profilePictureUrl,
                size:        44,
                isEditable:  false,
                showInitials: true,
                displayName: user.name,
              ),

              const SizedBox(width: 12),

              // ── Name & email ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(user.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize:   15,
                            color:      colors.textPrimary)),
                    const SizedBox(height: 2),
                    TranslatedText(user.email,
                        style: TextStyle(
                            fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),

              // ── Role badge ────────────────────────────────────────────────
              // Uses roleLabel (from the AdminUser model) which may include
              // capitalisation / display formatting beyond the raw role string.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TranslatedText(user.roleLabel,
                    style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      roleColor)),
              ),

              // ── Inactive badge ────────────────────────────────────────────
              // Only shown for deactivated accounts; active is the default
              // state and needs no badge to avoid visual noise.
              if (!user.isActive)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:        colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TranslatedText('Inactive',
                      style: TextStyle(
                          fontSize: 10, color: colors.error)),
                ),

              // ── Overflow menu ─────────────────────────────────────────────
              // Isolated to destructive actions only; non-destructive edits
              // are accessible by tapping the card.
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') _deleteUser(user);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'delete',
                      child: TranslatedText('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}