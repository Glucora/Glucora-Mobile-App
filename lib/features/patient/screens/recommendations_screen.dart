  import 'package:flutter/material.dart';
  import 'package:glucora_ai_companion/core/theme/color_extension.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import '../../../../services/ai_service.dart';
  import '../../../../services/supabase_service.dart';
  import 'package:glucora_ai_companion/shared/widgets/translated_text.dart'; // ← Add this import


  // ─── DISPLAY MODEL ────────────────────────────────────────────────────────────
  class _RecCard {
    final String id;
    final String category;
    final String title;
    final String message;
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

  factory _RecCard.fromRow(Map<String, dynamic> row) {
    // convert all fields safely
    final id = row['id']?.toString() ?? '';
    final category = row['category']?.toString() ?? 'general';
    final message = row['message']?.toString() ?? '';
    final isRead = row['is_read'] as bool? ?? false;

    DateTime createdAt;
    final rawCreated = row['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else if (rawCreated is int) {
      // epoch milliseconds
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreated);
    } else {
      createdAt = DateTime.now();
    }

    return _RecCard(
      id: id,
      category: category,
      title: _titleFor(category),
      message: message,
      isRead: isRead,
      createdAt: createdAt,
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
    bool _loading = true;
    bool _refreshing = false;
    String? _error;

    List<_RecCard> _cards = [];
    double? _currentGlucose;
    double? _predictedGlucose;

    String _authUserId = '';
    int? _patientProfileId;

    @override
    void initState() {
      super.initState();
      _init();
    }

    Future<void> _init() async {
      setState(() { _loading = true; _error = null; });
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception('Please log in first.');
        _authUserId = user.id;

        final pid = await getPatientProfileId(_authUserId);
        if (pid == null) throw Exception('No patient profile found.');
        _patientProfileId = pid;

        await _loadSaved();
        await _refreshFromAPI();
      } catch (e) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }

  Future<void> _loadSaved() async {
    final rows = await getLatestRecommendations(
        patientProfileId: _patientProfileId!,
        limit: 3, // latest 3 recommendations
    );

    if (!mounted) return;
    setState(() {
      _cards = rows.map(_RecCard.fromRow).toList();
      _loading = false;
    });
  }

    Future<void> _refreshFromAPI() async {
      if (!mounted) return;
      setState(() { _refreshing = true; _error = null; });

      try {
        final reading = await getLatestGlucoseReading(_patientProfileId!);
        if (reading != null) _currentGlucose = (reading['value_mg_dl'] as num).toDouble();

        final prediction = await getLatestPrediction(_patientProfileId!);
        if (prediction != null) _predictedGlucose = (prediction['predicted_value_mg_dl'] as num).toDouble();

        if (_currentGlucose == null) {
          setState(() {
            _error = 'No glucose readings found yet. Connect your sensor to get personalized advice.';
            _refreshing = false;
          });
          return;
        }

        _predictedGlucose ??= _currentGlucose! + 15;

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

        for (final rec in aiRecs) {
          await saveRecommendation(
            patientProfileId: _patientProfileId!,
            category: rec.category,
            message: rec.message,
          );
        }

        await _loadSaved();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = 'Could not get recommendations: '
              '${e.toString().replaceFirst('Exception: ', '')}';
        });
      } finally {
        if (mounted) setState(() { _refreshing = false; });
      }
    }

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
            child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          ),
          title: TranslatedText('Recommendations',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          actions: [
            _refreshing
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
                    onPressed: _refreshFromAPI,
                  ),
          ],
        ),
        body: _loading
            ? _buildLoading(colors)
            : RefreshIndicator(
                onRefresh: _refreshFromAPI,
                color: colors.primary,
                child: _buildBody(colors),
              ),
      );
    }

    Widget _buildLoading(dynamic colors) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            TranslatedText('Loading your recommendations...',
                style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          ]),
        );

    Widget _buildBody(dynamic colors) {
      if (_error != null) {
        return Padding(
        padding: const EdgeInsets.all(16),
        child: _buildErrorBanner(colors),
      );
      }

      if (_cards.isEmpty) return _buildEmptyState(colors);

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCard(colors, card),
          );
        },
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: TranslatedText(_error!, style: const TextStyle(fontSize: 12, color: Colors.red, height: 1.4)),
            ),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _refreshFromAPI,
            child: TranslatedText('Tap to retry', style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

  Widget _buildEmptyState(dynamic colors) {
      return Center( // ✅ Replaced top padding with Center
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24), // Keeps text from touching screen edges
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Icon(
                Icons.lightbulb_outline_rounded, 
                size: 52, 
                color: colors.textSecondary.withAlpha(80)
              ),
              const SizedBox(height: 16),
              TranslatedText(
                'No recommendations yet',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600, 
                  color: colors.textPrimary
                )
              ),
              const SizedBox(height: 8),
              TranslatedText(
                'Tap the refresh button to get AI-generated recommendations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13, 
                  color: colors.textSecondary, 
                  height: 1.5
                ),
              ),
            ]
          ),
        ),
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
              BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: card.color.withAlpha(28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(card.icon, color: card.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TranslatedText(card.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: 6),
                TranslatedText(card.message,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5)),
              ]),
            ),
          ]),
        ),
      );
    }
  }