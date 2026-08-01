import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import 'dart:math';

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({super.key});

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  String _emoji = '🎯';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<Milestone> _milestones = [];
  bool _isSaving = false;

  final List<String> _emojiChoices = [
    '🎯',
    '🚀',
    '⭐',
    '🏃‍♂️',
    '📚',
    '💪',
    '🧘‍♀️',
    '🎨',
    '💼',
    '💰',
    '🔥',
    '🏆'
  ];

  String _genId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(1000).toString();

  void _addMilestone() {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Milestone'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(hintText: 'e.g., Learn Basics'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _milestones.add(Milestone(
                    id: _genId(),
                    title: titleCtrl.text.trim(),
                    order: _milestones.length,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addSubtask(int milestoneIndex) {
    final titleCtrl = TextEditingController();
    bool isDaily = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Subtask'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(hintText: 'Task title'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Type: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Stepping Stone'),
                      selected: !isDaily,
                      onSelected: (val) =>
                          setDialogState(() => isDaily = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Daily'),
                      selected: isDaily,
                      onSelected: (val) => setDialogState(() => isDaily = true),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      final m = _milestones[milestoneIndex];
                      if (isDaily) {
                        _milestones[milestoneIndex] = m.copyWith(
                          dailies: [
                            ...m.dailies,
                            Daily(id: _genId(), title: titleCtrl.text.trim())
                          ],
                        );
                      } else {
                        _milestones[milestoneIndex] = m.copyWith(
                          steppingStones: [
                            ...m.steppingStones,
                            SteppingStone(
                                id: _genId(), title: titleCtrl.text.trim())
                          ],
                        );
                      }
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveTask() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final docRef = FirebaseFirestore.instance.collection('tasks').doc();

      final task = Task(
        id: docRef.id,
        userId: user.uid,
        emoji: _emoji,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        colorIndex: Random().nextInt(Task.cardColors.length),
        createdAt: DateTime.now(),
        order: -DateTime.now().millisecondsSinceEpoch,
        milestones: _milestones,
      );

      await docRef.set(task.toMap());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('🔥 FIRESTORE ERROR: $e');

      // Move setState inside the if (mounted) check!
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to save task: ${e.toString().split('Exception: ').last}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Create Task',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Pick an Emoji'),
                            content: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _emojiChoices
                                  .map((e) => GestureDetector(
                                        onTap: () {
                                          setState(() => _emoji = e);
                                          Navigator.pop(ctx);
                                        },
                                        child: Text(e,
                                            style:
                                                const TextStyle(fontSize: 32)),
                                      ))
                                  .toList(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12)),
                        child:
                            Text(_emoji, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _titleCtrl,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                            hintText: 'Task Title', border: InputBorder.none),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Add a description...',
                      border: InputBorder.none),
                  maxLines: null,
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Milestones',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _addMilestone,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    )
                  ],
                ),
                ..._milestones.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final m = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: const Color(0xFFFAF7F4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (m.dailies.isNotEmpty ||
                              m.steppingStones.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '${m.dailies.length} Dailies • ${m.steppingStones.length} Stepping Stones',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ),
                          SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: () => _addSubtask(idx),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Subtask'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8581A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Task',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
