import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/services/supabase_service.dart';
import 'package:glucora_ai_companion/services/translated_text.dart'; // ← Add this import

class IobDetailSheet extends StatefulWidget {
  const IobDetailSheet({super.key});

  @override
  State<IobDetailSheet> createState() => _IobDetailSheetState();
}

class _IobDetailSheetState extends State<IobDetailSheet> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _iob;

  @override
  void initState() {
    super.initState();
    _fetchIOB();
  }

  Future<void> _fetchIOB() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() { _error = 'Not logged in'; _loading = false; });
        return;
      }

      final patientId = await getPatientProfileId(userId);
      if (patientId == null) {
        setState(() { _error = 'No patient profile'; _loading = false; });
        return;
      }

    final response = await supabase
        .from('insulin_on_board')
        .select()
        .eq('patient_id', patientId)
        .order('calculated_at', ascending: false)
        .limit(1);

    final data = response as List;

    setState(() {
      _iob = data.isNotEmpty ? data.first : null;
      _loading = false;
    });
    } catch (e) {
      setState(() { _error = 'Failed to load: $e'; _loading = false; });
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '–';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '–';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatDateTime(String? raw) {
    if (raw == null) return '–';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '–';
    final l = dt.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  double _safeDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.water_drop_rounded,
                    size: 19, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText('Insulin On Board',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                  Text(
                    _iob != null
                        ? 'Updated ${_timeAgo(_iob!['calculated_at'])}'
                        : '–',
                    style:
                        TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
                child: TranslatedText(_error!,
                    style: const TextStyle(color: Colors.red)))
          else if (_iob == null)
            Center(
                child: TranslatedText('No IOB data available',
                    style:
                        TextStyle(color: colors.textSecondary)))
          else ...[
            // ── Total IOB — big display ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  TranslatedText('Total IOB',
                      style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TranslatedText(
                        _safeDouble(_iob!['total_iob_units'])
                            .toStringAsFixed(2),
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: colors.primary),
                      ),
                      const SizedBox(width: 6),
                      TranslatedText('U',
                          style: TextStyle(
                              fontSize: 20,
                              color: colors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Basal / Bolus split ──
            Row(
              children: [
                Expanded(
                  child: _miniCard(
                    context,
                    label: 'Basal IOB',
                    value:
                        '${_safeDouble(_iob!['basal_iob_units']).toStringAsFixed(2)} U',
                    icon: Icons.tune_rounded,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniCard(
                    context,
                    label: 'Bolus IOB',
                    value:
                        '${_safeDouble(_iob!['bolus_iob_units']).toStringAsFixed(2)} U',
                    icon: Icons.flash_on_rounded,
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Decay info ──
            Row(
              children: [
                Expanded(
                  child: _miniCard(
                    context,
                    label: 'DIA',
                    value:
                        '${_safeDouble(_iob!['dia_minutes']).toStringAsFixed(0)} min',
                    icon: Icons.hourglass_bottom_rounded,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniCard(
                    context,
                    label: 'Peak',
                    value:
                        '${_safeDouble(_iob!['peak_minutes']).toStringAsFixed(0)} min',
                    icon: Icons.show_chart_rounded,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniCard(
                    context,
                    label: 'Doses',
                    value:
                        _safeDouble(_iob!['contributing_dose_count']).toStringAsFixed(0),
                    icon: Icons.medication_rounded,
                    color: colors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Decay model + timestamps ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  _infoRow(context, 'Decay Model',
                      _iob!['decay_model']?.toString() ?? '–'),
                  _divider(colors),
                  _infoRow(context, 'Calculated At',
                      _formatDateTime(_iob!['calculated_at'])),
                  _divider(colors),
                  _infoRow(context, 'Expires At',
                      _formatDateTime(_iob!['expires_at'])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          TranslatedText(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary)),
          const SizedBox(height: 2),
          TranslatedText(label,
              style:
                  TextStyle(fontSize: 10, color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TranslatedText(label,
              style:
                  TextStyle(fontSize: 13, color: colors.textSecondary)),
          TranslatedText(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _divider(GlucoraColors colors) => Divider(
        height: 1,
        thickness: 1,
        color: colors.textSecondary.withValues(alpha: 0.1),
      );
}