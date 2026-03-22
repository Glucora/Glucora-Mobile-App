import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';

enum GuardianRequestStatus { pending, accepted, declined }

class PatientRequest {
  final String id;
  final String patientName;
  final int age;
  final String diabetesType;
  final String diabetesExplained;
  final String sentAgo;
  final String avatarInitials;
  GuardianRequestStatus status;

  PatientRequest({required this.id, required this.patientName, required this.age, required this.diabetesType, required this.diabetesExplained, required this.sentAgo, required this.avatarInitials, this.status = GuardianRequestStatus.pending});
}

class GuardianRequestsScreen extends StatefulWidget {
  const GuardianRequestsScreen({super.key});
  @override
  State<GuardianRequestsScreen> createState() => _GuardianRequestsScreenState();
}

class _GuardianRequestsScreenState extends State<GuardianRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<PatientRequest> _requests = [
    PatientRequest(id: '1', patientName: 'Ahmed Tarek', age: 24, diabetesType: 'Type 1', diabetesExplained: 'Needs daily insulin to manage blood sugar', sentAgo: '10 min ago', avatarInitials: 'AT'),
    PatientRequest(id: '2', patientName: 'Sara Mahmoud', age: 17, diabetesType: 'Type 1', diabetesExplained: 'Needs daily insulin to manage blood sugar', sentAgo: '2 hours ago', avatarInitials: 'SM'),
    PatientRequest(id: '3', patientName: 'Layla Ibrahim', age: 34, diabetesType: 'Type 1', diabetesExplained: 'Needs daily insulin to manage blood sugar', sentAgo: 'Yesterday', avatarInitials: 'LI', status: GuardianRequestStatus.accepted),
    PatientRequest(id: '4', patientName: 'Khaled Nour', age: 28, diabetesType: 'Type 1', diabetesExplained: 'Needs daily insulin to manage blood sugar', sentAgo: '3 days ago', avatarInitials: 'KN', status: GuardianRequestStatus.declined),
  ];

  List<PatientRequest> get _pending  => _requests.where((r) => r.status == GuardianRequestStatus.pending).toList();
  List<PatientRequest> get _accepted => _requests.where((r) => r.status == GuardianRequestStatus.accepted).toList();
  List<PatientRequest> get _declined => _requests.where((r) => r.status == GuardianRequestStatus.declined).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  void _accept(PatientRequest r) {
    setState(() => r.status = GuardianRequestStatus.accepted);
    _snack('You are now watching over ${r.patientName} ', context);
  }

  void _decline(PatientRequest r) {
    setState(() => r.status = GuardianRequestStatus.declined);
    _snack('Request from ${r.patientName} declined', context);
  }

  void _snack(String msg, BuildContext context) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: colors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: OrientationBuilder(builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          return Column(children: [
            _buildHeader(context, isLandscape),
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildList(context, _pending,  showActions: true,  isLandscape: isLandscape),
                  _buildList(context, _accepted, showActions: false, isLandscape: isLandscape),
                  _buildList(context, _declined, showActions: false, isLandscape: isLandscape),
                ],
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLandscape) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, isLandscape ? 10 : 24, 20, 0),
      child: isLandscape
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Patient Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary, letterSpacing: -0.5)),
                Text('${_pending.length} waiting for your response', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              ])),
              const SizedBox(width: 16),
              Row(children: [
                _summaryPill(context, 'Pending',  _pending.length,  colors.warning),
                const SizedBox(width: 8),
                _summaryPill(context, 'Watching', _accepted.length, colors.accent),
                const SizedBox(width: 8),
                _summaryPill(context, 'Declined', _declined.length, colors.error),
              ]),
              const SizedBox(height: 10),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Patient Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('${_pending.length} waiting for your response', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
              const SizedBox(height: 16),
              Row(children: [
                _summaryPill(context, 'Pending',  _pending.length,  colors.warning),
                const SizedBox(width: 10),
                _summaryPill(context, 'Watching', _accepted.length, colors.accent),
                const SizedBox(width: 10),
                _summaryPill(context, 'Declined', _declined.length, colors.error),
              ]),
              const SizedBox(height: 16),
            ]),
    );
  }

  Widget _summaryPill(BuildContext context, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$count $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: colors.accent,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.accent,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Pending'),
            if (_pending.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(10)),
                child: Text('${_pending.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ])),
          const Tab(text: 'Watching'),
          const Tab(text: 'Declined'),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<PatientRequest> requests, {required bool showActions, required bool isLandscape}) {
    final colors = context.colors;
    if (requests.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(showActions ? 'No requests' : 'All good', style: TextStyle(fontSize: 48, color: colors.textSecondary)),
          const SizedBox(height: 12),
          Text(showActions ? 'No requests right now' : 'Nothing here yet',
              style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      );
    }

    final hPad = isLandscape ? 80.0 : 20.0;
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(
        context: context,
        request: requests[i],
        showActions: showActions,
        onAccept: () => _accept(requests[i]),
        onDecline: () => _decline(requests[i]),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PatientRequest request;
  final bool showActions;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final BuildContext context;

  const _RequestCard({
    required this.context,
    required this.request,
    required this.showActions,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = this.context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colors.accent.withValues(alpha: 0.15),
              child: Text(request.avatarInitials, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request.patientName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colors.textPrimary)),
              const SizedBox(height: 3),
              Text('Age ${request.age}', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.info_outline_rounded, size: 12, color: colors.accent),
                  const SizedBox(width: 5),
                  Flexible(child: Text(request.diabetesExplained, style: TextStyle(fontSize: 11, color: colors.accent, fontWeight: FontWeight.w600))),
                ]),
              ),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(request.sentAgo, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            ]),
          ]),
        ),
        if (showActions) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Watch Over ', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: request.status == GuardianRequestStatus.accepted
                      ? colors.accent.withValues(alpha: 0.1)
                      : colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status == GuardianRequestStatus.accepted ? ' Watching over' : ' Declined',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: request.status == GuardianRequestStatus.accepted ? colors.accent : colors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}