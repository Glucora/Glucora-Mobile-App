// lib\features\guardian\screens\guardian_home_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/guardian_patient_model.dart';
import 'guardian_patient_detail_screen.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = _supabase.auth.currentUser!.id;
      print('👤 Current Guardian User ID: $userId');

      // Step 1: Get connections with user info
      final connectionsResp = await _supabase
          .from('guardian_patient_connections')
          .select('''
            patient_id, 
            relationship, 
            users!patient_id (
              full_name, 
              age, 
              phone_no
            )
          ''')
          .eq('guardian_id', userId)
          .eq('status', 'accepted');

      final connections = connectionsResp as List;
      print('📱 Found ${connections.length} connections');
      
      if (connections.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allPatients = [];
          _isLoading = false;
        });
        return;
      }

      // Step 2: Get patient_profile IDs from user UUIDs
      final patientUserIds = connections
          .map((r) => r['patient_id'] as String)
          .toList();
      
      print('📋 Patient UUIDs: $patientUserIds');

      final profilesResp = await _supabase
          .from('patient_profile')
          .select('id, user_id')
          .inFilter('user_id', patientUserIds);

      // Create mapping: user_uuid -> patient_profile_id
      final Map<String, int> uuidToProfileId = {};
      for (final p in (profilesResp as List)) {
        final userUuid = p['user_id'] as String;
        final profileId = p['id'] as int;
        uuidToProfileId[userUuid] = profileId;
        print('🔗 Mapping: User $userUuid -> Profile ID $profileId');
      }

      final patientProfileIds = uuidToProfileId.values.toList();
      print('📊 Profile IDs: $patientProfileIds');

      // Step 3: Fetch glucose readings for ALL patients at once
      final readingsResp = await _supabase
          .from('glucose_readings')
          .select('patient_id, value_mg_dl, trend, recorded_at')
          .inFilter('patient_id', patientProfileIds)
          .order('recorded_at', ascending: false);

      // Step 4: Fetch insulin doses for today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day)
          .toUtc()
          .toIso8601String();

      final dosesResp = await _supabase
          .from('insulin_doses')
          .select('patient_id, delivery_method, delivered_at')
          .inFilter('patient_id', patientProfileIds)
          .gte('delivered_at', startOfDay);

      // Step 5: Fetch device status
      final devicesResp = await _supabase
          .from('devices')
          .select('patient_id, device_type, is_active')
          .inFilter('patient_id', patientUserIds);

      // Build device status map
      final Map<String, Map<String, bool>> deviceStatusByUuid = {};
      for (final d in devicesResp as List) {
        final uuid = d['patient_id'] as String;
        final type = (d['device_type'] as String? ?? '').toLowerCase();
        final active = d['is_active'] as bool? ?? false;
        
        deviceStatusByUuid.putIfAbsent(uuid, () => {'sensor': false, 'pump': false});
        
        if (type.contains('cgm') || type.contains('sensor')) {
          if (active) deviceStatusByUuid[uuid]!['sensor'] = true;
        }
        if (type.contains('pump')) {
          if (active) deviceStatusByUuid[uuid]!['pump'] = true;
        }
      }

      // Group readings by patient_profile_id
      final Map<int, List<Map<String, dynamic>>> readingsByPatient = {};
      for (final r in readingsResp as List) {
        final patientId = r['patient_id'] as int;
        readingsByPatient.putIfAbsent(patientId, () => []);
        readingsByPatient[patientId]!.add(Map<String, dynamic>.from(r));
      }

      // Group doses by patient_profile_id
      final Map<int, List<Map<String, dynamic>>> dosesByPatient = {};
      for (final d in dosesResp as List) {
        final patientId = d['patient_id'] as int;
        dosesByPatient.putIfAbsent(patientId, () => []);
        dosesByPatient[patientId]!.add(Map<String, dynamic>.from(d));
      }

      if (!mounted) return;
      
      // Build patient list with CORRECT data mapping
      final List<GuardianPatient> builtPatients = [];
      
      for (final row in connections) {
        final user = row['users'] as Map<String, dynamic>?;
        final patientUuid = row['patient_id'] as String;
        final profileId = uuidToProfileId[patientUuid];
        
        // Skip if no profile ID found (shouldn't happen)
        if (profileId == null) {
          print('❌ ERROR: No profile ID for UUID: $patientUuid');
          continue;
        }
        
        final name = user?['full_name'] as String? ?? 'Unknown';
        final age = (user?['age'] as num?)?.toInt() ?? 0;
        final phone = user?['phone_no'] as String? ?? '';
        final relationship = row['relationship'] as String? ?? 'Guardian';
        
        // Get readings for THIS SPECIFIC patient using their profile ID
        final patientReadings = readingsByPatient[profileId] ?? [];
        
        // Get the latest reading
        Map<String, dynamic>? latestReading;
        int glucose = 0;
        String trend = 'stable';
        
        if (patientReadings.isNotEmpty) {
          // Readings are already ordered by recorded_at descending from the query
          latestReading = patientReadings.first;
          glucose = (latestReading['value_mg_dl'] as num?)?.toInt() ?? 0;
          trend = latestReading['trend'] as String? ?? 'stable';
        }
        
        final lastSeen = latestReading != null
            ? _timeAgo(latestReading['recorded_at'] as String)
            : 'No readings';
        
        // Get doses for THIS SPECIFIC patient
        final patientDoses = dosesByPatient[profileId] ?? [];
        final allAutomatic = patientDoses.isNotEmpty &&
            patientDoses.every((d) => d['delivery_method'] == 'Pump');
        
        // Get device status for THIS SPECIFIC patient
        final deviceStatus = deviceStatusByUuid[patientUuid];
        final sensorConnected = deviceStatus?['sensor'] ?? false;
        final pumpActive = deviceStatus?['pump'] ?? false;
        
        print('✅ Building patient: $name');
        print('   UUID: $patientUuid -> Profile ID: $profileId');
        print('   Glucose: $glucose mg/dL (from ${patientReadings.length} readings)');
        print('   Doses today: ${patientDoses.length}');
        print('   Devices: Sensor=$sensorConnected, Pump=$pumpActive');
        
        builtPatients.add(GuardianPatient(
          profileId: profileId,
          id: patientUuid,
          patientId: patientUuid,
          name: name,
          age: age,
          relationship: relationship,
          glucoseValue: glucose,
          glucoseTrend: trend,
          sensorConnected: sensorConnected,
          pumpActive: pumpActive,
          dosesToday: patientDoses.length,
          allDosesAutomatic: allAutomatic,
          lastSeenTime: lastSeen,
          phoneNumber: phone,
        ));
      }
      
      print('🎉 Successfully built ${builtPatients.length} patients');
      
      setState(() {
        _allPatients = builtPatients;
        _isLoading = false;
      });
      
    } catch (e, stackTrace) {
      print('❌ GUARDIAN FETCH ERROR: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load patients: $e');
      }
    }
  }

  String _timeAgo(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dateTime);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (e) {
      return 'Unknown';
    }
  }

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

  // FIXED: Improved search function
  List<GuardianPatient> get _filteredPatients {
    final filtered = _allPatients.where((patient) {
      final query = _query.toLowerCase().trim();
      
      if (query.isEmpty) {
        return _filterStatus == null || patient.overallStatus == _filterStatus;
      }
      
      // Search across multiple fields
      final matchesName = patient.name.toLowerCase().contains(query);
      final matchesRelationship = patient.relationship.toLowerCase().contains(query);
      final matchesStatus = patient.overallStatus.toLowerCase().contains(query);
      final matchesGlucoseLabel = patient.glucoseLabel.toLowerCase().contains(query);
      
      final matchesSearch = matchesName || matchesRelationship || matchesStatus || matchesGlucoseLabel;
      final matchesFilter = _filterStatus == null || patient.overallStatus == _filterStatus;
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // Sort by priority: emergency -> attention -> good
    filtered.sort((a, b) {
      const priority = {'emergency': 0, 'attention': 1, 'good': 2};
      final priorityA = priority[a.overallStatus] ?? 2;
      final priorityB = priority[b.overallStatus] ?? 2;
      return priorityA.compareTo(priorityB);
    });
    
    return filtered;
  }

  int get _emergencyCount =>
      _allPatients.where((p) => p.overallStatus == 'emergency').length;
      
  int get _attentionCount =>
      _allPatients.where((p) => p.overallStatus == 'attention').length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final patients = _filteredPatients;
    
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context),
            
            // Search and Filter Section
            _buildSearchAndFilter(context),
            
            // Patient List Section
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

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
        
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Watching over ${_allPatients.length} ${_allPatients.length == 1 ? 'person' : 'people'}',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusPills(context),
        ],
      ),
    );
  }

  Widget _buildStatusPills(BuildContext context) {
    final colors = context.colors;
    final goodCount = _allPatients.where((p) => p.overallStatus == 'good').length;
    
    return Row(
      children: [
        _buildPill(
          context,
          '$goodCount Doing well',
          colors.accent,
          colors.accent.withValues(alpha: 0.1),
        ),
        const SizedBox(width: 8),
        if (_attentionCount > 0)
          _buildPill(
            context,
            '$_attentionCount Worth a look',
            colors.warning,
            colors.warning.withValues(alpha: (0.1)),
          ),
        if (_emergencyCount > 0) ...[
          const SizedBox(width: 8),
          _buildPill(
            context,
            '$_emergencyCount Check on them',
            colors.error,
            colors.error.withValues(alpha: 0.1),
          ),
        ],
      ],
    );
  }

  Widget _buildPill(BuildContext context, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
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
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (value) {
                  setState(() => _query = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, relationship...',
                  hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: colors.textSecondary, size: 18),
                          onPressed: () {
                            setState(() {
                              _query = '';
                              _searchCtrl.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showFilterSheet(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _filterStatus != null ? colors.accent : colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.filter_list,
                color: _filterStatus != null ? Colors.white : colors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(BuildContext context, List<GuardianPatient> patients) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        return _buildPatientCard(context, patients[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty
                ? 'No patients match "$_query"'
                : 'No patients found',
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (_filterStatus != null || _query.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _filterStatus = null;
                  _query = '';
                  _searchCtrl.clear();
                });
              },
              child: Text(
                'Clear filters',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, GuardianPatient patient) {
    final colors = context.colors;
    final statusColor = _getStatusColor(patient.overallStatus, colors);
    final statusBgColor = _getStatusBgColor(patient.overallStatus, colors);
    final glucoseColor = _getGlucoseColor(patient, colors);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: patient.overallStatus == 'good'
              ? colors.textSecondary.withValues(alpha: 0.2)
              : statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Patient Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: statusBgColor,
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${patient.relationship} • Age ${patient.age}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(patient.overallStatus),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Glucose Info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  '${patient.glucoseValue}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: glucoseColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'mg/dL',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: glucoseColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getTrendIcon(patient.glucoseTrend),
                        size: 14,
                        color: glucoseColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        patient.glucoseLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: glucoseColor,
                        ),
                      ),
                    ],
                  ),
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
                    ),
                    const SizedBox(height: 4),
                    _buildDeviceStatus(
                      Icons.water_drop,
                      'Pump',
                      patient.pumpActive,
                      colors,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Device Alerts
          if (!patient.sensorConnected || !patient.pumpActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  if (!patient.sensorConnected)
                    _buildAlertChip('Sensor is off', colors.error, colors),
                  if (!patient.sensorConnected && !patient.pumpActive)
                    const SizedBox(width: 8),
                  if (!patient.pumpActive)
                    _buildAlertChip('Pump is paused', colors.error, colors),
                ],
              ),
            ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildActionButton(
                  Icons.call,
                  'Call',
                  colors.accent,
                  () => _makePhoneCall(patient.phoneNumber),
                  colors,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.message,
                  'SMS',
                  const Color(0xFF34B7F1),
                  () => _sendSMS(patient.phoneNumber),
                  colors,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _navigateToDetail(patient),
                  child: Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
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

  Widget _buildDeviceStatus(IconData icon, String label, bool isActive, GlucoraColors colors) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: isActive ? colors.accent : colors.textSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          isActive ? label : '$label off',
          style: TextStyle(
            fontSize: 10,
            color: isActive ? colors.accent : colors.textSecondary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertChip(String text, Color color, GlucoraColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
    GlucoraColors colors,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        currentFilter: _filterStatus,
        onFilterSelected: (filter) {
          setState(() => _filterStatus = filter);
        },
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('No phone number available');
      return;
    }
    
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('No phone number available');
      return;
    }
    
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      _showErrorSnackBar('Could not launch messaging app');
    }
  }

  void _navigateToDetail(GuardianPatient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuardianPatientDetailScreen(patient: patient),
      ),
    );
  }

  // Helper methods for styling
  Color _getStatusColor(String status, GlucoraColors colors) {
    switch (status) {
      case 'emergency': return colors.error;
      case 'attention': return colors.warning;
      default: return colors.accent;
    }
  }

  Color _getStatusBgColor(String status, GlucoraColors colors) {
    switch (status) {
      case 'emergency': return colors.error.withValues(alpha: 0.1);
      case 'attention': return colors.warning.withValues(alpha: 0.1);
      default: return colors.accent.withValues(alpha: 0.1);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'emergency': return 'Check on them';
      case 'attention': return 'Worth a look';
      default: return 'Doing well';
    }
  }

  Color _getGlucoseColor(GuardianPatient patient, GlucoraColors colors) {
    switch (patient.glucoseLabel) {
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

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'up': return Icons.trending_up;
      case 'down': return Icons.trending_down;
      default: return Icons.trending_flat;
    }
  }
}

// Filter Bottom Sheet
class _FilterBottomSheet extends StatelessWidget {
  final String? currentFilter;
  final Function(String?) onFilterSelected;

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              Text(
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
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterOption(
            context,
            null,
            'All Patients',
            'Show all patients',
            colors.textSecondary,
            colors.background,
          ),
          const SizedBox(height: 8),
          _buildFilterOption(
            context,
            'good',
            'Doing Well',
            'Blood sugar in normal range',
            colors.accent,
            colors.accent.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          _buildFilterOption(
            context,
            'attention',
            'Worth a Look',
            'Blood sugar slightly off',
            colors.warning,
            colors.warning.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          _buildFilterOption(
            context,
            'emergency',
            'Check on Them',
            'Immediate attention needed',
            colors.error,
            colors.error.withValues(alpha: 0.1),
          ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String? value,
    String title,
    String subtitle,
    Color color,
    Color bgColor,
  ) {
    final colors = Theme.of(context).extension<GlucoraColors>()!;
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
            color: isSelected ? color : colors.textSecondary.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
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