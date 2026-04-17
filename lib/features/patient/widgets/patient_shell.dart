import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/features/patient/screens/calorie_log_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/home_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/manual_log_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/weekly_report_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/patient_history_screen.dart';
import 'package:glucora_ai_companion/features/patient/screens/medication_screen.dart';
import 'package:glucora_ai_companion/features/guardian/widgets/guardian_shell.dart';
import 'package:flutter/services.dart';
import 'package:glucora_ai_companion/shared/screens/connection_requests_screen.dart';
import 'package:glucora_ai_companion/shared/screens/settings_screen.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';

// ─────────────────────────────────────────────────────────────
// PatientNavigation
// ─────────────────────────────────────────────────────────────
class PatientNavigation extends StatefulWidget {
  const PatientNavigation({super.key});

  @override
  State<PatientNavigation> createState() => _PatientNavigationState();
}

class _PatientNavigationState extends State<PatientNavigation> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    CalorieLogScreen(),
    ManualLogScreen(),
    MedicationScreen(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LocalizedDirectionality(
      child: Scaffold(
        backgroundColor: colors.background,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildNavBar(context),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.textSecondary.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavTile(
                icon: Icons.home_rounded,
                label: "Home",
                active: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavTile(
                icon: Icons.restaurant_menu_rounded,
                label: "Calories",
                active: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavTile(
                icon: Icons.edit_rounded,
                label: "Log",
                active: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavTile(
                icon: Icons.medication_rounded,
                label: "Meds",
                active: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavTile(
                icon: Icons.person_outline_rounded,
                label: "Profile",
                active: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _NavTile
// ─────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.primary : colors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            TranslatedText(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? colors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _ConnectionsScreen
// ─────────────────────────────────────────────────────────────
class _ConnectionsScreen extends StatefulWidget {
  const _ConnectionsScreen();

  @override
  State<_ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<_ConnectionsScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _globalLocationSharing = true;
  int? _patientLocationRowId;
  final Map<String, bool> _sharingMap = {};
  List<Map<String, dynamic>> _guardians = [];
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final userId = user.id;
      var locationRow = await supabase
          .from('patient_locations')
          .select('id, sharing_enabled')
          .eq('patient_id', userId)
          .maybeSingle();
      locationRow ??= await supabase
          .from('patient_locations')
          .insert({'patient_id': userId, 'sharing_enabled': true})
          .select('id, sharing_enabled')
          .single();
      _patientLocationRowId = locationRow['id'] as int;
      _globalLocationSharing = locationRow['sharing_enabled'] ?? true;

      final guardianRows = await supabase
          .from('guardian_patient_connections')
          .select(
            'id, guardian_id, relationship, is_sharing, users!guardian_id(full_name, email, phone_no)',
          )
          .eq('patient_id', userId)
          .eq('status', 'accepted');

      final doctorRows = await supabase
          .from('doctor_patient_connections')
          .select(
            'id, doctor_id, is_sharing, users!doctor_id(full_name, email, phone_no)',
          )
          .eq('patient_id', userId)
          .eq('status', 'accepted');

      final List<Map<String, dynamic>> guardians = [];
      for (final row in (guardianRows as List)) {
        final userInfo = row['users'] as Map<String, dynamic>?;
        final connectionId = row['id'].toString();
        guardians.add({
          'connectionId': connectionId,
          'name': userInfo?['full_name'] ?? 'Unknown',
          'email': userInfo?['email'] ?? '',
          'phone': userInfo?['phone_no'] ?? '',
          'relationship': row['relationship'] ?? '',
          'role': 'Guardian',
        });
        _sharingMap[connectionId] = row['is_sharing'] ?? true;
      }

      final List<Map<String, dynamic>> doctors = [];
      for (final row in (doctorRows as List)) {
        final userInfo = row['users'] as Map<String, dynamic>?;
        final connectionId = row['id'].toString();
        doctors.add({
          'connectionId': connectionId,
          'name': userInfo?['full_name'] ?? 'Unknown',
          'email': userInfo?['email'] ?? '',
          'phone': userInfo?['phone_no'] ?? '',
          'role': 'Doctor',
        });
        _sharingMap[connectionId] = row['is_sharing'] ?? true;
      }

      setState(() {
        _guardians = guardians;
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading connections: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onGlobalToggled(bool value) async {
    setState(() => _globalLocationSharing = value);
    try {
      await supabase
          .from('patient_locations')
          .update({'sharing_enabled': value})
          .eq('id', _patientLocationRowId!);
    } catch (e) {
      setState(() => _globalLocationSharing = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed to update: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  Future<void> _onPersonToggled(Map<String, dynamic> person, bool value) async {
    final connectionId = person['connectionId'] as String;
    final table = person['role'] == 'Guardian'
        ? 'guardian_patient_connections'
        : 'doctor_patient_connections';
    setState(() => _sharingMap[connectionId] = value);
    try {
      await supabase
          .from(table)
          .update({'is_sharing': value})
          .eq('id', int.parse(connectionId));
    } catch (e) {
      setState(() => _sharingMap[connectionId] = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeConnection(Map<String, dynamic> person) async {
    final connectionId = int.parse(person['connectionId'] as String);
    final table = person['role'] == 'Guardian'
        ? 'guardian_patient_connections'
        : 'doctor_patient_connections';
    try {
      await supabase.from(table).delete().eq('id', connectionId);
      setState(() {
        if (person['role'] == 'Guardian') {
          _guardians.removeWhere(
            (g) => g['connectionId'] == person['connectionId'],
          );
        } else {
          _doctors.removeWhere(
            (d) => d['connectionId'] == person['connectionId'],
          );
        }
        _sharingMap.remove(person['connectionId'] as String);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('${person['name']} removed.'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed to remove: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  void _confirmRemove(Map<String, dynamic> person) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: TranslatedText('Remove ${person['role']}'),
        content: TranslatedText(
          'Remove ${person['name']}? They will no longer see your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: TranslatedText(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeConnection(person);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const TranslatedText(
              'Remove',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Connections',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConnections,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  _buildGlobalToggle(colors),
                  const SizedBox(height: 32),
                  _buildSection(
                    colors: colors,
                    title: 'Guardians',
                    icon: Icons.shield_outlined,
                    people: _guardians,
                    emptyMessage: 'No guardians connected yet.',
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    colors: colors,
                    title: 'Doctors',
                    icon: Icons.medical_services_outlined,
                    people: _doctors,
                    emptyMessage: 'No doctors connected yet.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGlobalToggle(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _globalLocationSharing
            ? colors.primary.withValues(alpha: 0.07)
            : colors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _globalLocationSharing
              ? colors.primary.withValues(alpha: 0.25)
              : colors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _globalLocationSharing
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _globalLocationSharing
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  color: _globalLocationSharing ? colors.primary : colors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      'Location Sharing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      _globalLocationSharing
                          ? 'Your location is visible to connections'
                          : 'Hidden from everyone',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _globalLocationSharing,
                onChanged: _onGlobalToggled,
                activeThumbColor: colors.primary,
              ),
            ],
          ),
          if (!_globalLocationSharing) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: colors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      'Individual toggles are disabled while global sharing is off.',
                      style: TextStyle(fontSize: 12, color: colors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required dynamic colors,
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> people,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            TranslatedText(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TranslatedText(
                '${people.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (people.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.textSecondary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: colors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                TranslatedText(
                  emptyMessage,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...people.map((p) => _buildPersonCard(colors, p)),
      ],
    );
  }

  Widget _buildPersonCard(dynamic colors, Map<String, dynamic> person) {
    final connectionId = person['connectionId'] as String;
    final isSharing = _sharingMap[connectionId] ?? true;
    final name = person['name'] as String;
    final initials = name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();
    final effectivelySharing = isSharing && _globalLocationSharing;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  child: TranslatedText(
                    initials,
                    style: TextStyle(
                      color: colors.primary,
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
                      TranslatedText(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TranslatedText(
                        person['role'] == 'Guardian' &&
                                (person['relationship'] as String).isNotEmpty
                            ? '${person['role']} · ${person['relationship']}'
                            : person['role'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.person_remove_outlined,
                    color: colors.error,
                    size: 20,
                  ),
                  onPressed: () => _confirmRemove(person),
                ),
              ],
            ),
          ),
          if ((person['phone'] as String).isNotEmpty ||
              (person['email'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  if ((person['phone'] as String).isNotEmpty)
                    _contactRow(
                      colors,
                      Icons.phone_outlined,
                      person['phone'] as String,
                    ),
                  if ((person['email'] as String).isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _contactRow(
                      colors,
                      Icons.email_outlined,
                      person['email'] as String,
                    ),
                  ],
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: effectivelySharing
                  ? colors.primary.withValues(alpha: 0.05)
                  : colors.textSecondary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  effectivelySharing
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  size: 16,
                  color: effectivelySharing
                      ? colors.primary
                      : colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TranslatedText(
                    effectivelySharing
                        ? 'Seeing your location'
                        : !_globalLocationSharing
                        ? 'Blocked — global sharing is off'
                        : 'Location hidden from this person',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: effectivelySharing
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                Switch(
                  value: isSharing,
                  onChanged: _globalLocationSharing
                      ? (val) => _onPersonToggled(person, val)
                      : null,
                  activeThumbColor: colors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(dynamic colors, IconData icon, String text) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Copied: $text'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Row(
        children: [
          Icon(icon, size: 13, color: colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TranslatedText(
              text,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _BluetoothPairingScreen
// ─────────────────────────────────────────────────────────────
class _BluetoothPairingScreen extends StatelessWidget {
  const _BluetoothPairingScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Connect Device',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'Available Devices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _deviceTile(context, 'Dexcom G6', '80% battery', true),
              _deviceTile(context, 'Medtronic 780G', '45% battery', false),
              _deviceTile(context, 'Abbott Libre 3', 'Pairing mode', false),
              const SizedBox(height: 24),
              TranslatedText(
                'To pair a new device, put it in discovery mode and tap on it.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceTile(
    BuildContext context,
    String name,
    String status,
    bool isConnected,
  ) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bluetooth_rounded,
            size: 24,
            color: isConnected ? colors.primary : colors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                TranslatedText(
                  status,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TranslatedText(
                'Connected',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: TranslatedText('Pairing with $name...'),
                  duration: const Duration(seconds: 1),
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: TranslatedText(
                'Pair',
                style: TextStyle(color: colors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _EditProfileScreen
// ─────────────────────────────────────────────────────────────
class _EditProfileScreen extends StatefulWidget {
  final String name;
  final int age;
  final String? email;
  final String? phone;
  final String height;
  final String weight;

  const _EditProfileScreen({
    required this.name,
    required this.age,
    this.email,
    this.phone,
    required this.height,
    required this.weight,
  });

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _ageController = TextEditingController(text: widget.age.toString());
    _heightController = TextEditingController(text: widget.height);
    _weightController = TextEditingController(text: widget.weight);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TranslatedText(
          'Edit Profile',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: TranslatedText(
              'Save',
              style: TextStyle(
                color: colors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField(context, 'Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Email',
              _emailController,
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Height',
              _heightController,
              Icons.height,
              keyboardType: TextInputType.number,
              suffix: 'cm',
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Weight',
              _weightController,
              Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
              suffix: 'kg',
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Age',
              _ageController,
              Icons.cake_outlined,
              keyboardType: TextInputType.number,
              suffix: 'years',
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'Phone Number',
              _phoneController,
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? suffix,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        suffixText: suffix,
        suffixStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, size: 20, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colors.surface, // ✅ NOW USES THEME COLOR
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final newEmail = _emailController.text.trim();
      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();
      await supabase.auth.updateUser(
        UserAttributes(
          email: newEmail != user.email ? newEmail : null,
          data: {'full_name': newName, 'phone': newPhone},
        ),
      );
      final weightValue =
          double.tryParse(
            _weightController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      final heightValue =
          double.tryParse(
            _heightController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      final ageValue = int.tryParse(_ageController.text) ?? 0;
      await supabase
          .from('users')
          .update({
            'full_name': newName,
            'email': newEmail,
            'phone_no': newPhone,
            'age': ageValue,
          })
          .eq('id', user.id);
      await supabase
          .from('patient_profile')
          .update({'weight_kg': weightValue, 'height_cm': heightValue})
          .eq('user_id', user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, {
          'name': newName,
          'email': newEmail,
          'phone': newPhone,
          'age': ageValue,
          'height': "${heightValue.toInt()} cm",
          'weight': "${weightValue.toInt()} kgs",
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// _ProfileTab - UPDATED to use shared SettingsScreen
// ─────────────────────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  String _name = "";
  int _age = 0;
  String _height = "";
  String _phone = "";
  String _email = "";
  String _weight = "";
  String _profilePictureUrl = "";
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  final supabase = Supabase.instance.client;
  int? _openFaqIndex;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      var userData = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      userData ??= await supabase
          .from('users')
          .insert({'id': user.id, 'email': user.email, 'full_name': 'New User'})
          .select()
          .single();
      var patientData = await supabase
          .from('patient_profile')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      patientData ??= await supabase
          .from('patient_profile')
          .insert({'user_id': user.id, 'height_cm': 0, 'weight_kg': 0})
          .select()
          .single();
      setState(() {
        _name = userData?['full_name'] ?? "No Name";
        _phone = userData?['phone_no'] ?? "";
        _email = userData?['email'] ?? "";
        _age = (userData?['age'] ?? 0).toInt();
        _height = "${patientData?['height_cm'] ?? 0} cm";
        _weight = "${patientData?['weight_kg'] ?? 0} kg";
        _profilePictureUrl = userData?['profile_picture_url'] ?? "";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const TranslatedText('Log Out'),
        content: const TranslatedText(
          'Are you sure to log out of your account?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: TranslatedText(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const TranslatedText(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TranslatedText(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TranslatedText(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colors.textSecondary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          notificationsEnabled: _notificationsEnabled,
                          onNotificationsChanged: (notifications) {
                            setState(
                              () => _notificationsEnabled = notifications,
                            );
                          },
                          additionalSettings: [
                            _buildSettingsCard(
                              context,
                              icon: Icons.bluetooth_rounded,
                              title: 'Bluetooth Pairing',
                              subtitle: 'Connect your CGM sensor or pump',
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed('/bluetooth-pairing'),
                            ),
                            const SizedBox(height: 16),
                            _buildSettingsCard(
                              context,
                              icon: Icons.people_outline_rounded,
                              title: 'My Connections & Sharing',
                              subtitle: 'Doctors, guardians & location sharing',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const _ConnectionsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSettingsCard(
                              context,
                              icon: Icons.person_add_alt_1_rounded,
                              title: 'Connect with Care Team',
                              subtitle:
                                  'Find and connect with doctors & guardians',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ConnectionRequestsScreen(
                                        role: 'patient',
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  ProfilePicture(
                    userId: supabase.auth.currentUser!.id,
                    imageUrl: _profilePictureUrl,
                    size: 90,
                    isEditable: true,
                    onPictureChanged: () => _loadProfile(),
                    displayName: _name,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TranslatedText(
                        _name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _editProfile,
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    '$_age years',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoColumn(context, 'Height', _height),
                  Container(
                    height: 30,
                    width: 1,
                    color: colors.textSecondary.withValues(alpha: 0.2),
                  ),
                  _infoColumn(context, 'Weight', _weight),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TranslatedText(
              'Reports & History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeeklyReportScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.textSecondary.withValues(alpha: 0.2),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.insert_chart_outlined_rounded,
                              color: colors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TranslatedText(
                            'Weekly Report',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientHistoryScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.textSecondary.withValues(alpha: 0.2),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5B8CF5,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: Color(0xFF5B8CF5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TranslatedText(
                            'History & Export',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TranslatedText(
              'FAQs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _faqItem(
              context,
              0,
              "How do I connect my glucose monitor?",
              "Go to settings and connect your CGM device via Bluetooth.",
            ),
            _faqItem(
              context,
              1,
              "What do the glucose ranges mean?",
              "They indicate whether your sugar is low, normal, or high.",
            ),
            _faqItem(
              context,
              2,
              "Can I share data with my doctor?",
              "Yes, you can securely share your data with connected doctors.",
            ),
            _faqItem(
              context,
              3,
              "How accurate are the predictions?",
              "Predictions are AI-based and improve over time with more data.",
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final supabase = Supabase.instance.client;
                  final userId = supabase.auth.currentUser?.id;
                  if (userId == null) return;
                  try {
                    await supabase
                        .from('users')
                        .update({'role': 'guardian'})
                        .eq('id', userId);
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const GuardianMainScreen(),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TranslatedText('Failed to switch: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const TranslatedText(
                  'Switch to Guardian View',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: TranslatedText(
                    'Log Out',
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Column(
      children: [
        TranslatedText(
          label,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        TranslatedText(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _faqItem(
    BuildContext context,
    int index,
    String question,
    String answer,
  ) {
    final colors = context.colors;
    final isOpen = _openFaqIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _openFaqIndex = isOpen ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TranslatedText(
                    question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: colors.textSecondary,
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 10),
              TranslatedText(
                answer,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(
          name: _name,
          age: _age,
          email: _email,
          phone: _phone,
          height: _height,
          weight: _weight,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _name = result['name'];
        _email = result['email'];
        _phone = result['phone'];
        _age = result['age'];
        _height = result['height'];
        _weight = result['weight'];
      });
    }
  }
}
