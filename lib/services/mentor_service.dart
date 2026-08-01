import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mentor_message.dart';

// Reads/writes user Mentor chat and calls askMentor function
class MentorService {
  static final _db = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;
  // Per-user chat collection
  static CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('mentorMessages');

  // Oldest-first list of this user's chat messages (live updates)
  static Stream<List<MentorMessage>> messagesStream() => _col
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) =>
              MentorMessage.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  // Saves user message, asks Gemini via backend, saves reply
  static Future<void> sendMessage(String text) async {
    await _col.add(MentorMessage(
      id: '',
      role: 'user',
      text: text,
      createdAt: DateTime.now(),
    ).toMap());

    final callable = _functions.httpsCallable('askMentor');
    final result = await callable.call(<String, dynamic>{'message': text});
    final reply = result.data['reply'] as String;

    await _col.add(MentorMessage(
      id: '',
      role: 'model',
      text: reply,
      createdAt: DateTime.now(),
    ).toMap());
  }

  // Deletes every message in this user's Mentor chat history
  static Future<void> clearHistory() async {
    final snap = await _col.get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
