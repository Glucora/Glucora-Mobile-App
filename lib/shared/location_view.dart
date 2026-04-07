// lib\shared\location_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';

// Modular model used by both screens
class LocationPatientInfo {
  final String patientUserId;
  final String fullName;
  LocationPatientInfo({required this.patientUserId, required this.fullName});
}

class LocationView extends StatefulWidget {
  final LocationPatientInfo patient;
  final bool isLandscape;
  final String userRole; // 'doctor' or 'guardian'

  const LocationView({
    super.key,
    required this.patient,
    required this.isLandscape,
    required this.userRole,
  });

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  double? _lat;
  double? _lng;
  String _lastSeen = 'Loading...';
  bool _loading = true;
  bool _isSharing = true;
  RealtimeChannel? _channel;
  RealtimeChannel? _sharingChannel;

  @override
  void initState() {
    super.initState();
    _fetchAndListen();
  }

  Future<void> _fetchAndListen() async {
    final supabase = Supabase.instance.client;
    final String connectionTable = widget.userRole == 'doctor'
        ? 'doctor_patient_connections'
        : 'guardian_patient_connections';

    final String roleIdField = widget.userRole == 'doctor'
        ? 'doctor_id'
        : 'guardian_id';

    try {
      // 1. Check sharing status based on role
      final connection = await supabase
          .from(connectionTable)
          .select('is_sharing')
          .eq('patient_id', widget.patient.patientUserId)
          .eq(roleIdField, supabase.auth.currentUser!.id)
          .maybeSingle();

      if (connection != null && mounted) {
        setState(() => _isSharing = connection['is_sharing'] ?? true);
      }

      if (_isSharing) {
        await _fetchLocation();

        // 2. Listen for location updates
        _channel = supabase
            .channel('location_${widget.patient.patientUserId}')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'patient_locations',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'patient_id',
                value: widget.patient.patientUserId,
              ),
              callback: (payload) {
                if (!mounted || !_isSharing) return;
                final row = payload.newRecord;
                setState(() {
                  _lat = (row['latitude'] as num).toDouble();
                  _lng = (row['longitude'] as num).toDouble();
                  _lastSeen = _timeAgo(row['updated_at']);
                });
              },
            )
            .subscribe();
      } else {
        setState(() => _loading = false);
      }

      // 3. Listen for sharing status changes
      _sharingChannel = supabase
          .channel('sharing_${widget.patient.patientUserId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: connectionTable,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'patient_id',
              value: widget.patient.patientUserId,
            ),
            callback: (payload) {
              if (!mounted) return;
              final newSharing = payload.newRecord['is_sharing'] ?? true;
              setState(() {
                _isSharing = newSharing;
                if (!newSharing) {
                  _lat = null;
                  _lng = null;
                } else {
                  _fetchLocation();
                }
              });
            },
          )
          .subscribe();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchLocation() async {
    try {
      final data = await Supabase.instance.client
          .from('patient_locations')
          .select()
          .eq('patient_id', widget.patient.patientUserId)
          .single();

      if (mounted) {
        setState(() {
          _lat = (data['latitude'] as num).toDouble();
          _lng = (data['longitude'] as num).toDouble();
          _lastSeen = _timeAgo(data['updated_at']);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return 'Unknown';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void _openInMaps() async {
    if (_lat == null || _lng == null) return;
    final uri = Uri.parse('geo:$_lat,$_lng?q=$_lat,$_lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _sharingChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_loading)
      return Center(child: CircularProgressIndicator(color: colors.accent));

    if (!_isSharing || _lat == null || _lng == null) {
      return _buildDisabledView(colors);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: widget.isLandscape
                ? Row(
                    children: [
                      Expanded(flex: 3, child: _mapCard()),
                      const SizedBox(width: 14),
                      Expanded(flex: 2, child: _lastSeenCard()),
                    ],
                  )
                : Column(
                    children: [
                      _mapCard(),
                      const SizedBox(height: 14),
                      _lastSeenCard(),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledView(GlucoraColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            !_isSharing ? 'Sharing is disabled' : 'Location not available',
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _mapCard() {
    final colors = context.colors;
    return Container(
      height: widget.isLandscape ? 260 : 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(_lat!, _lng!),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_lat!, _lng!),
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFE76F51),
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Updated $_lastSeen',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lastSeenCard() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIVE LOCATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
