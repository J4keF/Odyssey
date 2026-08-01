import 'package:cloud_firestore/cloud_firestore.dart';

class MentorMessage {
  final String id;
  final String role;
  final String text;
  final DateTime createdAt;

  // Message with id, role (user/model), text, time created at
  const MentorMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  // Getter to check message sent by user for UI coloring
  bool get isUser => role == 'user';

  factory MentorMessage.fromMap(Map<String, dynamic> m, String id) =>
      MentorMessage(
        id: id,
        role: m['role'] as String? ?? 'model',
        text: m['text'] as String? ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'role': role,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
