import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static const _kOrange = Color(0xFFE8581A);

  @override
  Widget build(BuildContext context) {
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
                            color: const Color(0xFFFFE8D5),
                            image: photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: photoUrl == null
                              ? Center(
                                  child: Text(initials,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: _kOrange)))
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
                                      : const Color(0xFFFFE8D5),
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
                                          : _kOrange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
            child: const Text('Log Out',
                style: TextStyle(
                    color: _kOrange, fontWeight: FontWeight.w700)),
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
                        : const Color(0xFFFFE8D5),
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