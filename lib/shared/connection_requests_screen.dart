// lib\shared\connection_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// ─── CONFIG PER ROLE ─────────────────────────────────────────────────────────

class _RoleConfig {
  final String profileTable;
  final String profileIdField;
  final String connectionsTable;
  final String viewName;
  final String viewForeignKey;
  final String requestedByValue;

  const _RoleConfig({
    required this.profileTable,
    required this.profileIdField,
    required this.connectionsTable,
    required this.viewName,
    required this.viewForeignKey,
    required this.requestedByValue,
  });
}

_RoleConfig _configForRole(String role) {
  switch (role) {
    case 'doctor':
      return const _RoleConfig(
        profileTable: 'doctor_profile',
        profileIdField: 'doctor_id',
        connectionsTable: 'doctor_patient_connections',
        viewName: 'doctor_requests_view',
        viewForeignKey: 'doctor_id',
        requestedByValue: 'doctor',
      );
    case 'guardian':
      return const _RoleConfig(
        profileTable: 'guardian_profile',
        profileIdField: 'guardian_id',
        connectionsTable: 'guardian_patient_connections',
        viewName: 'guardian_requests_view',
        viewForeignKey: 'guardian_id',
        requestedByValue: 'guardian',
      );
    case 'patient':
      return const _RoleConfig(
        profileTable: 'patient_profile',
        profileIdField: 'patient_id',
        connectionsTable: 'doctor_patient_connections',
        viewName: 'patient_requests_view',
        viewForeignKey: 'patient_id',
        requestedByValue: 'patient',
      );
    default:
      throw Exception('Unknown role: $role');
  }
}

// ─── MODELS ──────────────────────────────────────────────────────────────────

enum RequestStatus { pending, accepted, declined }

class ConnectionRequest {
  final String id;
  final String personName;
  final String sentAgo;
  final String avatarInitials;
  final String requestedBy;
  RequestStatus status;

