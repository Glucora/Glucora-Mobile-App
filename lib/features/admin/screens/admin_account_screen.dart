// =============================================================================
// AdminAccountScreen
// =============================================================================
// Displays the currently-logged-in admin's own profile: name, age, email,
// phone, address, and profile picture. The admin can edit all these fields
// and toggle push notifications. A small FAQ section answers common admin
// questions.
//
// Data flow:
//   1. On mount, _fetchUserData() reads the admin's row from the `users`
//      Supabase table.
//   2. A Realtime channel (_profileChannel) listens for UPDATE events on that
//      same row so the UI refreshes automatically if the profile is changed
//      from another device or session.
//   3. Edits flow through _EditAdminProfileScreen (a push route), come back
//      via Navigator.pop(result), and are written to Supabase by
//      _saveUserEdits().
//
// Image-cache busting strategy (important!):
//   Supabase Storage URLs are stable — the same path always returns the same
//   URL even after the file is replaced. Flutter's image cache keyed on the
//   URL would therefore keep showing the old picture. To force a fresh fetch
//   we strip any previous cache-buster query-param and append a new timestamp:
//     `$baseUrl?t=<epoch-ms>`
//   Additionally, every reload bumps _reloadKey, which is used as a ValueKey
//   on BaseProfileTab. A new key causes Flutter to completely unmount the old
//   widget tree (discarding its in-memory Image state) and mount a fresh one.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glucora_ai_companion/core/theme/color_extension.dart';
import 'package:glucora_ai_companion/shared/widgets/translated_text.dart';
import 'package:glucora_ai_companion/shared/widgets/profile_picture.dart';
import 'package:glucora_ai_companion/services/profile_picture_service.dart';
import 'package:glucora_ai_companion/shared/widgets/base_profile_tab.dart';
import 'package:glucora_ai_companion/shared/widgets/shared_profile_field.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  // ── Profile field state ────────────────────────────────────────────────────
  String _name = '';
  int _age = 0;
  String _email = '';
  String _phone = '';
  String _address = '';

  // Holds the cache-busted URL for the admin's profile picture.
  // Empty string means "no picture set" — BaseProfileTab/ProfilePicture will
  // show initials as a fallback.
  String _profilePictureUrl = '';

  // Controls whether the loading spinner or the profile content is shown.
  bool _loading = true;

  // Non-null when a Supabase fetch fails; triggers the error/retry UI.
  String? _error;

  // Whether push notifications are enabled for this admin session.
  // Persisted remotely in a future iteration; stored locally for now.
  bool _notificationsEnabled = true;

  // ── Image-cache / rebuild key ──────────────────────────────────────────────
  // Incremented on every _fetchUserData call. Passed as ValueKey to
  // BaseProfileTab so Flutter fully destroys and recreates the widget tree —
  // including any ProfilePicture widget that caches the decoded image — on
  // each reload, preventing stale bytes from the previous fetch from showing.
  int _reloadKey = 0;

  // Supabase Realtime channel reference; kept so we can unsubscribe in dispose.
  RealtimeChannel? _profileChannel;

  // ── Static FAQ data ────────────────────────────────────────────────────────
  // Defined as a static list so it's shared across all instances (there is
  // normally only one) and is not rebuilt on every setState call.
  static final List<FaqEntry> _faqs = [
    FaqEntry(
      'How do I manage system users?',
      'Navigate to the More tab and select User Management. From there you can add, edit, or deactivate user accounts for doctors, patients, and other admins.',
    ),
    FaqEntry(
      'How do I assign devices to patients?',
      'Go to Device Management under the More tab. Select a device and use the Assign option to link it to a patient. You can also reassign or unassign devices.',
    ),
    FaqEntry(
      'How do I configure alert rules?',
      'Open Alert Rules from the More tab. You can create new rules, set thresholds for glucose levels, and choose notification channels for each alert type.',
    ),
    FaqEntry(
      'How do I manage role permissions?',
      'Access Role Management from the More tab. You can view existing roles, modify their permissions, or create custom roles to control access across the system.',
    ),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchUserData();          // Load profile data immediately on mount.
    _subscribeToProfileChanges(); // Start listening for remote changes.
  }

  @override
  void dispose() {
    // Always unsubscribe from the Realtime channel when leaving the screen to
    // avoid memory leaks and ghost callbacks after the widget is unmounted.
    _profileChannel?.unsubscribe();
    super.dispose();
  }

  // ── Realtime subscription ──────────────────────────────────────────────────

  /// Sets up a Supabase Realtime channel that fires _fetchUserData whenever
  /// the admin's row in the `users` table is updated.
  ///
  /// The filter `id = <userId>` ensures we only react to changes for THIS
  /// admin and not any other user row.
  void _subscribeToProfileChanges() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return; // Not authenticated; nothing to subscribe to.

    _profileChannel = supabase
        .channel('admin_profile_$userId') // Unique channel name per user.
        .onPostgresChanges(
          event: PostgresChangeEvent.update, // Only listen for UPDATE events.
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            // Ensure the widget is still mounted before calling setState
            // (the callback can fire even after navigation away).
            if (mounted) _fetchUserData();
          },
        )
        .subscribe();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  /// Fetches the admin's full profile row from Supabase and updates local
  /// state. Also increments _reloadKey to force BaseProfileTab to rebuild
  /// from scratch (see image-cache strategy in the file header).
  Future<void> _fetchUserData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not logged in');

      // Fetch only the columns we need to minimise payload size.
      final response = await Supabase.instance.client
          .from('users')
          .select(
              'id, full_name, email, role, is_active, created_at, phone_no, age, address, profile_picture_url')
          .eq('id', session.user.id)
          .single(); // Throws if 0 or >1 rows match.

      // Guard: the widget may have been disposed while the async call was in
      // flight (e.g. user navigated away). Skip state updates if so.
      if (!mounted) return;

      setState(() {
        _name    = response['full_name'] as String? ?? 'Admin User';
        _email   = response['email']    as String? ?? '';
        _phone   = response['phone_no'] as String? ?? '';
        _age     = response['age']      as int?    ?? 0;
        _address = response['address']  as String? ?? '';

        // ── Cache-bust the profile picture URL ──────────────────────────────
        // 1. Read the raw stored URL (may already have an old ?t= param).
        final rawUrl = response['profile_picture_url'] as String? ?? '';

        // 2. Strip any existing query string so we always build from the
        //    canonical base path. Without this step, the URL would grow
        //    indefinitely (e.g. `...?t=111?t=222?t=333`) and the comparison
        //    logic in Flutter's HTTP cache would never detect the same resource.
        final baseUrl =
            rawUrl.contains('?') ? rawUrl.split('?').first : rawUrl;

        // 3. Append a fresh millisecond timestamp. Each reload produces a
        //    unique URL, guaranteeing Flutter's image cache treats it as a
        //    new resource and makes a real network request.
        _profilePictureUrl = baseUrl.isNotEmpty
            ? '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}'
            : '';

        // 4. Bump the rebuild key — see header comment for why this matters.
        _reloadKey++;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error   = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Profile save ───────────────────────────────────────────────────────────

  /// Writes the edited profile fields to the `users` table and refreshes
  /// local state on success, or shows a SnackBar error on failure.
  Future<void> _saveUserEdits(
    String newName,
    String newEmail,
    String newPhone,
    String newAddress,
    int newAge,
  ) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;

      await Supabase.instance.client.from('users').update({
        'full_name': newName,
        'email':     newEmail,
        'phone_no':  newPhone,
        'age':       newAge,
        'address':   newAddress,
      }).eq('id', session.user.id);

      // Mirror the saved values into local state immediately so the UI
      // updates without waiting for the next _fetchUserData call.
      setState(() {
        _name    = newName;
        _email   = newEmail;
        _phone   = newPhone;
        _address = newAddress;
        _age     = newAge;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Profile updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Pushes _EditAdminProfileScreen and, if the user saved changes, persists
  /// them and re-fetches (to capture any server-side transformations and bust
  /// the image cache if the picture was also changed).
  Future<void> _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditAdminProfileScreen(
          name:              _name,
          age:               _age,
          email:             _email,
          phone:             _phone,
          address:           _address,
          profilePictureUrl: _profilePictureUrl,
        ),
      ),
    );

    // result is null when the user pressed Back without saving.
    if (result != null) {
      await _saveUserEdits(
        result['name'],
        result['email'],
        result['phone'],
        result['address'],
        result['age'],
      );
      // Re-fetch so any server-side changes (e.g. profile picture updated
      // inside the edit screen) are reflected and the image cache is busted.
      await _fetchUserData();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Show a full-screen spinner while the initial data load is in progress.
    if (_loading) {
      return Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: colors.primary)));
    }

    // Show an error state with a Retry button if the fetch failed.
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TranslatedText('Failed to load profile',
                  style: TextStyle(color: colors.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: _fetchUserData,
                  child: const TranslatedText('Retry')),
            ],
          ),
        ),
      );
    }

    return BaseProfileTab(
      // ── ValueKey trick ────────────────────────────────────────────────────
      // Providing a new key on every reload forces Flutter to unmount the
      // old BaseProfileTab subtree entirely (including any widget-internal
      // image cache state) and mount a completely fresh one. Without this,
      // ProfilePicture widgets that have already decoded an image may ignore
      // the updated URL and continue displaying the stale bytes.
      key: ValueKey(_reloadKey),

      name:              _name,
      age:               _age,
      roleBadge:         'Administrator',
      profilePictureUrl: _profilePictureUrl,

      notificationsEnabled:   _notificationsEnabled,
      onNotificationsChanged: (v) => setState(() => _notificationsEnabled = v),

      // Callbacks wired to local methods defined above.
      onPictureChanged: _fetchUserData,  // Re-fetch after a picture upload.
      onEditProfile:    _editProfile,
      onLogout:         () => showLogoutDialog(context),

      faqs: _faqs,

      // The info card displays read-only contact details with dividers between
      // each row. buildInfoCard / buildInfoRow are helper functions defined in
      // shared_profile_field.dart to keep all role-specific account screens
      // visually consistent.
      infoCard: buildInfoCard(
        context,
        child: Column(
          children: [
            buildInfoRow(context, Icons.email_outlined, 'Email', _email),
            Divider(
                height: 16,
                color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(context, Icons.phone_outlined, 'Phone',
                _phone.isNotEmpty ? _phone : 'Not set'),
            Divider(
                height: 16,
                color: colors.textSecondary.withValues(alpha: 0.3)),
            buildInfoRow(context, Icons.location_on_outlined, 'Address',
                _address.isNotEmpty ? _address : 'Not set'),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _EditAdminProfileScreen  (private — only used by AdminAccountScreen)
// =============================================================================
// A push-route screen that lets the admin edit their own profile fields and
// optionally change their profile picture. When the admin taps Save, this
// screen pops and returns a Map<String, dynamic> containing the updated values
// to the caller (AdminAccountScreen._editProfile). The caller is then
// responsible for persisting those values.
//
// Profile picture changes are handled in-screen via ProfilePicture's
// `isEditable` flag, which internally calls ProfilePictureService to upload
// the new image to Supabase Storage and then invokes the `onPictureChanged`
// callback (_onPictureChanged) to refresh the local URL with a new cache buster.
// =============================================================================
class _EditAdminProfileScreen extends StatefulWidget {
  final String  name;
  final int     age;
  final String  email;
  final String  phone;
  final String  address;
  final String? profilePictureUrl;

  const _EditAdminProfileScreen({
    required this.name,
    required this.age,
    required this.email,
    required this.phone,
    required this.address,
    this.profilePictureUrl,
  });

  @override
  State<_EditAdminProfileScreen> createState() =>
      _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<_EditAdminProfileScreen> {
  // Each text field owns its controller so we can read the current value at
  // save time and dispose them properly on widget teardown.
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  // Local copy of the profile picture URL, updated after a successful upload.
  String _profilePictureUrl = '';

  @override
  void initState() {
    super.initState();
    // Initialise each controller with the values passed in from the parent.
    _nameController    = TextEditingController(text: widget.name);
    _ageController     = TextEditingController(text: widget.age.toString());
    _emailController   = TextEditingController(text: widget.email);
    _phoneController   = TextEditingController(text: widget.phone);
    _addressController = TextEditingController(text: widget.address);
    _profilePictureUrl = widget.profilePictureUrl ?? '';
  }

  @override
  void dispose() {
    // TextEditingControllers hold references to platform text input resources.
    // Always dispose them to avoid resource leaks.
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ── Picture change handler ─────────────────────────────────────────────────

  /// Called by ProfilePicture after a successful upload. Re-fetches the
  /// canonical URL from ProfilePictureService and appends a cache-buster so
  /// the newly uploaded image is shown immediately in the edit screen.
  void _onPictureChanged() {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    ProfilePictureService.getProfilePictureUrl(userId).then((url) {
      if (mounted) {
        final rawUrl  = url ?? '';
        final baseUrl = rawUrl.contains('?') ? rawUrl.split('?').first : rawUrl;
        setState(() {
          _profilePictureUrl = baseUrl.isNotEmpty
              ? '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}'
              : '';
        });
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0, // Flat appearance; no drop shadow under the app bar.
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary),
          onPressed: () => Navigator.pop(context), // Discard and go back.
        ),
        title: TranslatedText(
          'Edit Profile',
          style: TextStyle(
              color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // The Save button lives in the AppBar so it's always visible without
          // the user having to scroll to a button at the bottom of the form.
          TextButton(
            onPressed: _save,
            child: TranslatedText(
              'Save',
              style: TextStyle(
                  color:       colors.primary,
                  fontSize:    16,
                  fontWeight:  FontWeight.w600),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          // Wrap in a scroll view so the fields are reachable on smaller
          // screens or when the keyboard is open.
          child: Column(
            children: [
              // ── Profile picture ───────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    ProfilePicture(
                      userId:     Supabase.instance.client.auth.currentUser!.id,
                      imageUrl:   _profilePictureUrl,
                      size:       100,
                      isEditable: true, // Shows the edit overlay/tap target.
                      onPictureChanged: _onPictureChanged,
                      displayName: _nameController.text,
                    ),
                    const SizedBox(height: 8),
                    TranslatedText(
                      'Tap to change profile picture',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Editable form fields ──────────────────────────────────────
              // buildProfileField is a shared helper that wraps a TextField in
              // a consistent decorated container (icon, label, border style).
              buildProfileField(
                  context, 'Name', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              buildProfileField(context, 'Age', _ageController,
                  Icons.cake_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              buildProfileField(context, 'Email', _emailController,
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              buildProfileField(context, 'Phone', _phoneController,
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              buildProfileField(context, 'Address', _addressController,
                  Icons.location_on_outlined),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save logic ─────────────────────────────────────────────────────────────

  /// Validates (minimal — just trims whitespace and falls back to original
  /// values if a field was cleared) and pops the route with the updated data.
  ///
  /// The actual Supabase write is intentionally deferred to the parent
  /// (_AdminAccountScreenState._saveUserEdits). This keeps the edit screen
  /// focused on UI concerns and makes it easier to unit-test field parsing
  /// independently of the network layer.
  void _save() {
    final updatedName    = _nameController.text.trim();
    final updatedAge     = int.tryParse(_ageController.text.trim()) ?? widget.age;
    final updatedEmail   = _emailController.text.trim();
    final updatedPhone   = _phoneController.text.trim();
    final updatedAddress = _addressController.text.trim();

    Navigator.pop(context, {
      // Fall back to the original value if the admin cleared the field,
      // preventing accidental data loss from an empty submission.
      'name':    updatedName.isEmpty    ? widget.name    : updatedName,
      'age':     updatedAge,
      'email':   updatedEmail.isEmpty   ? widget.email   : updatedEmail,
      'phone':   updatedPhone.isEmpty   ? widget.phone   : updatedPhone,
      'address': updatedAddress.isEmpty ? widget.address : updatedAddress,
    });
  }
}