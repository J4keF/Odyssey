import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../utils/color_utils.dart';
import 'edit_task_sheet.dart';

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
          backgroundColor: live.cardColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(task: live),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAF7F4),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    // Clip so content respects the rounded top
                    clipBehavior: Clip.antiAlias,
                    child: live.milestones.isEmpty
                        ? const _EmptyMilestones()
                        : _MilestoneList(task: live),
                  ),
                ),
              ],
            ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                Text(task.emoji, style: const TextStyle(fontSize: 48)),
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
                          fontSize: 14, color: Colors.grey[600], height: 1.4)),
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
    final color = darken(task.cardColor);
    final textColor = darken(task.cardColor, 0.42);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Overall progress',
                style: TextStyle(fontSize: 12, color: textColor)),
            Text('${(progress * 100).round()}%',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 28, 20, 40 + bottomPad),
      itemCount: task.milestones.length + 1,
      itemBuilder: (ctx, i) {
        if (i == task.milestones.length) {
          return _QuickAddMilestone(task: task);
        }
        return _MilestoneRow(
          task: task,
          milestone: task.milestones[i],
        );
      },
    );
  }
}

// ─── Quick add milestone ────────────────────────────────────────────────────

class _QuickAddMilestone extends StatelessWidget {
  final Task task;
  const _QuickAddMilestone({required this.task});

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EditTaskSheet(task: task, startWithNewMilestone: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = darken(task.cardColor);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      // Row wrapper to loosely contrain width, allows add button to be left aligned
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                CustomPaint(
                  painter: _DottedLinePainter(),
                  child: const SizedBox(width: 2, height: 16),
                ),
                GestureDetector(
                  onTap: () => _open(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                          color: color.withOpacity(0.4), width: 1.5),
                    ),
                    child: Icon(Icons.add_rounded, size: 16, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Milestone row ────────────────────────────────────────────────────────────

class _MilestoneRow extends StatefulWidget {
  final Task task;
  final Milestone milestone;
  const _MilestoneRow({required this.task, required this.milestone});

  @override
  State<_MilestoneRow> createState() => _MilestoneRowState();
}

class _MilestoneRowState extends State<_MilestoneRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;
    final progressColor = darken(widget.task.cardColor);
    final allDone = m.steppingStones.isNotEmpty &&
        m.steppingStones.every((s) => s.isCompleted);

    // Stack allows dotted connector to track frame height
    // Connector overshoots bottom edge to connect to next milestone
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Approximate centering of milestone number
        Positioned(
          left: 15,
          top: 36,
          bottom: -9,
          child: CustomPaint(
            painter: _DottedLinePainter(),
            child: const SizedBox(width: 2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Milestone marker
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: allDone ? progressColor : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                allDone ? progressColor : Colors.grey.shade300,
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
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
                                      color: progressColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      DateFormat('d MMM').format(m.targetDate!),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: progressColor,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                _CountPills(milestone: m, color: progressColor),
                                const SizedBox(width: 4),
                                Icon(
                                  _expanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: progressColor,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      progressColor),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  // Fixed full width on both states — only height should
                  // animate, otherwise the narrower "no items" text makes
                  // it visibly swing in sideways too.
                  child: SizedBox(
                    width: double.infinity,
                    child: !_expanded
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  child: Text(
                                      'No items yet. Tap Edit to add.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[400])),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Count pills ──────────────────────────────────────────────────────────────

class _CountPills extends StatelessWidget {
  final Milestone milestone;
  final Color color;
  const _CountPills({required this.milestone, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (milestone.steppingStones.isNotEmpty)
          _MiniPill(
              count: milestone.steppingStones.length,
              bg: lighten(color, 0.4),
              fg: color,
              icon: Icons.flag_outlined),
        if (milestone.dailies.isNotEmpty) ...[
          const SizedBox(width: 4),
          _MiniPill(
              count: milestone.dailies.length,
              bg: lighten(color, 0.4),
              fg: color,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text('$count',
              style: TextStyle(
                  fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Stepping stones ──────────────────────────────────────────────────────────

class _SteppingStoneSection extends StatelessWidget {
  final Task task;
  final Milestone milestone;
  const _SteppingStoneSection({required this.task, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final color = darken(task.cardColor);
    final pending =
        milestone.steppingStones.where((s) => !s.isCompleted).toList();
    final done = milestone.steppingStones.where((s) => s.isCompleted).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lighten(color, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 13, color: color),
              const SizedBox(width: 5),
              Text('Stepping Stones',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ...pending.map(
              (s) => _StoneTile(task: task, milestone: milestone, stone: s)),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...done.map(
                (s) => _StoneTile(task: task, milestone: milestone, stone: s)),
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
      {required this.task, required this.milestone, required this.stone});

  @override
  Widget build(BuildContext context) {
    final color = darken(task.cardColor);
    return GestureDetector(
      onTap: () => TaskService.toggleSteppingStone(
          task: task, milestoneId: milestone.id, stoneId: stone.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: stone.isCompleted ? color : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: color, width: 1.5),
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
                    decoration:
                        stone.isCompleted ? TextDecoration.lineThrough : null,
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
  const _DailySection({required this.task, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final color = darken(task.cardColor);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lighten(color, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.loop_rounded, size: 13, color: color),
              const SizedBox(width: 5),
              Text('Dailies',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ...milestone.dailies.map(
              (d) => DailyTile(task: task, milestone: milestone, daily: d)),
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
  // Overrides the task-colour default — used on the Routine page, where
  // every entry should follow the app theme colour instead of its own task.
  final Color? colorOverride;
  const DailyTile({
    super.key,
    required this.task,
    required this.milestone,
    required this.daily,
    this.showTaskLabel = false,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final checked = daily.isCheckedToday;
    final color = colorOverride ?? darken(task.cardColor);
    return GestureDetector(
      onTap: () => TaskService.toggleDaily(
          task: task, milestoneId: milestone.id, dailyId: daily.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? color : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color, width: 1.5),
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
                        decoration: checked ? TextDecoration.lineThrough : null,
                      )),
                  if (showTaskLabel)
                    Text(
                      '${task.emoji} ${task.title} › ${milestone.title}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
            if (daily.currentStreak > 0)
              _StreakBadge(daily: daily, color: color),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final Daily daily;
  final Color color;
  const _StreakBadge({required this.daily, required this.color});

  @override
  Widget build(BuildContext context) {
    final active = daily.isCheckedToday;
    return Tooltip(
      message: 'Best: ${daily.longestStreak} days',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(active ? '🔥' : '💤', style: const TextStyle(fontSize: 11)),
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
      canvas.drawLine(
          Offset(size.width / 2, y), Offset(size.width / 2, y + dotH), paint);
      y += dotH + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
