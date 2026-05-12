// lib/shared/screens/connection_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';

final supabase = Supabase.instance.client;

// ─── CONFIG PER ROLE ─────────────────────────────────────────────────────────

class _RoleConfig {
  final String profileIdField;
  final String connectionsTable;
  final String requestedByValue;

  const _RoleConfig({
    required this.profileIdField,
    required this.connectionsTable,
    required this.requestedByValue,
  });

  factory _RoleConfig.forRole(String role) {
    switch (role) {
      case 'doctor':
        return const _RoleConfig(
          profileIdField: 'doctor_id',
          connectionsTable: 'doctor_patient_connections',
          requestedByValue: 'doctor',
        );
      case 'guardian':
        return const _RoleConfig(
          profileIdField: 'guardian_id',
          connectionsTable: 'guardian_patient_connections',
          requestedByValue: 'guardian',
        );
      case 'patient':
        return const _RoleConfig(
          profileIdField: 'patient_id',
          connectionsTable: 'doctor_patient_connections',
          requestedByValue: 'patient',
        );
      default:
        throw Exception('Unknown role: $role');
    }
  }
}

// ─── MODELS ──────────────────────────────────────────────────────────────────

enum RequestStatus { pending, accepted, declined }

class ConnectionRequest {
  final String id;
  final String personName;
  final String personId;
  final String sentAgo;
  final String avatarInitials;
  final String? profilePictureUrl;
  final String requestedBy;
  final String sourceTable;
  final String? personRole;
  RequestStatus status;

