import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/mentor_service.dart';
import '../services/theme_controller.dart';
import '../utils/color_utils.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    final user = FirebaseAuth.instance.currentUser;
    final isGoogleUser = user?.providerData
            .any((p) => p.providerId == 'google.com') ??
        false;

    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : null;
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;
    final initials =
        (displayName?.isNotEmpty == true ? displayName![0] : email.isNotEmpty ? email[0] : 'U')
            .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: Color(0xFF1A1A1A)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Account',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Avatar card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: lighten(accentColor, 0.32),
                            image: photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: photoUrl == null
                              ? Center(
                                  child: Text(initials,
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor)))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (displayName != null)
                                Text(displayName,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A))),
                              Text(email,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500])),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isGoogleUser
                                      ? const Color(0xFFE6F1FB)
                                      : lighten(accentColor, 0.32),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isGoogleUser
                                      ? 'Google account'
                                      : 'Email account',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isGoogleUser
                                          ? const Color(0xFF185FA5)
                                          : accentColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Appearance
                  const _SectionLabel(label: 'Appearance'),
                  const SizedBox(height: 10),
                  const _ThemeColorPicker(),
                  const SizedBox(height: 24),

                  // ── Actions
                  const _SectionLabel(label: 'Account'),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    subtitle: isGoogleUser
                        ? 'Not available for Google accounts'
                        : 'Send a reset link to your email',
                    disabled: isGoogleUser,
                    onTap: () =>
                        _changePassword(context, email, isGoogleUser),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    subtitle: 'Sign out of your account',
                    onTap: () => _confirmLogout(context),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Developer Tools'),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Clear Mentor Chat',
                    subtitle: 'Erase your conversation history with Mentor',
                    onTap: () => _confirmClearMentorChat(context),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Tread Carefully'),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete Account',
                    subtitle: 'Permanently remove your account and data',
                    isDestructive: true,
                    onTap: () =>
                        _confirmDelete(context, isGoogleUser),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Auth actions ──────────────────────────────────────────────────────────

  void _changePassword(
      BuildContext context, String email, bool isGoogle) async {
    if (isGoogle) return;
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);
      if (context.mounted) {
        _showSnack(context, 'Reset link sent to $email ✓',
            isError: false);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Failed to send reset email.',
            isError: true);
      }
    }
  }

  void _confirmLogout(BuildContext context) {
    final accentColor = context.read<ThemeController>().accentColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'You can always sign back in with your credentials.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await GoogleSignIn.instance.signOut();
              await FirebaseAuth.instance.signOut();
            },
            child: Text('Log Out',
                style: TextStyle(
                    color: accentColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, bool isGoogle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete account?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This permanently deletes your account and all your tasks. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount(context, isGoogle);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(BuildContext context, bool isGoogle) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      if (isGoogle) {
        // Re-authenticate with Google first using the new singleton
        final googleUser = await GoogleSignIn.instance.authenticate();
        if (googleUser == null) return;
        
        final auth = await googleUser.authentication;
        
        // Build the modern credential using only the idToken
        final cred = GoogleAuthProvider.credential(idToken: auth.idToken);
        
        await user.reauthenticateWithCredential(cred);
      }
      await user.delete();
      // Auth stream in main.dart handles redirect to login
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          _showSnack(
              context,
              'Please log out and log back in before deleting your account.',
              isError: true);
        }
      } else {
        if (context.mounted) {
          _showSnack(context, 'Could not delete account: ${e.message}',
              isError: true);
        }
      }
    }
  }

  void _confirmClearMentorChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Mentor chat?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This permanently deletes your conversation history with Mentor.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await MentorService.clearHistory();
              if (context.mounted) {
                _showSnack(context, 'Mentor chat cleared', isError: false);
              }
            },
            child: const Text('Clear',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[400],
            letterSpacing: 0.8));
  }
}

// ─── Theme color picker ───────────────────────────────────────────────────────

class _ThemeColorPicker extends StatelessWidget {
  const _ThemeColorPicker();

  Future<void> _openPicker(BuildContext context) async {
    final controller = context.read<ThemeController>();
    final originalColor = controller.accentColor;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ColorWheelSheet(),
    );
    // Swiped away without tapping Done — revert the live preview.
    if (saved != true) {
      controller.previewAccentColor(originalColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme Color',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  SizedBox(height: 2),
                  Text('Tap to pick a color',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Color wheel + brightness slider sheet ─────────────────────────────────────

class _ColorWheelSheet extends StatefulWidget {
  const _ColorWheelSheet();

  @override
  State<_ColorWheelSheet> createState() => _ColorWheelSheetState();
}

class _ColorWheelSheetState extends State<_ColorWheelSheet> {
  static const double _minBrightness = 0.35;
  static const double _maxBrightness = 0.85;

  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    final initial = HSVColor.fromColor(
        context.read<ThemeController>().accentColor);
    _hsv = initial.withValue(
        initial.value.clamp(_minBrightness, _maxBrightness));
  }

  void _update(HSVColor next) {
    setState(() => _hsv = next);
    context.read<ThemeController>().previewAccentColor(next.toColor());
  }

  void _save() {
    context.read<ThemeController>().setAccentColor(_hsv.toColor());
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(
              children: [
                const Text('Theme Color',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: _save,
                  child: Text('Done',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ColorWheel(hsv: _hsv, onChanged: _update),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.brightness_6_rounded,
                    color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: color,
                      thumbColor: color,
                      overlayColor: Colors.transparent,
                    ),
                    child: Slider(
                      value: _hsv.value,
                      min: _minBrightness,
                      max: _maxBrightness,
                      onChanged: (v) => _update(_hsv.withValue(v)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ColorWheel extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;
  const _ColorWheel({required this.hsv, required this.onChanged});

  static const double _size = 240;

  void _handle(Offset localPosition) {
    const center = Offset(_size / 2, _size / 2);
    const radius = _size / 2;
    final d = localPosition - center;
    final dist = d.distance.clamp(0.0, radius);
    final angle = atan2(d.dy, d.dx);
    final hue = (angle * 180 / pi + 360) % 360;
    final saturation = dist / radius;
    onChanged(hsv.withHue(hue).withSaturation(saturation));
  }

  @override
  Widget build(BuildContext context) {
    final rad = hsv.hue * pi / 180;
    final r = hsv.saturation * (_size / 2);
    final thumbX = _size / 2 + cos(rad) * r;
    final thumbY = _size / 2 + sin(rad) * r;

    return GestureDetector(
      onPanStart: (d) => _handle(d.localPosition),
      onPanUpdate: (d) => _handle(d.localPosition),
      onTapDown: (d) => _handle(d.localPosition),
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipOval(
              child: Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: List.generate(13, (i) {
                      final h = i * 30.0;
                      return HSVColor.fromAHSV(1, h % 360, 1, 1).toColor();
                    }),
                  ),
                ),
              ),
            ),
            ClipOval(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.white, Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: thumbX - 12,
              top: thumbY - 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hsv.toColor(),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool disabled;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    final color = disabled
        ? Colors.grey[300]!
        : isDestructive
            ? Colors.red
            : const Color(0xFF1A1A1A);

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey[50]
              : isDestructive
                  ? const Color(0xFFFFF0F0)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDestructive
              ? Border.all(color: Colors.red.withOpacity(0.2))
              : null,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: disabled
                    ? Colors.grey[100]
                    : isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : lighten(accentColor, 0.32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            if (!disabled)
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}