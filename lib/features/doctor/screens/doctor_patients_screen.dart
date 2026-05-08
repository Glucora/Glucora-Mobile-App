import 'package:flutter/material.dart';
import 'patient_details_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';
import 'package:glucora_ai_companion/services/repositories/doctor_repository.dart';

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  late final DoctorRepository _repo =
      DoctorRepository(Supabase.instance.client);

  List<DoctorPatient> _allPatients = [];
  String _doctorName = '';
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _filterStatus;
  String? _filterTrend;
  String? _filterRange;

  bool get _hasActiveFilters =>
      _filterStatus != null || _filterTrend != null || _filterRange != null;

  String _glucoseRange(DoctorPatient p) {
    if (p.glucoseValue < 70) return 'Low';
    if (p.glucoseValue <= 180) return 'In Range';
    return 'High';
  }

  List<DoctorPatient> get _filtered {
    return _allPatients.where((p) {
      if (_query.isNotEmpty &&
          !p.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      if (_filterStatus != null && p.status != _filterStatus) return false;
      if (_filterTrend != null && p.trend != _filterTrend) return false;
      if (_filterRange != null && _glucoseRange(p) != _filterRange) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDoctorName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final fullName = user.userMetadata?['full_name'] as String?;
    setState(() => _doctorName = fullName ?? 'Doctor');
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final patients = await _repo.getPatients(userId);
      if (!mounted) return;
      setState(() {
        _allPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

    if (_error != null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              TranslatedText(
                'Failed to load patients',
                style: TextStyle(color: colors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPatients,
                child: const TranslatedText('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final total    = _allPatients.length;
    final critical = _allPatients.where((p) => p.status == 'Critical').length;
    final highRisk = _allPatients.where((p) => p.status == 'High Risk').length;
    final normal   = _allPatients.where((p) => p.status == 'Normal').length;
    final low      = _allPatients.where((p) => p.status == 'Low').length;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isLandscape ? 12 : 20,
                    ),
                    child: isLandscape
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildGreeting(colors, landscape: true)),
                              const SizedBox(width: 16),
                              SizedBox(width: 340, child: _buildSearchBar(context)),
                            ],
                          )
                        : _buildGreeting(colors, landscape: false),
                  ),
                ),

                // ── Summary chips ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        _summaryChip(context, 'Total',     '$total',    colors.accent),
                        _summaryChip(context, 'Critical',  '$critical', Colors.red),
                        _summaryChip(context, 'High Risk', '$highRisk', Colors.orange),
                        _summaryChip(context, 'Normal',    '$normal',   Colors.green),
                        _summaryChip(context, 'Low',       '$low',      Colors.blue),
                      ],
                    ),
                  ),
                ),

                // ── Search bar (portrait only) ───────────────────────────────
                if (!isLandscape)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: _buildSearchBar(context),
                    ),
                  ),

                // ── Section label ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TranslatedText(
                          'Your Patients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        TranslatedText(
                          '${_filtered.length} shown',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Empty state ──────────────────────────────────────────────
                if (_filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: TranslatedText(
                        'No patients found.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  ),

                // ── Patient list / grid ──────────────────────────────────────
                if (_filtered.isNotEmpty)
                  isLandscape
                      ? SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 0,
                              childAspectRatio: 3.4,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildPatientCard(context, index),
                              childCount: _filtered.length,
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildPatientCard(context, index),
                              childCount: _filtered.length,
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildGreeting(dynamic colors, {required bool landscape}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          landscape ? 'Hi, Doctor $_doctorName 👋' : 'Hi, Dr. $_doctorName 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        if (!landscape) const SizedBox(height: 4),
        TranslatedText(
          'Here is your patients overview',
          style: TextStyle(
            fontSize: landscape ? 13 : 14,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(BuildContext context, int index) {
    final patient = _filtered[index];
    return _PatientCard(
      patient: patient,
      onTap: () async {
        final removed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailsScreen(
              patientId: patient.profileId,
              patientName: patient.name,
            ),
          ),
        );
        if (removed == true) _loadPatients();
      },
    );
  }

  Widget _summaryChip(
    BuildContext context,
    String label,
    String count,
    Color color,
  ) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            TranslatedText(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            TranslatedText(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        currentStatus: _filterStatus,
        currentTrend: _filterTrend,
        currentRange: _filterRange,
        onApply: (status, trend, range) => setState(() {
          _filterStatus = status;
          _filterTrend = trend;
          _filterRange = range;
        }),
        onClear: () => setState(() {
          _filterStatus = null;
          _filterTrend = null;
          _filterRange = null;
        }),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: colors.textSecondary),
                hintText: 'Search patients...',
                hintStyle: TextStyle(color: colors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _showFilterSheet(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _hasActiveFilters ? colors.primaryDark : colors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 20),
              ),
              if (_hasActiveFilters)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: TranslatedText(
                        '${[_filterStatus, _filterTrend, _filterRange].where((f) => f != null).length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── FILTER BOTTOM SHEET ─────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  final String? currentStatus;
  final String? currentTrend;
  final String? currentRange;
  final void Function(String? status, String? trend, String? range) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    required this.currentStatus,
    required this.currentTrend,
    required this.currentRange,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _status;
  String? _trend;
  String? _range;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _trend  = widget.currentTrend;
    _range  = widget.currentRange;
  }

  bool get _hasAny => _status != null || _trend != null || _range != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              TranslatedText(
                'Filter Patients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_hasAny)
                GestureDetector(
                  onTap: () => setState(() {
                    _status = null;
                    _trend  = null;
                    _range  = null;
                  }),
                  child: TranslatedText(
                    'Clear all',
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          _filterSection(
            context,
            title: 'Status',
            icon: Icons.circle_outlined,
            options: const ['Low', 'Normal', 'High Risk', 'Critical'],
            optionColors: const [Colors.blue, Colors.green, Colors.orange, Colors.red],
            selected: _status,
            onSelect: (val) => setState(() => _status = _status == val ? null : val),
          ),
          const SizedBox(height: 20),

          _filterSection(
            context,
            title: 'Last Reading',
            icon: Icons.monitor_heart_outlined,
            options: const ['Low', 'In Range', 'High'],
            optionColors: const [
              Color(0xFFFF6B6B),
              Color(0xFF2BB6A3),
              Color(0xFFFF9F40),
            ],
            selected: _range,
            onSelect: (val) => setState(() => _range = _range == val ? null : val),
          ),
          const SizedBox(height: 20),

          _filterSection(
            context,
            title: 'Glucose Trend',
            icon: Icons.trending_up_outlined,
            options: const ['Rising', 'Falling', 'Stable'],
            optionColors: const [Colors.red, Color(0xFFFF9F40), Colors.green],
            selected: _trend == 'up'
                ? 'Rising'
                : _trend == 'down'
                    ? 'Falling'
                    : _trend == 'stable'
                        ? 'Stable'
                        : null,
            onSelect: (val) {
              const map = {'Rising': 'up', 'Falling': 'down', 'Stable': 'stable'};
              final internal = map[val];
              setState(() => _trend = _trend == internal ? null : internal);
            },
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_status, _trend, _range);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: TranslatedText(
                _hasAny ? 'Apply Filters' : 'Show All Patients',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> options,
    required List<Color> optionColors,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: colors.textSecondary),
            const SizedBox(width: 6),
            TranslatedText(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(options.length, (i) {
            final opt   = options[i];
            final color = optionColors[i];
            final isSelected = selected == opt;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onSelect(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.12)
                          : colors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : colors.textSecondary.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? color : colors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        TranslatedText(
                          opt,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? color : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── PATIENT CARD ─────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final DoctorPatient patient;
  final VoidCallback? onTap;
  const _PatientCard({required this.patient, this.onTap});

  Color _statusColor() {
    switch (patient.status) {
      case 'Critical':  return Colors.red;
      case 'High Risk': return Colors.orange;
      case 'Normal':    return Colors.green;
      case 'Low':       return Colors.blue;
      default:          return Colors.grey;
    }
  }

  Widget _trendIcon() {
    switch (patient.trend) {
      case 'up':   return const Icon(Icons.trending_up,   color: Colors.red,    size: 16);
      case 'down': return const Icon(Icons.trending_down, color: Colors.orange, size: 16);
      default:     return const Icon(Icons.trending_flat, color: Colors.green,  size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ProfilePicture(
              userId: patient.userId,
              imageUrl: patient.profilePictureUrl,
              size: 48,
              isEditable: false,
              showInitials: true,
              displayName: patient.name,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    patient.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _trendIcon(),
                      const SizedBox(width: 4),
                      TranslatedText(
                        patient.lastReading,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TranslatedText(
                        '• ${patient.lastReadingTime}',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TranslatedText(
                patient.status,
                style: TextStyle(
                  color: _statusColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}