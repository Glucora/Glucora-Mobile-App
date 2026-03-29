import 'package:flutter/material.dart';
import 'patient_details_screen.dart';
import 'care_plan_editor_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
// ─── ENUMS & MODELS ──────────────────────────────────────────────────────────

enum AlertSeverity { critical, warning, info }

enum AlertType {
  glucoseCriticalHigh,
  glucoseCriticalLow,
  pumpFailure,
  sensorDisconnect,
  missedDose,
  patientInactivity,
  timeOutOfRange,
  incident,
}

class DoctorAlert {
  final int id;
  final String patientName;
  final String patientInitials;
  final AlertSeverity severity;
  final AlertType type;
  final String title;
  final String description;
  final String timeAgo;
  bool isRead;
  bool isDismissed;

  DoctorAlert({
    required this.id,
    required this.patientName,
    required this.patientInitials,
    required this.severity,
    required this.type,
    required this.title,
    required this.description,
    required this.timeAgo,
    this.isRead = false,
    this.isDismissed = false,
  });
}

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class DoctorAlertsScreen extends StatefulWidget {
  const DoctorAlertsScreen({super.key});

  @override
  State<DoctorAlertsScreen> createState() => _DoctorAlertsScreenState();
}

class _DoctorAlertsScreenState extends State<DoctorAlertsScreen> {
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Critical', 'Warning', 'Info'];

  final List<DoctorAlert> _alerts = [
    DoctorAlert(id: 1, patientName: 'Qamar Salah', patientInitials: 'QS', severity: AlertSeverity.critical, type: AlertType.glucoseCriticalHigh, title: 'Critical High Glucose', description: 'Glucose reached 298 mg/dL — AID auto-correction delivered 3.5 U. Patient unresponsive to correction after 20 min.', timeAgo: '3 min ago'),
    DoctorAlert(id: 2, patientName: 'Carol Amr', patientInitials: 'CA', severity: AlertSeverity.critical, type: AlertType.glucoseCriticalLow, title: 'Critical Low Glucose', description: 'Glucose dropped to 52 mg/dL — AID suspended basal insulin. Patient may need immediate carb intake.', timeAgo: '8 min ago'),
    DoctorAlert(id: 3, patientName: 'Rana Fathy', patientInitials: 'RF', severity: AlertSeverity.critical, type: AlertType.incident, title: 'Incident: Severe Hypoglycemia', description: 'Patient experienced severe hypo at 6:02 AM (48 mg/dL). Basal suspended for 45 min. CGM trend was falling fast. AID intervention logged.', timeAgo: '2 hours ago'),
    DoctorAlert(id: 4, patientName: 'Khaled Adel', patientInitials: 'KA', severity: AlertSeverity.warning, type: AlertType.pumpFailure, title: 'Pump Connection Lost', description: 'Omnipod 5 lost connection at 10:15 AM. AID system paused. Patient switched to manual mode. Reconnection not confirmed.', timeAgo: '25 min ago'),
    DoctorAlert(id: 5, patientName: 'Walid Ahmed', patientInitials: 'WA', severity: AlertSeverity.warning, type: AlertType.missedDose, title: 'Missed Mealtime Bolus', description: 'No bolus recorded around lunch (12:00-13:00). Glucose rose to 188 mg/dL post-meal. Patient did not confirm meal.', timeAgo: '1 hour ago'),
    DoctorAlert(id: 6, patientName: 'Mayada Youssef', patientInitials: 'MY', severity: AlertSeverity.warning, type: AlertType.sensorDisconnect, title: 'CGM Sensor Disconnected', description: 'Dexcom G7 signal lost for 38 minutes. AID running in open loop fallback. Sensor reconnected at 2:44 PM.', timeAgo: '3 hours ago', isRead: true),
    DoctorAlert(id: 7, patientName: 'Omar Latif', patientInitials: 'OL', severity: AlertSeverity.info, type: AlertType.timeOutOfRange, title: 'High Time Above Range', description: 'Patient spent 34% of today above 180 mg/dL. 7-day average TIR is 61%. Care plan review recommended.', timeAgo: '5 hours ago', isRead: true),
    DoctorAlert(id: 8, patientName: 'Qamar Salah', patientInitials: 'QS', severity: AlertSeverity.info, type: AlertType.patientInactivity, title: 'No CGM Reading for 4 Hours', description: 'Last reading recorded at 9:18 AM. Sensor may be expired or detached. Patient has not opened the app today.', timeAgo: '6 hours ago', isRead: true),
  ];

  List<DoctorAlert> get _visibleAlerts {
    return _alerts.where((a) {
      if (a.isDismissed) return false;
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Critical') return a.severity == AlertSeverity.critical;
      if (_activeFilter == 'Warning') return a.severity == AlertSeverity.warning;
      if (_activeFilter == 'Info') return a.severity == AlertSeverity.info;
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
        return a.severity.index.compareTo(b.severity.index);
      });
  }

  int get _unreadCount => _alerts.where((a) => !a.isRead && !a.isDismissed).length;
  int get _criticalCount => _alerts.where((a) => a.severity == AlertSeverity.critical && !a.isDismissed).length;

  void _markRead(DoctorAlert alert) => setState(() => alert.isRead = true);

