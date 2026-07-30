import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'edit_task_sheet.dart';

Color _darken(Color c, [double amount = 0.28]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

class TaskDetailPage extends StatelessWidget {
  final Task task;
  const TaskDetailPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: TaskService.tasksStream(),
      builder: (context, snapshot) {
        final live = snapshot.data?.firstWhere(
              (t) => t.id == task.id,
              orElse: () => task,
            ) ??
            task;

        return Scaffold(
          backgroundColor: const Color(0xFFFAF7F4),
          body: Stack(
            children: [
              // Card-colour top strip behind header
              Positioned(
                top: 0, left: 0, right: 0, height: 300,
                child: Container(color: live.cardColor),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(task: live),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF7F4),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32)),
                        ),
                        // Clip so content respects the rounded top
                        clipBehavior: Clip.hardEdge,
                        child: live.milestones.isEmpty
                            ? const _EmptyMilestones()
                            : _MilestoneList(task: live),
                      ),
                    ),
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Task task;
  const _Header({required this.task});

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTaskSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF1A1A1A), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openEdit(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 15, color: Color(0xFF1A1A1A)),
                      SizedBox(width: 5),
                      Text('Edit',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.emoji,
                    style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 6),
                Text(task.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    )),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(task.description,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4)),
                ],
                const SizedBox(height: 12),
                _ProgressBar(task: task),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Task task;
  const _ProgressBar({required this.task});

  @override
  Widget build(BuildContext context) {
    final progress = task.totalProgress;
    final color = _darken(task.cardColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Overall progress',
                style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8))),
            Text('${(progress * 100).round()}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.18),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Empty ────────────────────────────────────────────────────────────────────

class _EmptyMilestones extends StatelessWidget {
  const _EmptyMilestones();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🗺️', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('No milestones yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          SizedBox(height: 6),
          Text('Tap Edit to map your path',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Milestone list ───────────────────────────────────────────────────────────

class _MilestoneList extends StatelessWidget {
  final Task task;
  const _MilestoneList({required this.task});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      itemCount: task.milestones.length,
      itemBuilder: (ctx, i) => _MilestoneRow(
        task: task,
        milestone: task.milestones[i],
        isLast: i == task.milestones.length - 1,
      ),
    );
  }
}

// ─── Milestone row ────────────────────────────────────────────────────────────

class _MilestoneRow extends StatefulWidget {
  final Task task;
  final Milestone milestone;
  final bool isLast;
  const _MilestoneRow(
      {required this.task,
      required this.milestone,
      required this.isLast});

  @override
  State<_MilestoneRow> createState() => _MilestoneRowState();
}

class _MilestoneRowState extends State<_MilestoneRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;
    final progressColor = _darken(widget.task.cardColor);
    final allDone = m.steppingStones.isNotEmpty &&
        m.steppingStones.every((s) => s.isCompleted);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dotted path column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: allDone ? progressColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: allDone
                          ? progressColor
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: allDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : Center(
                          child: Text('${m.order + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey))),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: CustomPaint(
                      painter: _DottedLinePainter(),
                      child: const SizedBox(width: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Milestone card header
                  GestureDetector(
                    onTap: () =>
                        setState(() => _expanded = !_expanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.title.isEmpty
                                      ? 'Milestone ${m.order + 1}'
                                      : m.title,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (m.targetDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: progressColor
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    DateFormat('d MMM')
                                        .format(m.targetDate!),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: progressColor,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              _CountPills(milestone: m),
                              const SizedBox(width: 4),
                              Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons
                                        .keyboard_arrow_down_rounded,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                          if (m.steppingStones.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: m.progress,
                                backgroundColor:
                                    progressColor.withOpacity(0.15),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        progressColor),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 8),
                    if (m.steppingStones.isNotEmpty)
                      _SteppingStoneSection(
                          task: widget.task, milestone: m),
                    if (m.dailies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DailySection(
                          task: widget.task, milestone: m),
                    ],
                    if (m.steppingStones.isEmpty &&
                        m.dailies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('No items yet. Tap Edit to add.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400])),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Count pills ──────────────────────────────────────────────────────────────

class _CountPills extends StatelessWidget {
  final Milestone milestone;
  const _CountPills({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (milestone.steppingStones.isNotEmpty)
          _MiniPill(
              count: milestone.steppingStones.length,
              bg: const Color(0xFFEAF3DE),
              fg: const Color(0xFF3B6D11),
              icon: Icons.flag_outlined),
        if (milestone.dailies.isNotEmpty) ...[
          const SizedBox(width: 4),
          _MiniPill(
              count: milestone.dailies.length,
              bg: const Color(0xFFE6F1FB),
              fg: const Color(0xFF185FA5),
              icon: Icons.loop_rounded),
        ],
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  final int count;
  final Color bg, fg;
  final IconData icon;
  const _MiniPill(
      {required this.count,
      required this.bg,
      required this.fg,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text('$count',
              style: TextStyle(
                  fontSize: 11,
                  color: fg,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Stepping stones ──────────────────────────────────────────────────────────

class _SteppingStoneSection extends StatelessWidget {
  final Task task;
  final Milestone milestone;
  const _SteppingStoneSection(
      {required this.task, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final pending =
        milestone.steppingStones.where((s) => !s.isCompleted).toList();
    final done =
        milestone.steppingStones.where((s) => s.isCompleted).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_outlined,
                  size: 13, color: Color(0xFF3B6D11)),
              SizedBox(width: 5),
              Text('Stepping Stones',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B6D11))),
            ],
          ),
          const SizedBox(height: 8),
          ...pending.map((s) =>
              _StoneTile(task: task, milestone: milestone, stone: s)),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Completed',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            ...done.map((s) =>
                _StoneTile(task: task, milestone: milestone, stone: s)),
          ],
        ],
      ),
    );
  }
}

class _StoneTile extends StatelessWidget {
  final Task task;
  final Milestone milestone;
  final SteppingStone stone;
  const _StoneTile(
      {required this.task,
      required this.milestone,
      required this.stone});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TaskService.toggleSteppingStone(
          task: task, milestoneId: milestone.id, stoneId: stone.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: stone.isCompleted
                    ? const Color(0xFF3B6D11)
                    : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: const Color(0xFF3B6D11), width: 1.5),
              ),
              child: stone.isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(stone.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: stone.isCompleted
                        ? Colors.grey[500]
                        : const Color(0xFF1A1A1A),
                    decoration: stone.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dailies ──────────────────────────────────────────────────────────────────

class _DailySection extends StatelessWidget {
  final Task task;
  final Milestone milestone;
  const _DailySection(
      {required this.task, required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.loop_rounded,
                  size: 13, color: Color(0xFF185FA5)),
              SizedBox(width: 5),
              Text('Dailies',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF185FA5))),
            ],
          ),
          const SizedBox(height: 8),
          ...milestone.dailies.map((d) => DailyTile(
              task: task, milestone: milestone, daily: d)),
        ],
      ),
    );
  }
}

