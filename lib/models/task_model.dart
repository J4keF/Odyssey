import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── SteppingStone ────────────────────────────────────────────────────────────

class SteppingStone {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;

  const SteppingStone({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });

  factory SteppingStone.fromMap(Map<String, dynamic> m) => SteppingStone(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        isCompleted: m['isCompleted'] as bool? ?? false,
        completedAt: m['completedAt'] != null
            ? (m['completedAt'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  SteppingStone copyWith({bool? isCompleted, DateTime? completedAt}) =>
      SteppingStone(
        id: id,
        title: title,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
      );
}

// ─── Daily ────────────────────────────────────────────────────────────────────

class Daily {
  final String id;
  final String title;
  final String lastCheckedDate; // "YYYY-MM-DD"
  final int currentStreak;
  final int longestStreak;

  const Daily({
    required this.id,
    required this.title,
    this.lastCheckedDate = '',
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get isCheckedToday => lastCheckedDate == _fmt(DateTime.now());

  factory Daily.fromMap(Map<String, dynamic> m) => Daily(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        lastCheckedDate: m['lastCheckedDate'] as String? ?? '',
        currentStreak: m['currentStreak'] as int? ?? 0,
        longestStreak: m['longestStreak'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'lastCheckedDate': lastCheckedDate,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };

  /// Toggle check state. If checking today, extends or starts streak.
  /// If unchecking, rolls back one day and decrements streak.
  Daily toggle() {
    final today = _fmt(DateTime.now());
    if (lastCheckedDate == today) {
      final yesterday = _fmt(DateTime.now().subtract(const Duration(days: 1)));
      return Daily(
        id: id,
        title: title,
        lastCheckedDate: yesterday,
        currentStreak: currentStreak > 0 ? currentStreak - 1 : 0,
        longestStreak: longestStreak,
      );
    }
    final yesterday = _fmt(DateTime.now().subtract(const Duration(days: 1)));
    final newStreak = lastCheckedDate == yesterday ? currentStreak + 1 : 1;
    return Daily(
      id: id,
      title: title,
      lastCheckedDate: today,
      currentStreak: newStreak,
      longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
    );
  }
}

// ─── Milestone ────────────────────────────────────────────────────────────────

class Milestone {
  final String id;
  final String title;
  final DateTime? targetDate;
  final int order;
  final List<SteppingStone> steppingStones;
  final List<Daily> dailies;

  const Milestone({
    required this.id,
    required this.title,
    this.targetDate,
    this.order = 0,
    this.steppingStones = const [],
    this.dailies = const [],
  });

  factory Milestone.fromMap(Map<String, dynamic> m) => Milestone(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        targetDate: m['targetDate'] != null
            ? (m['targetDate'] as Timestamp).toDate()
            : null,
        order: m['order'] as int? ?? 0,
        steppingStones: (m['steppingStones'] as List<dynamic>? ?? [])
            .map((e) => SteppingStone.fromMap(e as Map<String, dynamic>))
            .toList(),
        dailies: (m['dailies'] as List<dynamic>? ?? [])
            .map((e) => Daily.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'targetDate':
            targetDate != null ? Timestamp.fromDate(targetDate!) : null,
        'order': order,
        'steppingStones': steppingStones.map((e) => e.toMap()).toList(),
        'dailies': dailies.map((e) => e.toMap()).toList(),
      };

  Milestone copyWith({
    List<SteppingStone>? steppingStones,
    List<Daily>? dailies,
  }) =>
      Milestone(
        id: id,
        title: title,
        targetDate: targetDate,
        order: order,
        steppingStones: steppingStones ?? this.steppingStones,
        dailies: dailies ?? this.dailies,
      );

  double get progress {
    if (steppingStones.isEmpty) return 0;
    return steppingStones.where((s) => s.isCompleted).length /
        steppingStones.length;
  }

  bool get isComplete =>
      steppingStones.isNotEmpty && steppingStones.every((s) => s.isCompleted);
}

// ─── Task ─────────────────────────────────────────────────────────────────────

class Task {
  final String id;
  final String userId;
  final String emoji;
  final String title;
  final String description;
  final int colorIndex;
  final DateTime createdAt;
  final int order;
  final List<Milestone> milestones;

  const Task({
    required this.id,
    required this.userId,
    required this.emoji,
    required this.title,
    this.description = '',
    this.colorIndex = 0,
    required this.createdAt,
    required this.order,
    this.milestones = const [],
  });

  static const List<Color> cardColors = [
    Color(0xFFFDE8EC), // rose
    Color(0xFFE8F5EE), // mint
    Color(0xFFFFF3DC), // butter
    Color(0xFFE3F0FD), // sky
    Color(0xFFEDE7F6), // lavender
    Color(0xFFFFE8D5), // peach
  ];

  Color get cardColor => cardColors[colorIndex % cardColors.length];

  factory Task.fromMap(Map<String, dynamic> m, String id) {
    final createdAt = m['createdAt'] != null
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    // Tasks created before drag-reordering existed have no stored order —
    // fall back to newest-first, matching the old createdAt-based sort.
    return Task(
      id: id,
      userId: m['userId'] as String? ?? '',
      emoji: m['emoji'] as String? ?? '🎯',
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      colorIndex: m['colorIndex'] as int? ?? 0,
      createdAt: createdAt,
      order: m['order'] as int? ?? -createdAt.millisecondsSinceEpoch,
      milestones: (m['milestones'] as List<dynamic>? ?? [])
          .map((e) => Milestone.fromMap(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'emoji': emoji,
        'title': title,
        'description': description,
        'colorIndex': colorIndex,
        'createdAt': Timestamp.fromDate(createdAt),
        'order': order,
        'milestones': milestones.map((m) => m.toMap()).toList(),
      };

  Task copyWith({List<Milestone>? milestones, int? order}) => Task(
        id: id,
        userId: userId,
        emoji: emoji,
        title: title,
        description: description,
        colorIndex: colorIndex,
        createdAt: createdAt,
        order: order ?? this.order,
        milestones: milestones ?? this.milestones,
      );

  double get totalProgress {
    if (milestones.isEmpty) return 0;
    return milestones.map((m) => m.progress).fold(0.0, (sum, p) => sum + p) /
        milestones.length;
  }
}