  ConnectionRequest({
    required this.id,
    required this.personName,
    required this.sentAgo,
    required this.avatarInitials,
    required this.requestedBy,
    this.status = RequestStatus.pending,
  });
}

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class ConnectionRequestsScreen extends StatefulWidget {
  final String role;
  const ConnectionRequestsScreen({super.key, required this.role});

  @override
  State<ConnectionRequestsScreen> createState() =>
      _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState extends State<ConnectionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late _RoleConfig _config;
  List<ConnectionRequest> _requests = [];
  
  List<ConnectionRequest> get _incoming => _requests
      .where(
        (r) =>
            r.requestedBy != widget.role && r.status == RequestStatus.pending,
      )
      .toList();

  List<ConnectionRequest> get _sent => _requests
      .where(
        (r) =>
            r.requestedBy == widget.role && r.status == RequestStatus.pending,
      )
      .toList();

  List<ConnectionRequest> get _declined =>
      _requests.where((r) => r.status == RequestStatus.declined).toList();

  @override
  void initState() {
    super.initState();
    _config = _configForRole(widget.role);
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileAndFetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndFetch() async {
    await _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final userId = supabase.auth.currentUser!.id;

    // get the other person's name by joining through patient_profile → users
    final response = await supabase
        .from(_config.connectionsTable)
        .select(
          'id, status, requested_by, requested_at, patient_id, patient_profile(user_id, users(full_name))',
        )
        .eq(_config.profileIdField, userId);

    if (!mounted) return;
    setState(() {
      _requests = (response as List).map((row) {
        final fullName =
            row['patient_profile']?['users']?['full_name'] ?? 'Unknown';
        return ConnectionRequest(
          id: row['id'].toString(),
          personName: fullName,
          sentAgo: _timeAgo(row['requested_at']),
          avatarInitials: _initials(fullName),
          requestedBy: row['requested_by'] ?? widget.role,
          status: row['status'] == 'accepted'
              ? RequestStatus.accepted
              : row['status'] == 'declined'
              ? RequestStatus.declined
              : RequestStatus.pending,
        );
      }).toList();
    });
  }

  final userId = supabase.auth.currentUser!.id;
  Future<void> _sendRequest({
    required int patientProfileId,
    required String patientName,
  }) async {
    if (userId == null) return;

    final data = widget.role == 'doctor'
        ? {
            'doctor_id': userId,
            'patient_id': patientProfileId,
            'status': 'pending',
            'requested_by': widget.role,
            'requested_at': DateTime.now().toIso8601String(),
          }
        : widget.role == 'guardian'
        ? {
            'guardian_id': userId,
            'patient_id': patientProfileId,
            'status': 'pending',
            'requested_by': widget.role,
            'requested_at': DateTime.now().toIso8601String(),
          }
        : {
            'doctor_id': patientProfileId.toString(),
            'patient_id': int.parse(userId!),
            'status': 'pending',
            'requested_by': widget.role,
            'requested_at': DateTime.now().toIso8601String(),
          };

    final inserted = await supabase
        .from(_config.connectionsTable)
        .insert(data)
        .select()
        .single();

    if (!mounted) return;
    setState(() {
      _requests.add(
        ConnectionRequest(
          id: inserted['id'].toString(),
          personName: patientName,
          sentAgo: 'just now',
          avatarInitials: _initials(patientName),
          requestedBy: widget.role,
          status: RequestStatus.pending,
        ),
      );
    });

    _tabController.animateTo(1);
    _showSnackbar('Request sent to $patientName');
  }

  void _accept(ConnectionRequest request) async {
    try {
      await supabase
          .from(_config.connectionsTable)
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', int.parse(request.id));

      if (!mounted) return;
      setState(() => request.status = RequestStatus.accepted);
      _showSnackbar('${request.personName} accepted');
    } catch (e) {
      _showSnackbar('Failed to accept request');
    }
  }

  void _decline(ConnectionRequest request) async {
    try {
      await supabase
          .from(_config.connectionsTable)
          .update({
            'status': 'declined',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', int.parse(request.id));

      if (!mounted) return;
      setState(() => request.status = RequestStatus.declined);
      _showSnackbar('${request.personName} declined');
    } catch (e) {
      _showSnackbar('Failed to decline request');
    }
  }

  void _withdraw(ConnectionRequest request) async {
    await supabase
        .from(_config.connectionsTable)
        .delete()
        .eq('id', int.parse(request.id));
    if (!mounted) return;
    setState(() => _requests.remove(request));
    _showSnackbar('Request withdrawn');
  }

  void _openSearchSheet() {
    final userId = supabase.auth.currentUser!.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(
        role: widget.role,
        config: _config,
        profileId: userId,
        onSendRequest: _sendRequest,
        onRequestChanged: _fetchRequests,
      ),
    );
  }

  String _timeAgo(String isoString) {
    final diff = DateTime.now().difference(DateTime.parse(isoString).toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  void _showSnackbar(String message) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSearchSheet,
        backgroundColor: colors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_search_rounded),
        label: const Text(
          'Add Patient',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: colors.background,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return Column(
              children: [
                _buildHeader(context, isLandscape),
                _buildTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      _buildList(
                        context,
                        _incoming,
                        tabType: 'incoming',
                        isLandscape: isLandscape,
                      ),
                      _buildList(
                        context,
                        _sent,
                        tabType: 'sent',
                        isLandscape: isLandscape,
                      ),
                      _buildList(
                        context,
                        _declined,
                        tabType: 'declined',
                        isLandscape: isLandscape,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLandscape) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isLandscape ? 10 : 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_incoming.length} pending request${_incoming.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _chip(context, 'Incoming', _incoming.length, colors.accent),
              const SizedBox(width: 10),
              _chip(context, 'Sent', _sent.length, Colors.green),
              const SizedBox(width: 10),
              _chip(context, 'Declined', _declined.length, colors.error),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: colors.primaryDark,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.accent,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Incoming'),
                if (_incoming.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_incoming.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'Sent'),
          const Tab(text: 'Declined'),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ConnectionRequest> requests, {
    required String tabType,
    required bool isLandscape,
  }) {
    final colors = context.colors;
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              tabType == 'incoming'
                  ? 'No incoming requests'
                  : tabType == 'sent'
                  ? 'No sent requests'
                  : 'No declined requests',
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isLandscape ? 60 : 16,
        12,
        isLandscape ? 60 : 16,
        80,
      ),
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

// ─── REQUEST CARD ─────────────────────────────────────────────────────────────

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.accent.withValues(alpha: 0.15),
                child: Text(
                  request.avatarInitials,
                  style: TextStyle(
                    color: colors.primaryDark,
                    fontWeight: FontWeight.bold,
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
                      request.personName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.sentAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tabType == 'incoming') ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(color: colors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (tabType == 'sent') ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onWithdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Withdraw Request',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✗ Declined',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SEARCH SHEET ─────────────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  final String role;
  final _RoleConfig config;
  final String profileId;
  final Future<void> Function({
    required int patientProfileId,
    required String patientName,
  })
  onSendRequest;
  final VoidCallback onRequestChanged;

  const _SearchSheet({
    required this.role,
    required this.config,
    required this.profileId,
    required this.onSendRequest,
    required this.onRequestChanged,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _phoneController = TextEditingController();
  bool _isSearching = false;
  bool _isSending = false;
  List<Map<String, dynamic>> _results = [];
  String? _errorMessage;

  Future<void> _search() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isSearching = true;
      _results = [];
      _errorMessage = null;
    });

    try {
      final userRows = await supabase
          .from('users')
          .select('id, full_name, phone_no')
          .eq('phone_no', phone)
          .ilike('role', 'patient');

      if ((userRows as List).isEmpty) {
        setState(() {
          _errorMessage = 'No patient found with this phone number.';
          _isSearching = false;
        });
        return;
      }

      final List<Map<String, dynamic>> found = [];

      for (final user in userRows) {
        final profileRows = await supabase
            .from('patient_profile')
            .select('id')
            .eq('user_id', user['id'] as String);

        if ((profileRows as List).isEmpty) continue;

        final patientProfileId = profileRows[0]['id'] as int;

        final myConnection = await supabase
            .from(widget.config.connectionsTable)
            .select('id, status')
            .eq(widget.config.profileIdField, widget.profileId)
            .eq('patient_id', patientProfileId);

        String connectionStatus = 'none';
        if ((myConnection as List).isNotEmpty) {
          connectionStatus = myConnection[0]['status'] as String;
        }

        found.add({
          'patientProfileId': patientProfileId,
          'connectionId': (myConnection as List).isNotEmpty
              ? myConnection[0]['id'].toString()
              : null,
          'full_name': user['full_name'] as String,
          'phone_no': user['phone_no'] as String,
          'connectionStatus': connectionStatus,
        });
      }

      setState(() {
        _results = found;
        if (found.isEmpty) _errorMessage = 'No patient profile found.';
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isSearching = false;
      });
    }
  }

  Future<void> _add(Map<String, dynamic> patient) async {
    setState(() => _isSending = true);
    try {
      await widget.onSendRequest(
        patientProfileId: patient['patientProfileId'] as int,
        patientName: patient['full_name'] as String,
      );
      widget.onRequestChanged();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send request.';
        _isSending = false;
      });
    }
  }

  Future<void> _withdraw(Map<String, dynamic> patient) async {
    setState(() => _isSending = true);
    try {
      await supabase
          .from(widget.config.connectionsTable)
          .delete()
          .eq('id', int.parse(patient['connectionId'] as String));

      setState(() {
        _results = _results.map((p) {
          if (p['patientProfileId'] == patient['patientProfileId']) {
            return {...p, 'connectionStatus': 'none', 'connectionId': null};
          }
          return p;
        }).toList();
        _isSending = false;
      });
      widget.onRequestChanged();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to withdraw request.';
        _isSending = false;
      });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Widget _buildStatusWidget(Map<String, dynamic> patient) {
    final colors = context.colors;
    final status = patient['connectionStatus'] as String;
    switch (status) {
      case 'accepted':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Already connected',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : () => _withdraw(patient),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Withdraw',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      case 'declined':
        return ElevatedButton(
          onPressed: _isSending ? null : () => _add(patient),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Send Again',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      default:
        return ElevatedButton(
          onPressed: _isSending ? null : () => _add(patient),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Find a Patient',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search by phone number to send a connection request.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: colors.textSecondary,
                    ),
                    filled: true,
                    fillColor: colors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.textSecondary.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Search',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._results.map(
              (patient) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colors.accent.withValues(alpha: 0.15),
                      child: Text(
                        _initials(patient['full_name']),
                        style: TextStyle(
                          color: colors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient['full_name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            patient['phone_no'],
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusWidget(patient),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
