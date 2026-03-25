import 'package:flutter/material.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/ai_service.dart';
import '../../../services/supabase_service.dart';

// ─── DISPLAY MODEL ────────────────────────────────────────────────────────────

/// Everything the UI needs to render one recommendation card.
class _RecCard {
  final String id;          // ai_recommendations.id (uuid) — for mark-as-read
  final String category;    // 'dietary' | 'activity' | 'monitoring' | 'general'
  final String title;       // short heading
  final String message;     // full advice text
  final bool isRead;
  final DateTime createdAt;

  const _RecCard({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  /// Build from a Supabase ai_recommendations row.
  factory _RecCard.fromRow(Map<String, dynamic> row) {
    final category = (row['category'] as String? ?? 'general');
    return _RecCard(
      id: row['id'] as String,
      category: category,
      title: _titleFor(category),
      message: row['message'] as String? ?? '',
      isRead: row['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static String _titleFor(String category) {
    switch (category) {
      case 'dietary':    return 'Dietary advice';
      case 'activity':   return 'Physical activity';
      case 'monitoring': return 'What to monitor';
      default:           return 'Personalized advice';
    }
  }

  IconData get icon {
    switch (category) {
      case 'dietary':    return Icons.no_food_rounded;
      case 'activity':   return Icons.directions_walk_rounded;
      case 'monitoring': return Icons.loop_rounded;
      default:           return Icons.lightbulb_outline_rounded;
    }
  }

  Color get color {
    switch (category) {
      case 'dietary':    return const Color(0xFFEF5350);
      case 'activity':   return const Color(0xFF199A8E);
      case 'monitoring': return const Color(0xFFF9A825);
      default:           return const Color(0xFF5B8CF5);
    }
  }
}

// ─── SCREEN ───────────────────────────────────────────────────────────────────

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  // ── state ──
  bool _loading = true;
  bool _refreshing = false;   // separate flag so existing cards stay visible while refreshing
  String? _error;

  List<_RecCard> _cards = [];

  double? _currentGlucose;
  double? _predictedGlucose;

  String _authUserId = '';
  String _patientProfileId = '';

  // ── lifecycle ──

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ── data loading ─────────────────────────────────────────────────────────────

  /// Full initialisation: resolve IDs, load saved recs, then refresh from API.
  Future<void> _init() async {
    setState(() { _loading = true; _error = null; });

    try {
      // 1 — auth user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Please log in first.');
      _authUserId = user.id;

      // 2 — patient profile id (DIFFERENT from auth user id)
      final pid = await getPatientProfileId(_authUserId);
      if (pid == null) {
        throw Exception(
            'No patient profile found. Please complete your profile setup.');
      }
      _patientProfileId = pid;

      // 3 — load whatever is already saved in the DB immediately
      await _loadSaved();

      // 4 — fetch fresh glucose data and call the AI
      await _refreshFromAPI();

    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Load previously saved recommendations from ai_recommendations table.
  Future<void> _loadSaved() async {
  final rows = await getSavedRecommendations(
    patientProfileId: _patientProfileId, 
    limit: 20
  );
  if (!mounted) return;
  setState(() {
    _cards = rows.map(_RecCard.fromRow).toList();
  });
}

  /// Called on init AND on pull-to-refresh / refresh button.
  /// Fetches glucose, calls AI, saves new recs, reloads.
  Future<void> _refreshFromAPI() async {
    if (!mounted) return;
    setState(() { _refreshing = true; _error = null; });

    try {
      // ── Step A: get glucose reading ──────────────────────────────────────
      final reading = await getLatestGlucoseReading(_patientProfileId);
      if (reading != null) {
      _currentGlucose = (reading['glucose_value'] as num).toDouble();      }

      // ── Step B: get AI prediction ────────────────────────────────────────
      final prediction = await getLatestPrediction(_patientProfileId);
      String? predictionId;
      if (prediction != null) {
        _predictedGlucose = (prediction['predicted_value'] as num).toDouble(); 
        predictionId = prediction['id'] as String?;
      }

      // If no glucose data at all, show a clear message
      if (_currentGlucose == null) {
        setState(() {
          _error =
              'No glucose readings found yet. Connect your sensor to get personalized advice.';
          _refreshing = false;
        });
        return;
      }

      // If no prediction yet, estimate from current
      _predictedGlucose ??= _currentGlucose! + 15;

      // ── Step C: call OpenRouter AI ───────────────────────────────────────
      final aiRecs = await AIService.getRecommendations(
        currentGlucose: _currentGlucose!,
        predictedGlucose: _predictedGlucose!,
      );

      if (aiRecs.isEmpty) {
        setState(() {
          _error = 'The AI did not return any recommendations. Try again.';
          _refreshing = false;
        });
        return;
      }

      // ── Step D: save each recommendation to Supabase ─────────────────────
      final List<Map<String, dynamic>> saved = [];
      for (final rec in aiRecs) {
        final row = await saveRecommendation(
          patientProfileId: _patientProfileId,
          category: rec.category,
          message: rec.message,
          predictionId: predictionId,
        );
        if (row != null) saved.add(row);
      }

      // ── Step E: reload from DB so we show the real saved data ─────────────
      await _loadSaved();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not get recommendations: '
            '${e.toString().replaceFirst('Exception: ', '')}';
        _refreshing = false;
      });
    } finally {
      if (mounted) setState(() { _refreshing = false; });
    }
  }

  /// Mark a recommendation as read and update local state.
  Future<void> _markAsRead(_RecCard card) async {
    if (card.isRead) return;
    final ok = await markRecommendationAsRead(card.id);
    if (ok && mounted) {
      setState(() {
        _cards = _cards.map((c) {
          if (c.id == card.id) {
            return _RecCard(
              id: c.id, category: c.category, title: c.title,
              message: c.message, isRead: true, createdAt: c.createdAt,
            );
          }
          return c;
        }).toList();
      });
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
        ),
        title: Text(
          'Recommendations',
          style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          // Refresh button — visible even while loading
          _refreshing
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colors.primary),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
                  onPressed: _refreshFromAPI,
                  tooltip: 'Get fresh recommendations',
                ),
        ],
      ),
      body: _loading
          ? _buildLoadingState(colors)
          : RefreshIndicator(
              onRefresh: _refreshFromAPI,
              color: colors.primary,
              child: _buildBody(colors),
            ),
    );
  }

  Widget _buildLoadingState(dynamic colors) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: colors.primary),
        const SizedBox(height: 16),
        Text('Loading your recommendations...',
            style: TextStyle(fontSize: 13, color: colors.textSecondary)),
      ]),
    );
  }

  Widget _buildBody(dynamic colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [

        // ── Glucose context banner ─────────────────────────────────────────
        if (_currentGlucose != null) _buildGlucoseBanner(colors),
        if (_currentGlucose != null) const SizedBox(height: 16),

        // ── Error message ──────────────────────────────────────────────────
        if (_error != null) ...[
          _buildErrorBanner(colors),
          const SizedBox(height: 16),
        ],

        // ── Refreshing indicator (subtle, shown over existing cards) ───────
        if (_refreshing && _cards.isNotEmpty) ...[
          _buildRefreshingBanner(colors),
          const SizedBox(height: 14),
        ],

        // ── Empty state (no saved recs AND not loading) ────────────────────
        if (_cards.isEmpty && !_refreshing && _error == null)
          _buildEmptyState(colors),

        // ── Recommendation cards ───────────────────────────────────────────
        if (_cards.isNotEmpty) ...[
          Text(
            '${_cards.length} recommendation${_cards.length == 1 ? '' : 's'}',
            style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ..._cards.map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCard(colors, card),
              )),
        ],

        // ── Disclaimer ─────────────────────────────────────────────────────
        if (_cards.isNotEmpty) _buildDisclaimer(colors),
      ],
    );
  }

  // ── sub widgets ───────────────────────────────────────────────────────────

  Widget _buildGlucoseBanner(dynamic colors) {
    final statusColor = _currentGlucose! < 70
        ? const Color(0xFFE63946)
        : _currentGlucose! > 180
            ? const Color(0xFFF9A825)
            : const Color(0xFF199A8E);

    final statusText = _currentGlucose! < 70
        ? 'Low — below target'
        : _currentGlucose! > 180
            ? 'High — above target'
            : 'In range';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withAlpha(60)),
      ),
      child: Row(children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Current glucose: ${_currentGlucose!.toInt()} mg/dL — $statusText'
            '${_predictedGlucose != null ? '  ·  Predicted: ${_predictedGlucose!.toInt()} mg/dL' : ''}',
            style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w600,
                height: 1.4),
          ),
        ),
      ]),
    );
  }

  Widget _buildErrorBanner(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withAlpha(60)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_error!,
                style: const TextStyle(fontSize: 12, color: Colors.red, height: 1.4)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _refreshFromAPI,
              child: Text('Tap to retry',
                  style: TextStyle(
                      fontSize: 12,
                      color: colors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRefreshingBanner(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: colors.primary),
        ),
        const SizedBox(width: 10),
        Text('Getting fresh recommendations from AI...',
            style: TextStyle(fontSize: 12, color: colors.primary)),
      ]),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lightbulb_outline_rounded,
            size: 52, color: colors.textSecondary.withAlpha(80)),
        const SizedBox(height: 16),
        Text(
          'No recommendations yet',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure your glucose sensor is connected,\nthen tap the refresh button above.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13, color: colors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _refreshFromAPI,
          icon: Icon(Icons.refresh_rounded, color: colors.primary, size: 18),
          label: Text('Get recommendations',
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildCard(dynamic colors, _RecCard card) {
    return GestureDetector(
      onTap: () => _markAsRead(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: card.isRead
              ? Border.all(color: Colors.transparent)
              : Border.all(color: card.color.withAlpha(80), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: card.color.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(card.icon, color: card.color, size: 22),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    card.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary),
                  ),
                ),
                // Unread dot
                if (!card.isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: card.color, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 6),
              Text(
                card.message,
                style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 8),
              // Timestamp
              Text(
                _formatTime(card.createdAt),
                style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary.withAlpha(120)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildDisclaimer(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.warning_amber_rounded,
            size: 13, color: colors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Recommendations are AI-generated and for informational purposes only. '
            'Always consult your healthcare provider before making health decisions.',
            style: TextStyle(
                fontSize: 11, color: colors.textSecondary, height: 1.5),
          ),
        ),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}