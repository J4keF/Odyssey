import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/theme_controller.dart';
import '../utils/color_utils.dart';
import 'task_detail_page.dart' show DailyTile;

class DailiesPage extends StatelessWidget {
  const DailiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    return SafeArea(
      bottom:
          false, // let floating nav + scroll padding handle bottom clearance
      child: StreamBuilder<List<Task>>(
        stream: TaskService.tasksStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }

          // Flatten all dailies with their task/milestone context
          final entries = <_DailyEntry>[];
          for (final task in snap.data ?? []) {
            for (final milestone in task.milestones) {
              if (milestone.isComplete) continue;
              for (final daily in milestone.dailies) {
                entries.add(_DailyEntry(
                    task: task, milestone: milestone, daily: daily));
              }
            }
          }

          // Split into today-done and pending
          final pending =
              entries.where((e) => !e.daily.isCheckedToday).toList();
          final done = entries.where((e) => e.daily.isCheckedToday).toList();

          final totalCount = entries.length;
          final doneCount = done.length;
          final allComplete = totalCount > 0 && doneCount == totalCount;

          return CustomScrollView(
            slivers: [
              // ── Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Routine',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todayLabel(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      if (totalCount > 0) ...[
                        const SizedBox(height: 16),
                        _SummaryCard(
                          done: doneCount,
                          total: totalCount,
                          allComplete: allComplete,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Empty state
              if (totalCount == 0)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('☀️', style: TextStyle(fontSize: 52)),
                        const SizedBox(height: 12),
                        const Text('No dailies yet',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 6),
                        Text(
                          'Add dailies to your task milestones\nto build your routine',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Pending dailies
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  label: 'To do today',
                  count: pending.length,
                  color: accentColor,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _DailyCard(entry: pending[i]),
                      childCount: pending.length,
                    ),
                  ),
                ),
              ],

              // ── Completed dailies
              if (done.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Done today',
                  count: done.length,
                  color: const Color(0xFF3B6D11),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _DailyCard(entry: done[i], dim: true),
                      childCount: done.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int done;
  final int total;
  final bool allComplete;

  const _SummaryCard(
      {required this.done, required this.total, required this.allComplete});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? done / total : 0.0;
    final accentColor = context.watch<ThemeController>().accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allComplete
              ? [const Color(0xFF27500A), const Color(0xFF3B6D11)]
              : [darken(accentColor, 0.16), accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                allComplete ? '🎉 All done!' : '$done / $total completed',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          if (allComplete) ...[
            const SizedBox(height: 8),
            const Text(
              'Routine complete for today 😎',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionHeader(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily card ───────────────────────────────────────────────────────────────

class _DailyCard extends StatelessWidget {
  final _DailyEntry entry;
  final bool dim;
  const _DailyCard({required this.entry, this.dim = false});

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: dim ? Colors.white.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(dim ? 0.02 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: DailyTile(
        task: entry.task,
        milestone: entry.milestone,
        daily: entry.daily,
        showTaskLabel: true,
        colorOverride: accentColor,
      ),
    );
  }
}

// ─── Entry model ──────────────────────────────────────────────────────────────

class _DailyEntry {
  final Task task;
  final Milestone milestone;
  final Daily daily;
  const _DailyEntry(
      {required this.task, required this.milestone, required this.daily});
}
