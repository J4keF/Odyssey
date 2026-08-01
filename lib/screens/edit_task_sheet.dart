import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/theme_controller.dart';
import 'add_task_sheet.dart';

const _uuid = Uuid();

class EditTaskSheet extends StatefulWidget {
  final Task task;
  // When true, a fresh empty milestone is appended and opened expanded —
  // the "quick add" entry point from the task detail page.
  final bool startWithNewMilestone;
  const EditTaskSheet(
      {super.key, required this.task, this.startWithNewMilestone = false});

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet> {
  late String _emoji;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late int _colorIndex;
  late List<MilestoneDraft> _milestones;
  String? _autoExpandId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _emoji = t.emoji;
    _titleCtrl = TextEditingController(text: t.title);
    _descCtrl = TextEditingController(text: t.description);
    _colorIndex = t.colorIndex;

    // Convert existing milestones into editable drafts
    _milestones = t.milestones.map((m) {
      return MilestoneDraft(
        id: m.id,
        title: m.title,
        targetDate: m.targetDate,
        steppingStones: m.steppingStones
            .map((s) => SubItemDraft(id: s.id, title: s.title))
            .toList(),
        dailies: m.dailies
            .map((d) => SubItemDraft(id: d.id, title: d.title))
            .toList(),
      );
    }).toList();

    if (widget.startWithNewMilestone) {
      final draft = MilestoneDraft(id: _uuid.v4());
      _milestones.add(draft);
      _autoExpandId = draft.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete task?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This permanently deletes this task and all its milestones. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await TaskService.deleteTask(widget.task.id);
              if (mounted) {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              }
            },
            child: const Text('Delete',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickEmoji() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmojiPickerModal(current: _emoji),
    );
    if (result != null && mounted) setState(() => _emoji = result);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title')),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      // Rebuild milestone list, preserving existing completion state
      final existingById = {for (final m in widget.task.milestones) m.id: m};

      final milestones = _milestones.asMap().entries.map((entry) {
        final i = entry.key;
        final draft = entry.value;
        final existing = existingById[draft.id];

        // Preserve existing stepping-stone completion state
        final existingStonesById = {
          for (final s in existing?.steppingStones ?? <SteppingStone>[]) s.id: s
        };
        final stones = draft.steppingStones
            .where((s) => s.title.trim().isNotEmpty)
            .map((s) {
          final prev = existingStonesById[s.id];
          return SteppingStone(
            id: s.id,
            title: s.title.trim(),
            isCompleted: prev?.isCompleted ?? false,
            completedAt: prev?.completedAt,
          );
        }).toList();

        // Preserve existing daily streak/check state
        final existingDailiesById = {
          for (final d in existing?.dailies ?? <Daily>[]) d.id: d
        };
        final dailies =
            draft.dailies.where((d) => d.title.trim().isNotEmpty).map((d) {
          final prev = existingDailiesById[d.id];
          return Daily(
            id: d.id,
            title: d.title.trim(),
            lastCheckedDate: prev?.lastCheckedDate ?? '',
            currentStreak: prev?.currentStreak ?? 0,
            longestStreak: prev?.longestStreak ?? 0,
          );
        }).toList();

        return Milestone(
          id: draft.id,
          title: draft.title,
          targetDate: draft.targetDate,
          order: i,
          steppingStones: stones,
          dailies: dailies,
        );
      }).toList();

      final updated = Task(
        id: widget.task.id,
        userId: widget.task.userId,
        emoji: _emoji,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        colorIndex: _colorIndex,
        createdAt: widget.task.createdAt,
        order: widget.task.order,
        milestones: milestones,
      );

      await TaskService.updateTask(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Text('Edit Task',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Save',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Emoji + Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickEmoji,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Center(
                                child: Text(_emoji,
                                    style: const TextStyle(fontSize: 28))),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _titleCtrl,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                              hintText: 'Task title',
                              hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Add a description…',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Color picker
                    _ColorRowEdit(
                      selected: _colorIndex,
                      onTap: (i) => setState(() => _colorIndex = i),
                    ),
                    const SizedBox(height: 28),
                    // Milestones
                    Row(
                      children: [
                        const Text('Milestones',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() =>
                              _milestones.add(MilestoneDraft(id: _uuid.v4()))),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                              foregroundColor: accentColor,
                              padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_milestones.isEmpty)
                      Center(
                        child: Text(
                          'No milestones yet — tap Add',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      )
                    else
                      ..._milestones
                          .asMap()
                          .entries
                          .map((e) => MilestoneDraftCard(
                                key: ValueKey(e.value.id),
                                draft: e.value,
                                index: e.key,
                                startExpanded: e.value.id == _autoExpandId,
                                onDelete: () =>
                                    setState(() => _milestones.removeAt(e.key)),
                                onChange: () => setState(() {}),
                              )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColorRowEdit extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _ColorRowEdit({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    return Row(
      children: List.generate(Task.cardColors.length, (i) {
        final isSel = i == selected;
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Task.cardColors[i],
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSel ? accentColor : Colors.transparent, width: 2),
            ),
            child:
                isSel ? Icon(Icons.check, size: 14, color: accentColor) : null,
          ),
        );
      }),
    );
  }
}
