import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'guardian_patient_detail_screen.dart';

//  MOCK DATA MODEL 

class _PatientSummary {
  final String name;
  final int age;
  final String glucoseLabel;
  final int glucoseValue;
  final String glucoseTrend;
  final String overallStatus;
  final String lastMeal;
  final String lastMealTime;
  final bool sensorConnected;
  final bool pumpActive;
  final int dosesToday;
  final bool allDosesAutomatic;
  final String lastSeenTime;
  final String phoneNumber;

  const _PatientSummary({
    required this.name,
    required this.age,
    required this.glucoseLabel,
    required this.glucoseValue,
    required this.glucoseTrend,
    required this.overallStatus,
    required this.lastMeal,
    required this.lastMealTime,
    required this.sensorConnected,
    required this.pumpActive,
    required this.dosesToday,
    required this.allDosesAutomatic,
    required this.lastSeenTime,
    required this.phoneNumber,
  });
}

//  SCREEN 

class GuardianHomeScreen extends StatelessWidget {
  const GuardianHomeScreen({super.key});

  static const _patient = _PatientSummary(
    name: 'Ahmed',
    age: 24,
    glucoseLabel: 'In Range',
    glucoseValue: 118,
    glucoseTrend: 'stable',
    overallStatus: 'good',
    lastMeal: 'Lunch',
    lastMealTime: '1:05 PM',
    sensorConnected: true,
    pumpActive: true,
    dosesToday: 4,
    allDosesAutomatic: true,
    lastSeenTime: '5 min ago',
    phoneNumber: '+201012345678',
  );

  //  Status helpers 

  Color get _statusColor {
    switch (_patient.overallStatus) {
      case 'emergency': return const Color(0xFFE63946);
      case 'attention': return const Color(0xFFE76F51);
      default:          return const Color(0xFF2A9D8F);
    }
  }

  Color get _glucoseColor {
    switch (_patient.glucoseLabel) {
      case 'Too high':
      case 'Very high': return const Color(0xFFE63946);
      case 'A bit high': return const Color(0xFFE76F51);
      case 'Too low':
      case 'Very low':  return const Color(0xFFE63946);
      default:          return const Color(0xFF2A9D8F);
    }
  }

  String get _statusEmoji {
    switch (_patient.overallStatus) {
      case 'emergency': return 'Emergency';
      case 'attention': return 'Warning';
      default:          return 'Good';
    }
  }

  String get _statusMessage {
    switch (_patient.overallStatus) {
      case 'emergency':
        return '${_patient.name} needs help right now';
      case 'attention':
        return '${_patient.name} needs some attention';
      default:
        return '${_patient.name} is doing well';
    }
  }

  IconData get _trendIcon {
    switch (_patient.glucoseTrend) {
      case 'up':   return Icons.trending_up_rounded;
      case 'down': return Icons.trending_down_rounded;
      default:     return Icons.trending_flat_rounded;
    }
  }

  String get _trendLabel {
    switch (_patient.glucoseTrend) {
      case 'up':   return 'Rising';
      case 'down': return 'Falling';
      default:     return 'Steady';
    }
  }