  void _dismiss(DoctorAlert alert) {
    setState(() => alert.isDismissed = true);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Alert dismissed', style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.grey.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
      action: SnackBarAction(label: 'Undo', textColor: Colors.white, onPressed: () => setState(() => alert.isDismissed = false)),
    ));
  }

  void _markAllRead() => setState(() { for (final a in _alerts) { a.isRead = true; } });

  void _openEditPlan(DoctorAlert alert) {
    _markRead(alert);
    Navigator.push(context, MaterialPageRoute(builder: (_) => CarePlanEditorScreen(patientId:alert.id ,patientName: alert.patientName)));
  }

  void _openPatient(DoctorAlert alert) {
    _markRead(alert);
    Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailsScreen(patientId:alert.id,patientName: alert.patientName)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visible = _visibleAlerts;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, isLandscape ? 12 : 20, 16, 0),
                    child: isLandscape
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildTitleBlock(context)),
                              const SizedBox(width: 16),
                              _buildFilterChipsInline(context),
                            ],
                          )
                        : _buildTitleBlock(context),
                  ),
                ),
                if (!isLandscape)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildFilterChipsScroll(context),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (visible.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(context)),
                if (visible.isNotEmpty)
                  isLandscape
                      ? SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 0,
                              mainAxisExtent: 240,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _AlertCard(
                                alert: visible[i],
                                onMarkRead: () => _markRead(visible[i]),
                                onDismiss: () => _dismiss(visible[i]),
                                onViewPatient: () => _openPatient(visible[i]),
                                onEditPlan: () => _openEditPlan(visible[i]),
                              ),
                              childCount: visible.length,
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _AlertCard(
                                alert: visible[i],
                                onMarkRead: () => _markRead(visible[i]),
                                onDismiss: () => _dismiss(visible[i]),
                                onViewPatient: () => _openPatient(visible[i]),
                                onEditPlan: () => _openEditPlan(visible[i]),
                              ),
                              childCount: visible.length,
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

  Widget _buildTitleBlock(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Alerts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.textPrimary))),
            if (_unreadCount > 0)
              TextButton(
                onPressed: _markAllRead,
                child: Text('Mark all read', style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (_unreadCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('$_unreadCount unread', style: TextStyle(color: colors.error, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: 8),
            ],
            if (_criticalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_rounded, color: colors.error, size: 12),
                    const SizedBox(width: 4),
                    Text('$_criticalCount critical', style: TextStyle(color: colors.error, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildFilterChipsScroll(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const ClampingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _filterChip(context, _filters[index]),
      ),
    );
  }

  Widget _buildFilterChipsInline(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _filters.map((f) => Padding(padding: const EdgeInsets.only(left: 8), child: _filterChip(context, f))).toList(),
    );
  }

  Widget _filterChip(BuildContext context, String filter) {
    final colors = context.colors;
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(filter, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : colors.textSecondary)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 56, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text('No alerts in this category', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

// ─── ALERT CARD ──────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final DoctorAlert alert;
  final VoidCallback onMarkRead;
  final VoidCallback onDismiss;
  final VoidCallback onViewPatient;
  final VoidCallback onEditPlan;

  const _AlertCard({required this.alert, required this.onMarkRead, required this.onDismiss, required this.onViewPatient, required this.onEditPlan});

Color _severityColor(GlucoraColors colors) {
  switch (alert.severity) {
    case AlertSeverity.critical: return colors.error;
    case AlertSeverity.warning: return colors.warning;
    case AlertSeverity.info: return const Color(0xFF5B8CF5);
  }
}

  IconData get _typeIcon {
    switch (alert.type) {
      case AlertType.glucoseCriticalHigh: return Icons.arrow_upward_rounded;
      case AlertType.glucoseCriticalLow: return Icons.arrow_downward_rounded;
      case AlertType.pumpFailure: return Icons.water_drop_outlined;
      case AlertType.sensorDisconnect: return Icons.bluetooth_disabled_rounded;
      case AlertType.missedDose: return Icons.medication_outlined;
      case AlertType.patientInactivity: return Icons.person_off_outlined;
      case AlertType.timeOutOfRange: return Icons.show_chart_rounded;
      case AlertType.incident: return Icons.report_problem_outlined;
    }
  }

  String get _severityLabel {
    switch (alert.severity) {
      case AlertSeverity.critical: return 'CRITICAL';
      case AlertSeverity.warning: return 'WARNING';
      case AlertSeverity.info: return 'INFO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final severityColor = _severityColor(colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: alert.isRead ? null : Border.all(color: severityColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(_typeIcon, color: severityColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(_severityLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: severityColor, letterSpacing: 0.8)),
                          ),
                          if (alert.type == AlertType.incident) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Text('INCIDENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.purple, letterSpacing: 0.8)),
                            ),
                          ],
                          const Spacer(),
                          Text(alert.timeAgo, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                          if (!alert.isRead) ...[
                            const SizedBox(width: 6),
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: severityColor, shape: BoxShape.circle)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(alert.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: alert.isRead ? colors.textSecondary : colors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(alert.description, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colors.accent.withValues(alpha: 0.15),
                  child: Text(alert.patientInitials, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.primaryDark)),
                ),
                const SizedBox(width: 8),
                Text(alert.patientName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!alert.isRead)
                  _actionBtn(Icons.done, 'Mark Read', colors.textSecondary, colors.background, onMarkRead),
                _actionBtn(Icons.close, 'Dismiss', colors.textSecondary, colors.background, onDismiss),
                _actionBtn(Icons.edit_outlined, 'Edit Plan', const Color(0xFF5B8CF5), const Color(0xFF5B8CF5).withValues(alpha: 0.1), onEditPlan),
                _actionBtn(Icons.person_outline, 'View Patient', colors.primaryDark, colors.accent.withValues(alpha: 0.1), onViewPatient),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}