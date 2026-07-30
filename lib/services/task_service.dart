import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;
  static CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('tasks');

  // ─── Streams ───────────────────────────────────────────────────────────────

  static Stream<List<Task>> tasksStream() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Task.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  // ─── Create ────────────────────────────────────────────────────────────────

  static Future<void> addTask(Task task) =>
      _col.doc(task.id).set(task.toMap());

  // ─── Update whole task (milestones, dailies, stepping stones) ──────────────

  static Future<void> updateTask(Task task) =>
      _col.doc(task.id).update(task.toMap());

  // ─── Delete ────────────────────────────────────────────────────────────────

  static Future<void> deleteTask(String taskId) => _col.doc(taskId).delete();

  // ─── Toggle daily ──────────────────────────────────────────────────────────

  static Future<void> toggleDaily({
    required Task task,
    required String milestoneId,
    required String dailyId,
  }) async {
    final updatedMilestones = task.milestones.map((m) {
      if (m.id != milestoneId) return m;
      final updatedDailies = m.dailies.map((d) {
        if (d.id != dailyId) return d;
        return d.toggle();
      }).toList();
      return m.copyWith(dailies: updatedDailies);
    }).toList();
    await updateTask(task.copyWith(milestones: updatedMilestones));
  }

  // ─── Toggle stepping stone ─────────────────────────────────────────────────

  static Future<void> toggleSteppingStone({
    required Task task,
    required String milestoneId,
    required String stoneId,
  }) async {
    final now = DateTime.now();
    final updatedMilestones = task.milestones.map((m) {
      if (m.id != milestoneId) return m;
      final updatedStones = m.steppingStones.map((s) {
        if (s.id != stoneId) return s;
        final completed = !s.isCompleted;
        return s.copyWith(
          isCompleted: completed,
          completedAt: completed ? now : null,
        );
      }).toList();
      return m.copyWith(steppingStones: updatedStones);
    }).toList();
    await updateTask(task.copyWith(milestones: updatedMilestones));
  }
}