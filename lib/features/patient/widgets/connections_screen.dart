import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'connections_controller.dart';

// ─────────────────────────────────────────────────────────────
// ConnectionsScreen  (StatefulWidget – UI only)
// ─────────────────────────────────────────────────────────────
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  late final ConnectionsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConnectionsController()..loadConnections();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Confirm + remove ──────────────────────────────────────
  void _confirmRemove(ConnectionPerson person) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: TranslatedText('Remove ${person.role}'),
        content: TranslatedText(
          'Remove ${person.name}? They will no longer see your data.',
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _controller.removeConnection(person);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TranslatedText('${person.name} removed.'),
                    backgroundColor: colors.error,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: TranslatedText('Failed to remove: $e'),
                    backgroundColor: colors.error,
                  ),
                );
              }
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

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary),
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
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _controller.loadConnections,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _GlobalLocationToggle(
                  controller: _controller,
                  onError: (msg) => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                    content: TranslatedText(msg),
                    backgroundColor: colors.error,
                  )),
                ),
                const SizedBox(height: 32),
                _ConnectionSection(
                  title: 'Guardians',
                  icon: Icons.shield_outlined,
                  people: _controller.guardians,
                  emptyMessage: 'No guardians connected yet.',
                  controller: _controller,
                  onRemove: _confirmRemove,
                  onError: (msg) => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                    content: TranslatedText(msg),
                    backgroundColor: colors.error,
                  )),
                ),
                const SizedBox(height: 32),
                _ConnectionSection(
                  title: 'Doctors',
                  icon: Icons.medical_services_outlined,
                  people: _controller.doctors,
                  emptyMessage: 'No doctors connected yet.',
                  controller: _controller,
                  onRemove: _confirmRemove,
                  onError: (msg) => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                    content: TranslatedText(msg),
                    backgroundColor: colors.error,
                  )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _GlobalLocationToggle
// ─────────────────────────────────────────────────────────────
class _GlobalLocationToggle extends StatelessWidget {
  final ConnectionsController controller;
  final void Function(String) onError;

  const _GlobalLocationToggle({
    required this.controller,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sharing = controller.globalLocationSharing;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: sharing
            ? colors.primary.withValues(alpha: 0.07)
            : colors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sharing
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
                  color: sharing
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  sharing
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  color: sharing ? colors.primary : colors.error,
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
                      sharing
                          ? 'Your location is visible to connections'
                          : 'Hidden from everyone',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: sharing,
                onChanged: (v) async {
                  try {
                    await controller.toggleGlobalSharing(v);
                  } catch (e) {
                    onError('Failed to update: $e');
                  }
                },
                activeThumbColor: colors.primary,
              ),
            ],
          ),
          if (!sharing) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: colors.error),
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
}

// ─────────────────────────────────────────────────────────────
// _ConnectionSection
// ─────────────────────────────────────────────────────────────
class _ConnectionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ConnectionPerson> people;
  final String emptyMessage;
  final ConnectionsController controller;
  final void Function(ConnectionPerson) onRemove;
  final void Function(String) onError;

  const _ConnectionSection({
    required this.title,
    required this.icon,
    required this.people,
    required this.emptyMessage,
    required this.controller,
    required this.onRemove,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
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
          _EmptySection(icon: icon, message: emptyMessage)
        else
          ...people.map(
            (p) => _PersonCard(
              person: p,
              controller: controller,
              onRemove: onRemove,
              onError: onError,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _EmptySection
// ─────────────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 32,
              color: colors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          TranslatedText(
            message,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _PersonCard
// ─────────────────────────────────────────────────────────────
class _PersonCard extends StatelessWidget {
  final ConnectionPerson person;
  final ConnectionsController controller;
  final void Function(ConnectionPerson) onRemove;
  final void Function(String) onError;

  const _PersonCard({
    required this.person,
    required this.controller,
    required this.onRemove,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSharing = controller.sharingMap[person.connectionId] ?? true;
    final effectivelySharing = controller.effectivelySharing(person);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.textSecondary.withValues(alpha: 0.15)),
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
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      colors.primary.withValues(alpha: 0.12),
                  child: TranslatedText(
                    person.initials,
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
                        person.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TranslatedText(
                        person.role == 'Guardian' &&
                                person.relationship.isNotEmpty
                            ? '${person.role} · ${person.relationship}'
                            : person.role,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.person_remove_outlined,
                      color: colors.error, size: 20),
                  onPressed: () => onRemove(person),
                ),
              ],
            ),
          ),
          // Contact details
          if (person.phone.isNotEmpty || person.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  if (person.phone.isNotEmpty)
                    _ContactRow(
                      icon: Icons.phone_outlined,
                      text: person.phone,
                    ),
                  if (person.email.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _ContactRow(
                      icon: Icons.email_outlined,
                      text: person.email,
                    ),
                  ],
                ],
              ),
            ),
          // Location sharing footer
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
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
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
                        : !controller.globalLocationSharing
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
                  onChanged: controller.globalLocationSharing
                      ? (val) async {
                          try {
                            await controller.togglePersonSharing(
                                person, val);
                          } catch (e) {
                            onError('Failed: $e');
                          }
                        }
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
}

// ─────────────────────────────────────────────────────────────
// _ContactRow
// ─────────────────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              style:
                  TextStyle(fontSize: 13, color: colors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
