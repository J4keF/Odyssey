import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

const _uuid = Uuid();
const kOrange = Color(0xFFE8581A);

// ─── Shared emoji list ────────────────────────────────────────────────────────

const kEmojis = [
  '🎯','📚','💪','🌱','🎨','🎵','✈️','🏃','💻','🧘',
  '🍎','🌍','🔬','🎭','📷','⚽','🏋️','🛠️','🤝','💡',
  '🌟','🏆','📝','🎓','🚀','🧩','🎸','🌸','🦋','🔥',
  '🎪','🎬','🎤','🎺','🏄','🧗','🤸','🏇','🤿','🧁',
  '🌮','🍜','☕','🍵','🎂','🥗','🍕','🍣','🥐','🧃',
];

// ─── Emoji picker modal ───────────────────────────────────────────────────────
// Opens as its own bottom sheet so it never shifts the parent layout.

class EmojiPickerModal extends StatefulWidget {
  final String current;
  const EmojiPickerModal({super.key, required this.current});

  @override
  State<EmojiPickerModal> createState() => _EmojiPickerModalState();
}

class _EmojiPickerModalState extends State<EmojiPickerModal> {
  late String _selected;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _ctrl.text = widget.current;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pick(String e) {
    setState(() => _selected = e);
    Navigator.pop(context, e);
  }

