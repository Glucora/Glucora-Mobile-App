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
}

_RoleConfig _configForRole(String role) {
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
    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final userId = user.id;
    try {
      if (widget.role == 'patient') {
        final doctorRows = await supabase
            .from('doctor_patient_connections')
            .select(
              'id, status, requested_by, requested_at, users!doctor_patient_connections_doctor_id_fkey(full_name, profile_picture_url, id)',
            )
            .eq('patient_id', userId);

        final guardianRows = await supabase
            .from('guardian_patient_connections')
            .select(
              'id, status, requested_by, requested_at, users!guardian_patient_connections_guardian_id_fkey(full_name, profile_picture_url, id)',
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
            all.add(
              ConnectionRequest(
                id: row['id'].toString(),
                personName: fullName,
                personId: personId,
                sentAgo: _timeAgo(row['requested_at']),
                avatarInitials: _initials(fullName),
                profilePictureUrl: profilePictureUrl,
                requestedBy: row['requested_by'],
                sourceTable: table,
                status: _parseStatus(row['status']),
              ),
            );
          }
        }

        addRequests(doctorRows as List, 'doctor_patient_connections');
        addRequests(guardianRows as List, 'guardian_patient_connections');
        if (mounted) {
          setState(() => _requests = all);
          widget.onIncomingCountChanged?.call(_incoming.length);
        }
      } else {
        final response = await supabase
            .from(_config.connectionsTable)
            .select(
              'id, status, requested_by, requested_at, users!${_config.connectionsTable}_patient_id_fkey(full_name, profile_picture_url, id)',
            )
            .eq(_config.profileIdField, userId);

        final List<ConnectionRequest> all = (response as List).map((row) {
          final userData = row['users'] as Map<String, dynamic>?;
          final fullName = userData?['full_name'] ?? 'Unknown User';
          final personId = userData?['id'] as String? ?? '';
          final profilePictureUrl = userData?['profile_picture_url'] as String?;
          return ConnectionRequest(
            id: row['id'].toString(),
            personName: fullName,
            personId: personId,
            sentAgo: _timeAgo(row['requested_at']),
            avatarInitials: _initials(fullName),
            profilePictureUrl: profilePictureUrl,
            requestedBy: row['requested_by'] ?? widget.role,
            sourceTable: _config.connectionsTable,
            status: _parseStatus(row['status']),
          );
        }).toList();

        if (mounted) {
          setState(() => _requests = all);
          widget.onIncomingCountChanged?.call(_incoming.length);
        }
      }
    } catch (e) {
      debugPrint('Fetch Error: $e');
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
      setState(() => request.status = RequestStatus.accepted);
      _showSnackbar('${request.personName} accepted');
    } catch (e) {
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
      setState(() => request.status = RequestStatus.declined);
      _showSnackbar('${request.personName} declined');
    } catch (e) {
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
      setState(() => _requests.remove(request));
      _showSnackbar('Request withdrawn');
    } catch (e) {
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
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  void _showSnackbar(String message) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText(
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
        elevation: 4,
        icon: const Icon(Icons.person_search_rounded),
        label: TranslatedText(
          widget.role == 'patient' ? 'Add Doctor/Guardian' : 'Add Patient',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
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
      padding: EdgeInsets.fromLTRB(20, isLandscape ? 10 : 25, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            'Connection Requests',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          TranslatedText(
            'Manage your clinical and care connections',
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(context, 'Incoming', _incoming.length, colors.accent),
                const SizedBox(width: 10),
                _chip(context, 'Sent', _sent.length, Colors.green),
                const SizedBox(width: 10),
                _chip(context, 'Declined', _declined.length, colors.error),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          TranslatedText(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(child: TranslatedText('Incoming')),
          Tab(child: TranslatedText('Sent')),
          Tab(child: TranslatedText('Declined')),
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
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: colors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            TranslatedText(
              'No $tabType requests found',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ✅ Profile Picture instead of CircleAvatar
              ProfilePicture(
                userId: request.personId,
                imageUrl: request.profilePictureUrl,
                size: 52,
                isEditable: false,
                showInitials: true,
                displayName: request.personName,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      request.personName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        TranslatedText(
                          request.sentAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (tabType == 'incoming')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(
                        color: colors.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const TranslatedText(
                      'Decline',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const TranslatedText(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          else if (tabType == 'sent')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onWithdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const TranslatedText(
                  'Withdraw Request',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TranslatedText(
                  'Declined',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── SEARCH SHEET ─────────────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  final String role;
  final _RoleConfig config;
  final VoidCallback onRequestChanged;

  const _SearchSheet({
    required this.role,
    required this.config,
    required this.onRequestChanged,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  String? _errorMessage;

  Future<void> _search() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
      _errorMessage = null;
    });

    try {
      final query = supabase
          .from('users')
          .select('id, full_name, phone_no, role, profile_picture_url')
          .eq('phone_no', phone);

      if (widget.role == 'patient') {
        query.inFilter('role', ['doctor', 'guardian']);
      } else {
        query.eq('role', 'patient');
      }

      final userRows = await query;
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
          'profile_picture_url': user['profile_picture_url'],
          'table': table,
          'foreignKey': foreignKey,
          'status': (connCheck as List).isNotEmpty
              ? connCheck[0]['status']
              : 'none',
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
      widget.onRequestChanged();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send request.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        25,
        12,
        25,
        25 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 25),
          TranslatedText(
            'Search Connections',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              hintText: 'Enter Phone Number',
              prefixIcon: const Icon(Icons.phone_iphone_rounded),
              suffixIcon: IconButton(
                icon: Icon(Icons.search_rounded, color: colors.accent),
                onPressed: _search,
              ),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.phone,
            onSubmitted: (_) => _search(),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: TranslatedText(
                _errorMessage!,
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 25),
            ..._results.map((p) => _buildResultRow(p)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(Map<String, dynamic> p) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // ✅ Profile Picture in search results
          ProfilePicture(
            userId: p['targetId'],
            imageUrl: p['profile_picture_url'],
            size: 44,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TranslatedText(
                  p['phone_no'],
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (p['status'] == 'none')
            ElevatedButton(
              onPressed: () => _send(p),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const TranslatedText('Add'),
            )
          else
            TranslatedText(
              p['status'].toString().toUpperCase(),
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