  ConnectionRequest({
    required this.id,
    required this.personName,
    required this.personId,
    required this.sentAgo,
    required this.avatarInitials,
    this.profilePictureUrl,
    required this.requestedBy,
    required this.sourceTable,
    this.personRole,
    this.status = RequestStatus.pending,
  });
}

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class ConnectionRequestsScreen extends StatefulWidget {
  final String role;
  final void Function(int count)? onIncomingCountChanged;

  const ConnectionRequestsScreen({
    super.key,
    required this.role,
    this.onIncomingCountChanged,
  });

  @override
  State<ConnectionRequestsScreen> createState() =>
      _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late _RoleConfig _config;
  List<ConnectionRequest> _requests = [];
  bool _isLoading = true;
  int _refreshTabs = 0;

  List<ConnectionRequest> get _incoming => _requests
      .where((r) =>
          r.requestedBy != widget.role && r.status == RequestStatus.pending)
      .toList();

  List<ConnectionRequest> get _sent => _requests
      .where((r) =>
          r.requestedBy == widget.role && r.status == RequestStatus.pending)
      .toList();

  List<ConnectionRequest> get _declined =>
      _requests.where((r) => r.status == RequestStatus.declined).toList();

  @override
  void initState() {
    super.initState();
    _config = _RoleConfig.forRole(widget.role);
    _tabController = TabController(length: 3, vsync: this);
    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final userId = supabase.auth.currentUser!.id;
    try {
      if (widget.role == 'patient') {
        final doctorRows = await supabase
            .from('doctor_patient_connections')
            .select(
              'id, status, requested_by, requested_at, users!doctor_patient_connections_doctor_id_fkey(full_name, profile_picture_url, id, role)',
            )
            .eq('patient_id', userId);

        final guardianRows = await supabase
            .from('guardian_patient_connections')
            .select(
              'id, status, requested_by, requested_at, users!guardian_patient_connections_guardian_id_fkey(full_name, profile_picture_url, id, role)',
            )
            .eq('patient_id', userId);

        final List<ConnectionRequest> all = [];

        void addRequests(List rows, String table) {
          for (final row in rows) {
            final userData = row['users'] as Map<String, dynamic>?;
            final fullName = userData?['full_name'] ?? 'Unknown User';
            final personId = userData?['id'] as String? ?? '';
            final profilePictureUrl =
                userData?['profile_picture_url'] as String?;
            final personRole = userData?['role'] as String?;
            all.add(ConnectionRequest(
              id: row['id'].toString(),
              personName: fullName,
              personId: personId,
              sentAgo: _timeAgo(row['requested_at']),
              avatarInitials: _initials(fullName),
              profilePictureUrl: profilePictureUrl,
              requestedBy: row['requested_by'],
              sourceTable: table,
              personRole: personRole,
              status: _parseStatus(row['status']),
            ));
          }
        }

        addRequests(doctorRows as List, 'doctor_patient_connections');
        addRequests(guardianRows as List, 'guardian_patient_connections');

        if (mounted) {
          setState(() {
            _requests = all;
            _isLoading = false;
            _refreshTabs++;
          });
          widget.onIncomingCountChanged?.call(_incoming.length);
        }
      } else {
        final response = await supabase
            .from(_config.connectionsTable)
            .select(
              'id, status, requested_by, requested_at, users!${_config.connectionsTable}_patient_id_fkey(full_name, profile_picture_url, id, role)',
            )
            .eq(_config.profileIdField, userId);

        final List<ConnectionRequest> all = (response as List).map((row) {
          final userData = row['users'] as Map<String, dynamic>?;
          final fullName = userData?['full_name'] ?? 'Unknown User';
          final personId = userData?['id'] as String? ?? '';
          final profilePictureUrl =
              userData?['profile_picture_url'] as String?;
          final personRole = userData?['role'] as String?;
          return ConnectionRequest(
            id: row['id'].toString(),
            personName: fullName,
            personId: personId,
            sentAgo: _timeAgo(row['requested_at']),
            avatarInitials: _initials(fullName),
            profilePictureUrl: profilePictureUrl,
            requestedBy: row['requested_by'] ?? widget.role,
            sourceTable: _config.connectionsTable,
            personRole: personRole,
            status: _parseStatus(row['status']),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _requests = all;
            _isLoading = false;
            _refreshTabs++;
          });
          widget.onIncomingCountChanged?.call(_incoming.length);
        }
      }
    } catch (e) {
      debugPrint('Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  RequestStatus _parseStatus(String? s) {
    if (s == 'accepted') return RequestStatus.accepted;
    if (s == 'declined') return RequestStatus.declined;
    return RequestStatus.pending;
  }

  void _accept(ConnectionRequest request) async {
    try {
      await supabase
          .from(request.sourceTable)
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', int.parse(request.id));

      if (!mounted) return;
      setState(() {
        final i = _requests.indexWhere((r) => r.id == request.id);
        if (i != -1) _requests[i].status = RequestStatus.accepted;
        _refreshTabs++;
      });
      _showSnackbar('Connected with ${request.personName}', success: true);
    } catch (_) {
      _showSnackbar('Failed to accept request');
    }
  }

  void _decline(ConnectionRequest request) async {
    try {
      await supabase
          .from(request.sourceTable)
          .update({
            'status': 'declined',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', int.parse(request.id));

      if (!mounted) return;
      setState(() {
        final i = _requests.indexWhere((r) => r.id == request.id);
        if (i != -1) _requests[i].status = RequestStatus.declined;
        _refreshTabs++;
      });
      _showSnackbar('Request declined');
    } catch (_) {
      _showSnackbar('Failed to decline request');
    }
  }

  void _withdraw(ConnectionRequest request) async {
    try {
      await supabase
          .from(request.sourceTable)
          .delete()
          .eq('id', int.parse(request.id));

      if (!mounted) return;
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
        _refreshTabs++;
      });
      _showSnackbar('Request withdrawn');
    } catch (_) {
      _showSnackbar('Failed to withdraw request');
    }
  }

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(
        role: widget.role,
        config: _config,
        onRequestChanged: _fetchRequests,
        onSent: () {
          _fetchRequests();
          _tabController.animateTo(1);
        },
      ),
    );
  }

  String _timeAgo(String isoString) {
    final diff =
        DateTime.now().difference(DateTime.parse(isoString).toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  void _showSnackbar(String message, {bool success = false}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            TranslatedText(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: success ? Colors.green.shade600 : colors.accent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSearchSheet,
        backgroundColor: colors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_search_rounded, size: 20),
        label: TranslatedText(
          widget.role == 'patient' ? 'Add Doctor / Guardian' : 'Add Patient',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildTabBar(context),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colors.accent,
                        strokeWidth: 2,
                      ),
                    )
                  : TabBarView(
                      key: ValueKey(_refreshTabs),
                      controller: _tabController,
                      children: [
                        _buildList(context, _incoming, tabType: 'incoming'),
                        _buildList(context, _sent, tabType: 'sent'),
                        _buildList(context, _declined, tabType: 'declined'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.people_alt_rounded,
                color: colors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'Connection Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                TranslatedText(
                  'Manage your clinical and care connections',
                  style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: colors.textSecondary.withValues(alpha: 0.12), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colors.accent,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.accent,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: [
          _Tab(label: 'Incoming', count: _incoming.length),
          _Tab(label: 'Sent', count: _sent.length),
          _Tab(label: 'Declined', count: _declined.length),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ConnectionRequest> requests, {
    required String tabType,
  }) {
    if (requests.isEmpty) return _EmptyState(tabType: tabType);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: requests.length,
      itemBuilder: (context, index) => _RequestCard(
        request: requests[index],
        tabType: tabType,
        onAccept: () => _accept(requests[index]),
        onDecline: () => _decline(requests[index]),
        onWithdraw: () => _withdraw(requests[index]),
      ),
    );
  }
}

// ─── TAB WIDGET ──────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final int count;

  const _Tab({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: context.colors.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: context.colors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String tabType;

  const _EmptyState({required this.tabType});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, title, subtitle) = switch (tabType) {
      'incoming' => (
          Icons.download_rounded,
          'No incoming requests',
          'When someone requests to connect,\nit will appear here'
        ),
      'sent' => (
          Icons.upload_rounded,
          'No sent requests',
          'Your pending requests will appear here'
        ),
      _ => (
          Icons.cancel_rounded,
          'No declined requests',
          'Declined requests will appear here'
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.1)),
              ),
              child: Icon(icon,
                  size: 32,
                  color: colors.textSecondary.withValues(alpha: 0.35)),
            ),
            const SizedBox(height: 16),
            TranslatedText(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TranslatedText(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── REQUEST CARD ────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final ConnectionRequest request;
  final String tabType;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onWithdraw;

  const _RequestCard({
    required this.request,
    required this.tabType,
    required this.onAccept,
    required this.onDecline,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: colors.textSecondary.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                ProfilePicture(
                  userId: request.personId,
                  imageUrl: request.profilePictureUrl,
                  size: 48,
                  isEditable: false,
                  showInitials: true,
                  displayName: request.personName,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        request.personName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (request.personRole != null) ...[
                            _RoleBadge(role: request.personRole!),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.access_time_rounded,
                              size: 11,
                              color:
                                  colors.textSecondary.withValues(alpha: 0.7)),
                          const SizedBox(width: 3),
                          TranslatedText(
                            request.sentAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
              height: 1,
              thickness: 1,
              color: colors.textSecondary.withValues(alpha: 0.07)),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: _buildActions(context, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, dynamic colors) {
    if (tabType == 'incoming') {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Decline',
              icon: Icons.close_rounded,
              onTap: onDecline,
              variant: _ButtonVariant.danger,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              label: 'Accept',
              icon: Icons.check_rounded,
              onTap: onAccept,
              variant: _ButtonVariant.primary,
            ),
          ),
        ],
      );
    }

    if (tabType == 'sent') {
      return _ActionButton(
        label: 'Withdraw Request',
        icon: Icons.undo_rounded,
        onTap: onWithdraw,
        variant: _ButtonVariant.danger,
        fullWidth: true,
      );
    }

    // Declined
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 13, color: colors.error),
              const SizedBox(width: 5),
              TranslatedText(
                'Declined',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── ROLE BADGE ──────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isDoctor = role == 'doctor';
    final color = isDoctor ? const Color(0xFF185FA5) : const Color(0xFF0F6E56);
    final bg = isDoctor
        ? const Color(0xFFE6F1FB)
        : const Color(0xFFE1F5EE);
    final label = isDoctor ? 'Doctor' : role == 'guardian' ? 'Guardian' : role;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TranslatedText(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── ACTION BUTTON ───────────────────────────────────────────────────────────

enum _ButtonVariant { primary, danger }

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final _ButtonVariant variant;
  final bool fullWidth;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.variant,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPrimary = variant == _ButtonVariant.primary;

    final bg = isPrimary
        ? colors.accent
        : colors.error.withValues(alpha: 0.08);
    final fg = isPrimary ? Colors.white : colors.error;
    final border = isPrimary
        ? BorderSide.none
        : BorderSide(color: colors.error.withValues(alpha: 0.25));

    final child = Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.fromBorderSide(border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              TranslatedText(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: child) : child;
  }
}

// ─── SEARCH SHEET ─────────────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  final String role;
  final _RoleConfig config;
  final VoidCallback onRequestChanged;
  final VoidCallback onSent;

  const _SearchSheet({
    required this.role,
    required this.config,
    required this.onRequestChanged,
    required this.onSent,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
      _errorMessage = null;
    });

    try {
      final userRows = await (widget.role == 'patient'
          ? supabase
              .from('users')
              .select('id, full_name, phone_no, role, profile_picture_url')
              .eq('phone_no', phone)
              .inFilter('role', ['doctor', 'guardian'])
          : supabase
              .from('users')
              .select('id, full_name, phone_no, role, profile_picture_url')
              .eq('phone_no', phone)
              .eq('role', 'patient'));
      if ((userRows as List).isEmpty) {
        setState(() {
          _errorMessage = 'No registered user found with this number.';
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> found = [];
      final currentUserId = supabase.auth.currentUser!.id;

      for (final user in userRows) {
        final targetUserId = user['id'] as String;
        final targetRole = user['role'] as String;

        final String table;
        final String foreignKey;

        if (widget.role == 'patient') {
          table = targetRole == 'doctor'
              ? 'doctor_patient_connections'
              : 'guardian_patient_connections';
          foreignKey = targetRole == 'doctor' ? 'doctor_id' : 'guardian_id';
        } else {
          table = widget.config.connectionsTable;
          foreignKey = widget.config.profileIdField;
        }

        final connCheck = await supabase
            .from(table)
            .select('id, status')
            .eq(
              'patient_id',
              widget.role == 'patient' ? currentUserId : targetUserId,
            )
            .eq(
              foreignKey,
              widget.role == 'patient' ? targetUserId : currentUserId,
            );

        found.add({
          'targetId': targetUserId,
          'full_name': user['full_name'],
          'phone_no': user['phone_no'],
          'role': targetRole,
          'profile_picture_url': user['profile_picture_url'],
          'table': table,
          'foreignKey': foreignKey,
          'status':
              (connCheck as List).isNotEmpty ? connCheck[0]['status'] : 'none',
        });
      }

      setState(() {
        _results = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _send(Map<String, dynamic> person) async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      final data = {
        'status': 'pending',
        'requested_by': widget.role,
        'requested_at': DateTime.now().toIso8601String(),
        'is_sharing': true,
      };

      if (widget.role == 'patient') {
        data['patient_id'] = currentUserId;
        data[person['foreignKey']] = person['targetId'];
      } else {
        data['patient_id'] = person['targetId'];
        data[widget.config.profileIdField] = currentUserId;
      }

      await supabase.from(person['table']).insert(data);
      if (mounted) {
        Navigator.pop(context);
        widget.onSent();
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to send request.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
              color: colors.textSecondary.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.search_rounded, color: colors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              TranslatedText(
                'Search Connections',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.phone,
                  onSubmitted: (_) => _search(),
                  style: TextStyle(
                      fontSize: 14, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.phone_iphone_rounded,
                        color: colors.textSecondary, size: 18),
                    filled: true,
                    fillColor: colors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color:
                              colors.textSecondary.withValues(alpha: 0.12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colors.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const TranslatedText('Search',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),

          // Error
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: colors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      _errorMessage!,
                      style: TextStyle(
                          color: colors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Results
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 20),
            TranslatedText(
              '${_results.length} result${_results.length == 1 ? '' : 's'} found',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary),
            ),
            const SizedBox(height: 10),
            ..._results.map((p) => _buildResultRow(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(Map<String, dynamic> p) {
    final colors = context.colors;
    final status = p['status'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: colors.textSecondary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ProfilePicture(
            userId: p['targetId'],
            imageUrl: p['profile_picture_url'],
            size: 42,
            isEditable: false,
            showInitials: true,
            displayName: p['full_name'],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  p['full_name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (p['role'] != null) ...[
                      _RoleBadge(role: p['role']),
                      const SizedBox(width: 6),
                    ],
                    Icon(Icons.phone_rounded,
                        size: 11, color: colors.textSecondary),
                    const SizedBox(width: 3),
                    TranslatedText(
                      p['phone_no'],
                      style: TextStyle(
                          fontSize: 11, color: colors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (status == 'none')
            ElevatedButton(
              onPressed: () => _send(p),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12),
              ),
              child: const TranslatedText('Add'),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: status == 'accepted'
                    ? Colors.green.withValues(alpha: 0.1)
                    : colors.textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TranslatedText(
                status == 'accepted' ? 'Connected' : _capitalize(status),
                style: TextStyle(
                  color: status == 'accepted'
                      ? Colors.green.shade700
                      : colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}