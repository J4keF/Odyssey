import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color kDefaultAccentColor = Color(0xFFE8581A);

class ThemeController extends ChangeNotifier {
  Color _accentColor = kDefaultAccentColor;
  Color get accentColor => _accentColor;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;

  ThemeController() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    _docSub?.cancel();
    if (user == null) {
      _accentColor = kDefaultAccentColor;
      notifyListeners();
      return;
    }
    _docSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      final value = snap.data()?['accentColor'] as int?;
      final next = value != null ? Color(value) : kDefaultAccentColor;
      if (next != _accentColor) {
        _accentColor = next;
        notifyListeners();
      }
    });
  }

  // Updates the in-memory color only — for live preview while dragging.
  void previewAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }

  // Commits the color, persisting it so it syncs across devices.
  Future<void> setAccentColor(Color color) async {
    previewAccentColor(color);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'accentColor': color.toARGB32()}, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _docSub?.cancel();
    super.dispose();
  }
}