// ─── Daily tile (exported for dailies_page) ───────────────────────────────────

class DailyTile extends StatelessWidget {
  final Task task;
  final Milestone milestone;
  final Daily daily;
  final bool showTaskLabel;
  const DailyTile({
    super.key,
    required this.task,
    required this.milestone,
    required this.daily,
    this.showTaskLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final checked = daily.isCheckedToday;
    return GestureDetector(
      onTap: () => TaskService.toggleDaily(
          task: task, milestoneId: milestone.id, dailyId: daily.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: checked
                    ? const Color(0xFF185FA5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: const Color(0xFF185FA5), width: 1.5),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(daily.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: checked
                            ? Colors.grey[400]
                            : const Color(0xFF1A1A1A),
                        decoration: checked
                            ? TextDecoration.lineThrough
                            : null,
                      )),
                  if (showTaskLabel)
                    Text(
                      '${task.emoji} ${task.title} › ${milestone.title}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
            if (daily.currentStreak > 0)
              _StreakBadge(daily: daily),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final Daily daily;
  const _StreakBadge({required this.daily});

  @override
  Widget build(BuildContext context) {
    final active = daily.isCheckedToday;
    return Tooltip(
      message: 'Best: ${daily.longestStreak} days',
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFE8581A)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(active ? '🔥' : '💤',
                style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Text('${daily.currentStreak}',
                style: TextStyle(
                    color: active ? Colors.white : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Dotted line ──────────────────────────────────────────────────────────────

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2;
    const dotH = 4.0, gap = 6.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, y + dotH), paint);
      y += dotH + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}