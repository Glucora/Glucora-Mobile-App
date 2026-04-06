/*\lib\features\guardian\screens\guardian_home_screen.dart */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'guardian_patient_model.dart';
import 'guardian_patient_detail_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final _supabase = Supabase.instance.client;

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});
  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterStatus;

  List<GuardianPatient> _allPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Step 1: get connections with user info
      final connectionsResp = await _supabase
          .from('guardian_patient_connections')
          .select(
            'patient_id, relationship, users!patient_id(full_name, age, phone_no)',
          )
          .eq('guardian_id', userId)
          .eq('status', 'accepted');

      final connections = connectionsResp as List;

      if (connections.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allPatients = [];
          _isLoading = false;
        });
        return;
      }

      // Step 2: get patient_profile bigint ids from user uuids
      // needed because glucose_readings and insulin_doses still use patient_profile.id
      final patientUserIds = connections
          .map((r) => r['patient_id'] as String)
          .toList();

      final profilesResp = await _supabase
          .from('patient_profile')
          .select('id, user_id')
          .inFilter('user_id', patientUserIds);

      // Map uuid -> bigint patient_profile id
      final Map<String, int> uuidToProfileId = {};
      for (final p in (profilesResp as List)) {
        uuidToProfileId[p['user_id'] as String] = p['id'] as int;
      }

      final patientProfileIds = uuidToProfileId.values.toList();

      // Step 3: glucose readings using bigint ids
      final readingsResp = await _supabase
          .from('glucose_readings')
          .select('patient_id, value_mg_dl, trend, recorded_at')
          .inFilter('patient_id', patientProfileIds);

      // Step 4: insulin doses using bigint ids
      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toUtc().toIso8601String();

      final dosesResp = await _supabase
          .from('insulin_doses')
          .select('patient_id, delivery_method, delivered_at')
          .inFilter('patient_id', patientProfileIds)
          .gte('delivered_at', startOfDay);

      // Group by patient_profile bigint id
      final Map<int, List<dynamic>> readingsByPatient = {};
      for (final r in readingsResp as List) {
        readingsByPatient.putIfAbsent(r['patient_id'] as int, () => []).add(r);
      }

      final Map<int, List<dynamic>> dosesByPatient = {};
      for (final d in dosesResp as List) {
        dosesByPatient.putIfAbsent(d['patient_id'] as int, () => []).add(d);
      }

      if (!mounted) return;
      setState(() {
        _allPatients = connections.map((row) {
          final user = row['users'] as Map<String, dynamic>?;
          final patientUuid = row['patient_id'] as String;
          final profileId = uuidToProfileId[patientUuid];

          final name = user?['full_name'] ?? 'Unknown';
          final age = (user?['age'] as num?)?.toInt() ?? 0;
          final phone = user?['phone_no'] ?? '';
          final rel = row['relationship'] ?? 'Guardian';

          final readings = List.from(readingsByPatient[profileId] ?? []);
          readings.sort(
            (a, b) => DateTime.parse(
              b['recorded_at'],
            ).compareTo(DateTime.parse(a['recorded_at'])),
          );
          final latest = readings.isNotEmpty ? readings.first : null;
          final glucose = (latest?['value_mg_dl'] as num?)?.toInt() ?? 0;
          final trend = latest?['trend'] ?? 'stable';
          final lastSeen = latest != null
              ? _timeAgo(latest['recorded_at'])
              : 'No readings';

          final doses = dosesByPatient[profileId] ?? [];
          final allAutomatic =
              doses.isNotEmpty &&
              doses.every((d) => d['delivery_method'] == 'Pump');

          return GuardianPatient(
            id: patientUuid,
            patientId: profileId ?? 0,
            name: name,
            age: age,
            relationship: rel,
            glucoseValue: glucose,
            glucoseTrend: trend,
            sensorConnected: true,
            pumpActive: true,
            dosesToday: doses.length,
            allDosesAutomatic: allAutomatic,
            lastSeenTime: lastSeen,
            phoneNumber: phone,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('GUARDIAN FETCH ERROR: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _timeAgo(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  List<GuardianPatient> get _filtered =>
      _allPatients.where((p) {
        final q = _query.toLowerCase();
        final matchQ =
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.relationship.toLowerCase().contains(q);
        final matchF =
            _filterStatus == null || p.overallStatus == _filterStatus;
        return matchQ && matchF;
      }).toList()..sort((a, b) {
        const o = {'emergency': 0, 'attention': 1, 'good': 2};
        return (o[a.overallStatus] ?? 2).compareTo(o[b.overallStatus] ?? 2);
      });

  int get _emergencyCount =>
      _allPatients.where((p) => p.overallStatus == 'emergency').length;

  int get _attentionCount =>
      _allPatients.where((p) => p.overallStatus == 'attention').length;

  static Color statusColor(String s, GlucoraColors colors) {
    switch (s) {
      case 'emergency':
        return colors.error;
      case 'attention':
        return colors.warning;
      default:
        return colors.accent;
    }
  }

  static Color statusBg(String s, GlucoraColors colors) {
    switch (s) {
      case 'emergency':
        return colors.error.withValues(alpha: 0.1);
      case 'attention':
        return colors.warning.withValues(alpha: 0.1);
      default:
        return colors.accent.withValues(alpha: 0.1);
    }
  }

  static String statusLabel(String s) {
    switch (s) {
      case 'emergency':
        return 'Check on them';
      case 'attention':
        return 'Worth a look';
      default:
        return 'Doing well';
    }
  }

  static Color glucoseColor(GuardianPatient p, GlucoraColors colors) {
    switch (p.glucoseLabel) {
      case 'Too high':
      case 'Very high':
      case 'Too low':
      case 'Very low':
        return colors.error;
      case 'A bit high':
        return colors.warning;
      default:
        return colors.accent;
    }
  }

  static IconData trendIcon(String t) {
    switch (t) {
      case 'up':
        return Icons.trending_up_rounded;
      case 'down':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        current: _filterStatus,
        onApply: (v) => setState(() => _filterStatus = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final list = _filtered;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (ctx, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      isLandscape ? 10 : 24,
                      20,
                      0,
                    ),
                    child: isLandscape
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _titleBlock(context)),
                              const SizedBox(width: 16),
                              _statusPills(context),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _titleBlock(context),
                              const SizedBox(height: 10),
                              _statusPills(context),
                            ],
                          ),
                  ),
                ),

                /*      if (_emergencyCount > 0 || _attentionCount > 0)
                  SliverToBoxAdapter(child: _nudgeBar(context)),
 */
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: colors.textSecondary,
                                  size: 20,
                                ),
                                hintText: 'Search by name or relationship...',
                                hintStyle: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: colors.textSecondary,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(() {
                                          _query = '';
                                          _searchCtrl.clear();
                                        }),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => _showFilter(context),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: _filterStatus != null
                                      ? colors.accent
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: _filterStatus != null
                                      ? Colors.white
                                      : colors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            if (_filterStatus != null)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: colors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'Your Patients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${list.length} of ${_allPatients.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (list.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No patients match your search.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (_filterStatus != null || _query.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(() {
                                _filterStatus = null;
                                _query = '';
                                _searchCtrl.clear();
                              }),
                              child: Text(
                                'Clear filters',
                                style: TextStyle(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                if (list.isNotEmpty)
                  isLandscape
                      ? SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 0,
                                  mainAxisExtent: 230,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _buildCard(context, list[i]),
                              childCount: list.length,
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _buildCard(context, list[i]),
                              childCount: list.length,
                            ),
                          ),
                        ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _titleBlock(BuildContext context) {
    final colors = context.colors;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Watching over ${_allPatients.length} people',
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _statusPills(BuildContext context) {
    final colors = context.colors;
    final good = _allPatients.where((p) => p.overallStatus == 'good').length;
    return Wrap(
      spacing: 8,
      children: [
        _pill(
          context,
          '$good Doing well',
          colors.accent,
          colors.accent.withValues(alpha: 0.1),
        ),
        if (_attentionCount > 0)
          _pill(
            context,
            '$_attentionCount Worth a look',
            colors.warning,
            colors.warning.withValues(alpha: 0.1),
          ),
        if (_emergencyCount > 0)
          _pill(
            context,
            '$_emergencyCount Check on them',
            colors.error,
            colors.error.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  Widget _pill(BuildContext context, String label, Color color, Color bg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );

  Widget _nudgeBar(BuildContext context) {
    final colors = context.colors;
    final urgentNames = _allPatients
        .where((p) => p.overallStatus == 'emergency')
        .map((p) => p.name)
        .toList();
    final attnNames = _allPatients
        .where((p) => p.overallStatus == 'attention')
        .map((p) => p.name)
        .toList();

    final bool isUrgent = urgentNames.isNotEmpty;
    final names = isUrgent ? urgentNames : attnNames;
    final color = isUrgent ? colors.error : colors.accent;
    final bg = isUrgent
        ? colors.error.withValues(alpha: 0.1)
        : colors.accent.withValues(alpha: 0.1);

    final message = isUrgent
        ? 'It might be a good time to check on ${names.join(' and ')}'
        : "${names.join(' and ')}'s sugar is slightly off — nothing urgent";

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_border_rounded, color: color, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, GuardianPatient p) {
    final colors = context.colors;
    final sColor = statusColor(p.overallStatus, colors);
    final sBg = statusBg(p.overallStatus, colors);
    final gColor = glucoseColor(p, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.overallStatus == 'good'
              ? colors.textSecondary.withValues(alpha: 0.2)
              : sColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: sBg,
                  child: Text(
                    p.name.substring(0, 1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: sColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.relationship}  ·  Age ${p.age}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: sBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel(p.overallStatus),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '${p.glucoseValue}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: gColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'mg/dL',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: gColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon(p.glucoseTrend), color: gColor, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        p.glucoseLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: gColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _deviceLine(
                      Icons.sensors,
                      'Sensor',
                      p.sensorConnected,
                      colors,
                    ),
                    const SizedBox(height: 2),
                    _deviceLine(
                      Icons.water_drop_outlined,
                      'Pump',
                      p.pumpActive,
                      colors,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!p.sensorConnected || !p.pumpActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  if (!p.sensorConnected)
                    _softChip(
                      'Sensor is off',
                      colors.error,
                      colors.error.withValues(alpha: 0.1),
                    ),
                  if (!p.sensorConnected && !p.pumpActive)
                    const SizedBox(width: 6),
                  if (!p.pumpActive)
                    _softChip(
                      'Pump is paused',
                      colors.error,
                      colors.error.withValues(alpha: 0.1),
                    ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                _actionBtn(Icons.call_rounded, 'Call', colors.accent, () async {
                  HapticFeedback.mediumImpact();
                  final uri = Uri(scheme: 'tel', path: p.phoneNumber);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    _snack('Could not open dialer', colors.error);
                  }
                }, colors),
                const SizedBox(width: 8),
                _actionBtn(
                  Icons.sms_rounded,
                  'SMS',
                  const Color(0xFF5B8CF5),
                  () async {
                    final uri = Uri(scheme: 'sms', path: p.phoneNumber);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      _snack('Could not open messages', colors.error);
                    }
                  },
                  colors,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuardianPatientDetailScreen(patient: p),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceLine(
    IconData icon,
    String label,
    bool ok,
    GlucoraColors colors,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: ok ? colors.accent : colors.textSecondary),
      const SizedBox(width: 3),
      Text(
        ok ? '$label on' : '$label off',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: ok ? colors.accent : colors.textSecondary,
        ),
      ),
    ],
  );

  Widget _softChip(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
    ),
  );

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    GlucoraColors colors,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final String? current;
  final ValueChanged<String?> onApply;
  const _FilterSheet({required this.current, required this.onApply});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _sel;
  @override
  void initState() {
    super.initState();
    _sel = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              if (_sel != null)
                TextButton(
                  onPressed: () {
                    setState(() => _sel = null);
                    widget.onApply(null);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _opt(
            context,
            null,
            'All Patients',
            'Show everyone',
            colors.textSecondary,
            colors.background,
          ),
          const SizedBox(height: 8),
          _opt(
            context,
            'good',
            'Doing Well',
            'Sugar is in the normal range',
            colors.accent,
            colors.accent.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          _opt(
            context,
            'attention',
            'Worth a Look',
            'Sugar slightly off — nothing to worry',
            colors.warning,
            colors.warning.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          _opt(
            context,
            'emergency',
            'Check on Them',
            'May be a good time to reach out',
            colors.error,
            colors.error.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_sel);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _sel == null ? 'Show All Patients' : 'Apply Filter',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opt(
    BuildContext context,
    String? value,
    String title,
    String subtitle,
    Color color,
    Color bg,
  ) {
    final colors = context.colors;
    final active = _sel == value;
    return GestureDetector(
      onTap: () =>
          setState(() => _sel = (active && value != null) ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? bg : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.35)
                : colors.textSecondary.withValues(alpha: 0.2),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: active ? color : colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