  void _callPatient(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${_patient.name}...',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF2A9D8F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _smsPatient(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening SMS for ${_patient.name}...',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFE76F51),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),


      
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                //  Top greeting & header 
                SliverToBoxAdapter(child: _buildHeader(context, isLandscape)),

                //  Status banner 
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, isLandscape ? 12 : 20),
                    child: _buildStatusBanner(context),
                  ),
                ),

                //  Main content — portrait: stacked, landscape: 2-col 
                isLandscape
                    ? SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildGlucoseCard(context),
                                    const SizedBox(height: 14),
                                    _buildDeviceStatusCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Right column
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildInsulinCard(),
                                    const SizedBox(height: 14),
                                    _buildQuickActionsCard(context),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildGlucoseCard(context),
                            const SizedBox(height: 14),
                            _buildDeviceStatusCard(),
                            const SizedBox(height: 14),
                            _buildInsulinCard(),
                            const SizedBox(height: 14),
                            _buildQuickActionsCard(context),
                          ]),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  //  HEADER 

  Widget _buildHeader(BuildContext context, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, isLandscape ? 12 : 24, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, Guardian ',
                  style: TextStyle(
                    fontSize: isLandscape ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2B3C),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Here\'s how ${_patient.name} is doing today',
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // View details button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GuardianPatientDetailScreen(
                  patientName: _patient.name,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE76F51).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE76F51).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Text('View Details',
                    style: TextStyle(
                      color: Color(0xFFE76F51),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFE76F51), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  STATUS BANNER 

  Widget _buildStatusBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _statusColor,
            _statusColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(_statusEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Last updated ${_patient.lastSeenTime}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // SOS button for emergencies
          if (_patient.overallStatus == 'emergency')
            GestureDetector(
              onTap: () => _callPatient(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('CALL',
                  style: TextStyle(
                    color: Color(0xFFE63946),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  //  GLUCOSE CARD 

  Widget _buildGlucoseCard(BuildContext context) {
    return _card(
      child: Row(
        children: [
          // Big glucose reading
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _glucoseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Blood Sugar Right Now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_patient.glucoseValue}',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: _glucoseColor,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('mg/dL',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Plain-English label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _glucoseColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_trendIcon, color: _glucoseColor, size: 15),
                      const SizedBox(width: 5),
                      Text('${_patient.glucoseLabel} · $_trendLabel',
                        style: TextStyle(
                          color: _glucoseColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Visual gauge
          SizedBox(
            width: 64,
            height: 100,
            child: CustomPaint(
              painter: _GlucoseGaugePainter(
                value: _patient.glucoseValue,
                color: _glucoseColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  DEVICE STATUS CARD 

  Widget _buildDeviceStatusCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardLabel('Devices'),
          const SizedBox(height: 10),
          _deviceChip(
            icon: Icons.sensors,
            label: 'Sensor',
            status: _patient.sensorConnected ? 'Connected' : 'Disconnected',
            ok: _patient.sensorConnected,
          ),
          const SizedBox(height: 8),
          _deviceChip(
            icon: Icons.water_drop_outlined,
            label: 'Pump',
            status: _patient.pumpActive ? 'Active' : 'Paused',
            ok: _patient.pumpActive,
          ),
        ],
      ),
    );
  }

  Widget _deviceChip({
    required IconData icon,
    required String label,
    required String status,
    required bool ok,
  }) {
    final color = ok ? const Color(0xFF2A9D8F) : const Color(0xFFE63946);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2B3C))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  //  INSULIN CARD 

  Widget _buildInsulinCard() {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5B8CF5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_rounded,
                color: Color(0xFF5B8CF5), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_patient.dosesToday} insulin doses today',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2B3C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _patient.allDosesAutomatic
                      ? 'All given automatically by the device ': 'Some doses were given manually',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  QUICK ACTIONS 

  Widget _buildQuickActionsCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardLabel('Quick Actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.call_rounded,
                  label: 'Call ${_patient.name}',
                  color: const Color(0xFF2A9D8F),
                  onTap: () => _callPatient(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  icon: Icons.sms_rounded,
                  label: 'Send SMS',
                  color: const Color(0xFFE76F51),
                  onTap: () => _smsPatient(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  color: const Color(0xFF5B8CF5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuardianPatientDetailScreen(
                        patientName: _patient.name,
                        initialTab: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  HELPERS 

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade400,
        letterSpacing: 0.8,
      ),
    );
  }
}

//  GLUCOSE GAUGE PAINTER 

class _GlucoseGaugePainter extends CustomPainter {
  final int value;
  final Color color;

  _GlucoseGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double minVal = 40;
    const double maxVal = 300;
    const double low = 70;
    const double high = 180;

    final double fillRatio =
        ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);

    final double barWidth = 12;
    final double barX = size.width / 2 - barWidth / 2;
    final double barHeight = size.height * 0.85;
    final double barTop = (size.height - barHeight) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barTop, barWidth, barHeight),
        const Radius.circular(6),
      ),
      trackPaint,
    );

    // Target zone highlight
    final lowY = barTop + barHeight * (1 - ((high - minVal) / (maxVal - minVal)));
    final highY = barTop + barHeight * (1 - ((low - minVal) / (maxVal - minVal)));
    final zonePaint = Paint()
      ..color = const Color(0xFF2A9D8F).withValues(alpha: 0.15);
    canvas.drawRect(Rect.fromLTWH(barX, lowY, barWidth, highY - lowY), zonePaint);

    // Fill
    final fillHeight = barHeight * fillRatio;
    final fillTop = barTop + barHeight - fillHeight;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, fillTop, barWidth, fillHeight),
        const Radius.circular(6),
      ),
      fillPaint,
    );

    // Indicator dot
    final dotY = fillTop;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(barX + barWidth / 2, dotY), 7, dotPaint);
    canvas.drawCircle(
      Offset(barX + barWidth / 2, dotY),
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels
    final labelStyle = TextStyle(
        fontSize: 8.5,
        color: Colors.grey.shade400,
        fontWeight: FontWeight.w600);
    for (final entry in {'High': high, 'Low': low}.entries) {
      final y = barTop +
          barHeight * (1 - ((entry.value - minVal) / (maxVal - minVal)));
      final tp = TextPainter(
        text: TextSpan(text: entry.key, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(barX - tp.width - 4, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}