import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glucora_ai_companion/core/theme/app_theme.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/providers/glucose_provider.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IobDetailSheet extends StatefulWidget {
  const IobDetailSheet({super.key});

  @override
  State<IobDetailSheet> createState() => _IobDetailSheetState();
}

class _IobDetailSheetState extends State<IobDetailSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _init());
  }

  Future<void> _init() async {
    final provider = context.read<GlucoseProvider>();
    if (provider.patientProfileId == null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) await provider.init(user.id);
    } else {
      await provider.loadLatestIob();
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

    return Consumer<GlucoseProvider>(
      builder: (context, provider, _) {
        final iob = provider.latestIob;

        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                        iob != null
                            ? 'Updated ${_timeAgo(iob['calculated_at'])}'
                            : '–',
                        style: TextStyle(
                            fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (provider.errorMessage != null)
                Center(
                  child: TranslatedText(provider.errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                )
              else if (iob == null)
                Center(
                  child: TranslatedText('No IOB data available',
                      style: TextStyle(color: colors.textSecondary)),
                )
              else ...[
                // ── Total IOB ──
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
                            _safeDouble(iob['total_iob_units'])
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
                      child: _miniCard(context,
                          label: 'Basal IOB',
                          value:
                              '${_safeDouble(iob['basal_iob_units']).toStringAsFixed(2)} U',
                          icon: Icons.tune_rounded,
                          color: const Color(0xFF4CAF50)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniCard(context,
                          label: 'Bolus IOB',
                          value:
                              '${_safeDouble(iob['bolus_iob_units']).toStringAsFixed(2)} U',
                          icon: Icons.flash_on_rounded,
                          color: const Color(0xFFFF9800)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Decay info ──
                Row(
                  children: [
                    Expanded(
                      child: _miniCard(context,
                          label: 'DIA',
                          value:
                              '${_safeDouble(iob['dia_minutes']).toStringAsFixed(0)} min',
                          icon: Icons.hourglass_bottom_rounded,
                          color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniCard(context,
                          label: 'Peak',
                          value:
                              '${_safeDouble(iob['peak_minutes']).toStringAsFixed(0)} min',
                          icon: Icons.show_chart_rounded,
                          color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniCard(context,
                          label: 'Doses',
                          value: _safeDouble(iob['contributing_dose_count'])
                              .toStringAsFixed(0),
                          icon: Icons.medication_rounded,
                          color: colors.primary),
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
                        color:
                            colors.textSecondary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      _infoRow(context, 'Decay Model',
                          iob['decay_model']?.toString() ?? '–'),
                      _divider(colors),
                      _infoRow(context, 'Calculated At',
                          _formatDateTime(iob['calculated_at'])),
                      _divider(colors),
                      _infoRow(context, 'Expires At',
                          _formatDateTime(iob['expires_at'])),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
              style: TextStyle(
                  fontSize: 10, color: colors.textSecondary)),
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