  @override
  Widget build(BuildContext context) {
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
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Text('Choose Emoji',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text('Done',
                      style: TextStyle(color: kOrange, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // Current selection preview
          Text(_selected, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          // Type-any-emoji field — tapping opens native emoji keyboard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _ctrl,
              maxLength: 2,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Type any emoji…',
                hintStyle: TextStyle(
                    color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kOrange, width: 2),
                ),
                suffixIcon: const Tooltip(
                  message: 'Tap the emoji key (🌐 or 😊) on your keyboard',
                  child: Icon(Icons.info_outline_rounded,
                      color: Colors.grey, size: 18),
                ),
              ),
              onChanged: (v) {
                final runes = v.runes.toList();
                if (runes.isNotEmpty) {
                  setState(() => _selected = String.fromCharCodes(
                      runes.take(2)));
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Quick picks',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: kEmojis.length,
              itemBuilder: (ctx, i) {
                final e = kEmojis[i];
                final isSel = e == _selected;
                return GestureDetector(
                  onTap: () => _pick(e),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFFFFE8D5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 22))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Subitem model (local draft only) ────────────────────────────────────────

class SubItemDraft {
  final String id;
  String title;
  SubItemDraft({required this.id, this.title = ''});
}

class MilestoneDraft {
  final String id;
  String title;
  DateTime? targetDate;
  List<SubItemDraft> steppingStones;
  List<SubItemDraft> dailies;

  MilestoneDraft({
    required this.id,
    this.title = '',
    this.targetDate,
    List<SubItemDraft>? steppingStones,
    List<SubItemDraft>? dailies,
  })  : steppingStones = steppingStones ?? [],
        dailies = dailies ?? [];
}

// ─── Add Task Sheet ───────────────────────────────────────────────────────────

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  String _emoji = '🎯';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _colorIndex = 0;
  final List<MilestoneDraft> _milestones = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmojiPickerModal(current: _emoji),
    );
    if (result != null && mounted) {
      setState(() => _emoji = result);
    }
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
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final milestones = _milestones.asMap().entries.map((e) {
        final m = e.value;
        return Milestone(
          id: m.id,
          title: m.title,
          targetDate: m.targetDate,
          order: e.key,
          steppingStones: m.steppingStones
              .where((s) => s.title.trim().isNotEmpty)
              .map((s) => SteppingStone(id: s.id, title: s.title.trim()))
              .toList(),
          dailies: m.dailies
              .where((d) => d.title.trim().isNotEmpty)
              .map((d) => Daily(id: d.id, title: d.title.trim()))
              .toList(),
        );
      }).toList();

      await TaskService.addTask(Task(
        id: _uuid.v4(),
        userId: uid,
        emoji: _emoji,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        colorIndex: _colorIndex,
        createdAt: DateTime.now(),
        milestones: milestones,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F4),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Text('New Task',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Save',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
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
                    // Emoji + Title — emoji is a plain button, no inline grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickEmoji,
                          child: Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: Center(
                                child: Text(_emoji,
                                    style: const TextStyle(
                                        fontSize: 28))),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _titleCtrl,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700),
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
                        hintStyle: TextStyle(
                            color: Colors.grey[400], fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ColorRow(
                      selected: _colorIndex,
                      colors: Task.cardColors,
                      onTap: (i) => setState(() => _colorIndex = i),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Text('Milestones',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() => _milestones
                              .add(MilestoneDraft(id: _uuid.v4()))),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                              foregroundColor: kOrange,
                              padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_milestones.isEmpty)
                      Center(
                        child: Text(
                          'No milestones yet — tap Add',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13),
                        ),
                      )
                    else
                      ..._milestones.asMap().entries.map((e) =>
                          MilestoneDraftCard(
                            draft: e.value,
                            index: e.key,
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

// ─── Color picker row ─────────────────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  final int selected;
  final List<Color> colors;
  final ValueChanged<int> onTap;
  const _ColorRow(
      {required this.selected,
      required this.colors,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(colors.length, (i) {
        final isSel = i == selected;
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: colors[i],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSel
                    ? kOrange
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: isSel
                ? const Icon(Icons.check, size: 14, color: kOrange)
                : null,
          ),
        );
      }),
    );
  }
}

// ─── Milestone draft card (shared with edit sheet) ────────────────────────────

class MilestoneDraftCard extends StatefulWidget {
  final MilestoneDraft draft;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final bool startExpanded;

  const MilestoneDraftCard({
    super.key,
    required this.draft,
    required this.index,
    required this.onDelete,
    required this.onChange,
    this.startExpanded = true,
  });

  @override
  State<MilestoneDraftCard> createState() => _MilestoneDraftCardState();
}

class _MilestoneDraftCardState extends State<MilestoneDraftCard> {
  late bool _expanded;
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
    _titleCtrl = TextEditingController(text: widget.draft.title);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.draft;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(
                        color: kOrange, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${widget.index + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _titleCtrl,
                      onChanged: (v) {
                        m.title = v;
                        widget.onChange();
                      },
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Milestone title',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate:
                            m.targetDate ?? DateTime.now(),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 1)),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: kOrange)),
                          child: child!,
                        ),
                      );
                      if (d != null) {
                        setState(() => m.targetDate = d);
                        widget.onChange();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3DC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m.targetDate != null
                            ? '${m.targetDate!.day}/${m.targetDate!.month}/${m.targetDate!.year}'
                            : 'Date',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF854F0B),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                  ),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.close_rounded,
                          color: Colors.grey[400], size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  SubList(
                    label: 'Stepping Stones',
                    icon: Icons.flag_outlined,
                    color: const Color(0xFF3B6D11),
                    bgColor: const Color(0xFFEAF3DE),
                    items: m.steppingStones,
                    onAdd: () {
                      setState(() => m.steppingStones
                          .add(SubItemDraft(id: _uuid.v4())));
                      widget.onChange();
                    },
                    onRemove: (id) {
                      setState(() => m.steppingStones
                          .removeWhere((s) => s.id == id));
                      widget.onChange();
                    },
                    onChange: widget.onChange,
                  ),
                  const SizedBox(height: 14),
                  SubList(
                    label: 'Dailies',
                    icon: Icons.loop_rounded,
                    color: const Color(0xFF185FA5),
                    bgColor: const Color(0xFFE6F1FB),
                    items: m.dailies,
                    onAdd: () {
                      setState(() =>
                          m.dailies.add(SubItemDraft(id: _uuid.v4())));
                      widget.onChange();
                    },
                    onRemove: (id) {
                      setState(() =>
                          m.dailies.removeWhere((d) => d.id == id));
                      widget.onChange();
                    },
                    onChange: widget.onChange,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-list widget (shared) ─────────────────────────────────────────────────

class SubList extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<SubItemDraft> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback onChange;

  const SubList({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onAdd,
              child: Icon(Icons.add_circle_outline, size: 18, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text('None yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ...items.map((item) => _SubItemRow(
            item: item, onRemove: onRemove, onChange: onChange)),
      ],
    );
  }
}

class _SubItemRow extends StatefulWidget {
  final SubItemDraft item;
  final ValueChanged<String> onRemove;
  final VoidCallback onChange;
  const _SubItemRow(
      {required this.item,
      required this.onRemove,
      required this.onChange});

  @override
  State<_SubItemRow> createState() => _SubItemRowState();
}

class _SubItemRowState extends State<_SubItemRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.title);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.drag_indicator_rounded,
              size: 16, color: Colors.grey[300]),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: (v) {
                widget.item.title = v;
                widget.onChange();
              },
              decoration: InputDecoration(
                hintText: 'Add title…',
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => widget.onRemove(widget.item.id),
            child: Icon(Icons.close_rounded,
                size: 16, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}