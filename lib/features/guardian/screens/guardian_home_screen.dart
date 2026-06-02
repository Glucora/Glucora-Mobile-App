import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/guardian_patient_model.dart';
import 'guardian_patient_detail_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';
import 'package:glucora_ai_companion/providers/guardian_riverpod_providers.dart';

class GuardianHomeScreen extends ConsumerStatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  ConsumerState<GuardianHomeScreen> createState() =>
      _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends ConsumerState<GuardianHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(guardianPatientsProvider.notifier).loadPatients();
    });
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('No phone number available');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('No phone number available');
      return;
    }
    final uri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar('Could not launch messaging app');
    }
  }

  void _navigateToDetail(GuardianPatient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuardianPatientDetailScreen(patient: patient),
      ),
    );
  }

  // ── Styling helpers ────────────────────────────────────────────────────────

  Color _getStatusColor(String status, GlucoraColors colors) {
    switch (status) {
      case 'emergency': return colors.error;
      case 'attention': return colors.warning;
      default:          return colors.accent;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'emergency': return 'Check on them';
      case 'attention': return 'Worth a look';
      default:          return 'Doing well';
    }
  }

  Color _getGlucoseColor(GuardianPatient patient, GlucoraColors colors) {
    switch (patient.glucoseLabel) {
      case 'Too high':
      case 'Very high':
      case 'Too low':
      case 'Very low':
        return colors.error;
      case 'A bit high': return colors.warning;
      default:           return colors.accent;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'up':   return Icons.trending_up;
      case 'down': return Icons.trending_down;
      default:     return Icons.trending_flat;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(guardianPatientsProvider);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText(state.error!,
                  style: TextStyle(color: colors.error)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(guardianPatientsProvider.notifier).clearError();
                  ref.read(guardianPatientsProvider.notifier).loadPatients();
                },
                child: const TranslatedText('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final patients = state.filtered(_query, _filterStatus);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            _buildSearchAndFilter(context),
            Expanded(
              child: patients.isEmpty
                  ? _buildEmptyState(context)
                  : _buildPatientList(context, patients),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GuardianPatientsState state) {
    final colors = context.colors;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.patients.length} ${state.patients.length == 1 ? 'person' : 'people'} under your care',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          if (state.patients.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (state.emergencyCount > 0) ...[
                  _buildSummaryChip(
                      '${state.emergencyCount} need help',
                      colors.error,
                      colors),
                  const SizedBox(width: 8),
                ],
                if (state.attentionCount > 0) ...[
                  _buildSummaryChip(
                      '${state.attentionCount} worth a look',
                      colors.warning,
                      colors),
                  const SizedBox(width: 8),
                ],
                _buildSummaryChip(
                    '${state.goodCount} doing well',
                    colors.accent,
                    colors),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
      String label, Color color, GlucoraColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color:
                        colors.textSecondary.withValues(alpha: 0.12)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style:
                    TextStyle(fontSize: 14, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search patients',
                  hintStyle: TextStyle(
                      color: colors.textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: colors.textSecondary, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: Icon(Icons.close_rounded,
                              color: colors.textSecondary, size: 16),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showFilterSheet(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _filterStatus != null
                    ? colors.accent
                    : colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _filterStatus != null
                      ? colors.accent
                      : colors.textSecondary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: _filterStatus != null
                    ? Colors.white
                    : colors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(
      BuildContext context, List<GuardianPatient> patients) {
    return ListView.separated(
      key: ValueKey('patient_list_$_query$_filterStatus'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: patients.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return KeyedSubtree(
          key: ValueKey('patient_${patient.id}_$_query'),
          child: _buildPatientCard(context, patient),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 64,
              color: colors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          TranslatedText(
            _query.isNotEmpty
                ? 'No patients match "$_query"'
                : 'No patients found',
            style:
                TextStyle(fontSize: 16, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          if (_filterStatus != null || _query.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _filterStatus = null;
                _searchCtrl.clear();
              }),
              child: TranslatedText(
                'Clear filters',
                style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
      BuildContext context, GuardianPatient patient) {
    final colors = context.colors;
    final statusColor = _getStatusColor(patient.overallStatus, colors);
    final glucoseColor = _getGlucoseColor(patient, colors);

    return GestureDetector(
      onTap: () => _navigateToDetail(patient),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: patient.overallStatus == 'good'
                ? colors.textSecondary.withValues(alpha: 0.12)
                : statusColor.withValues(alpha: 0.4),
            width: patient.overallStatus == 'good' ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfilePicture(
                    userId: patient.patientId,
                    imageUrl: patient.profilePictureUrl,
                    size: 44,
                    isEditable: false,
                    showInitials: true,
                    displayName: patient.name,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          patient.relationship,
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Age ${patient.age}',
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getStatusLabel(patient.overallStatus),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                  height: 1,
                  color:
                      colors.textSecondary.withValues(alpha: 0.1)),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${patient.glucoseValue}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: glucoseColor,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              'mg/dL',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              glucoseColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                _getTrendIcon(
                                    patient.glucoseTrend),
                                size: 11,
                                color: glucoseColor),
                            const SizedBox(width: 3),
                            Text(
                              patient.glucoseLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: glucoseColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildDeviceStatus(
                          Icons.sensors,
                          'Sensor',
                          patient.sensorConnected,
                          colors,
                          patient.id),
                      const SizedBox(height: 5),
                      _buildDeviceStatus(
                          Icons.water_drop_outlined,
                          'Pump',
                          patient.pumpActive,
                          colors,
                          patient.id),
                    ],
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _sendSMS(patient.phoneNumber),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.textSecondary
                            .withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.message_outlined,
                          size: 16,
                          color: colors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        _makePhoneCall(patient.phoneNumber),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            colors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.call_rounded,
                          size: 16, color: colors.accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceStatus(
    IconData icon,
    String label,
    bool isActive,
    GlucoraColors colors,
    String patientId,
  ) {
    final color = isActive
        ? colors.accent
        : colors.textSecondary.withValues(alpha: 0.5);
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        TranslatedText(
          isActive ? label : '$label off',
          key: ValueKey('device_${label}_${patientId}_$_query'),
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(
        currentFilter: _filterStatus,
        onFilterSelected: (filter) =>
            setState(() => _filterStatus = filter),
      ),
    );
  }
}

// ─── FILTER BOTTOM SHEET — unchanged ─────────────────────────────────────────

class _FilterBottomSheet extends StatelessWidget {
  final String? currentFilter;
  final ValueChanged<String?> onFilterSelected;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GlucoraColors>()!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TranslatedText(
                  'Filter by Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                if (currentFilter != null)
                  TextButton(
                    onPressed: () {
                      onFilterSelected(null);
                      Navigator.pop(context);
                    },
                    child: TranslatedText(
                      'Clear',
                      style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _filterOption(context, null, 'All Patients',
                'Show all patients', colors.textSecondary,
                colors.background, colors),
            const SizedBox(height: 8),
            _filterOption(context, 'good', 'Doing Well',
                'Blood sugar in normal range', colors.accent,
                colors.accent.withValues(alpha: 0.1), colors),
            const SizedBox(height: 8),
            _filterOption(context, 'attention', 'Worth a Look',
                'Blood sugar slightly off', colors.warning,
                colors.warning.withValues(alpha: 0.1), colors),
            const SizedBox(height: 8),
            _filterOption(context, 'emergency', 'Check on Them',
                'Immediate attention needed', colors.error,
                colors.error.withValues(alpha: 0.1), colors),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const TranslatedText('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(
    BuildContext context,
    String? value,
    String title,
    String subtitle,
    Color color,
    Color bgColor,
    GlucoraColors colors,
  ) {
    final isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () {
        onFilterSelected(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : colors.textSecondary.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? color
                          : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TranslatedText(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}