import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/theme_controller.dart';
import '../utils/color_utils.dart';
import 'add_task_sheet.dart';
import 'task_detail_page.dart';
import 'account_page.dart';
import 'dailies_page.dart';
import 'mentor_page.dart';

// ─── Root shell ───────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _index = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _pageCtrl.animateToPage(i,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      // extendBody lets the PageView render behind the floating navbar
      // so BackdropFilter can blur it
      extendBody: true,
      body: PageView(
        controller: _pageCtrl,
        children: const [_TasksTab(), DailiesPage(), MentorPage()],
        onPageChanged: (i) => setState(() => _index = i),
      ),
      bottomNavigationBar: _FloatingNavBar(
        index: _index,
        onTap: _onNavTap,
      ),
    );
  }
}

// ─── Floating glass navbar ────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _FloatingNavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: Colors.white.withOpacity(0.6), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  iconWidget: SvgPicture.asset(
                    'assets/odyssey_logo.svg',
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Colors.black87,
                      BlendMode.srcIn,
                    ),
                  ),
                  selected: index == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.loop_outlined,
                  activeIcon: Icons.loop_rounded,
                  selected: index == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.account_balance_outlined,
                  activeIcon: Icons.account_balance,
                  selected: index == 2,
                  onTap: () => onTap(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final IconData? activeIcon;
  final Widget? iconWidget;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    this.icon,
    this.activeIcon,
    this.iconWidget,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.black.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: iconWidget ??
                Icon(
                  selected ? activeIcon : icon,
                  color: Colors.black87,
                  size: 28,
                ),
          ),
        ),
      ),
    );
  }
}

// ─── Tasks tab ────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  void _openAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    return SafeArea(
      bottom: false, // let floating nav handle bottom padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _openAddTask(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AccountPage()),
                  ),
                  child: _UserAvatar(),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: TaskService.tasksStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: accentColor),
                  );
                }
                final tasks = snap.data ?? [];
                if (tasks.isEmpty) {
                  return _EmptyState(
                      onAdd: () => _openAddTask(context));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) =>
                      _TaskCard(task: tasks[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User Avatar ──────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final accentColor = context.watch<ThemeController>().accentColor;
    final initials = (user?.displayName?.isNotEmpty == true
            ? user!.displayName![0]
            : user?.email?[0] ?? 'U')
        .toUpperCase();

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lighten(accentColor, 0.32),
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(photoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: photoUrl == null
          ? Center(
              child: Text(initials,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: accentColor)))
          : null,
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/odyssey_logo.svg',
            width: 64,
            height: 64,
            colorFilter: ColorFilter.mode(
                lighten(accentColor, 0.28), BlendMode.srcIn),
          ),
          const SizedBox(height: 20),
          const Text('No tasks yet',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text('Tap + to add your first goal',
              style: TextStyle(fontSize: 15, color: Colors.grey[500])),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Add a Task',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Task card ────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    // Progress colour = darkened version of the card's background
    final progressColor = darken(task.cardColor);
    // Extra-darkened variant for progress text, so it reads with more contrast
    final progressTextColor = darken(task.cardColor, 0.42);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: task.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(task.emoji,
                    style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey[500]),
              ],
            ),
            const SizedBox(height: 10),
            Text(task.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3)),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4)),
            ],
            if (task.milestones.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.totalProgress,
                  backgroundColor: progressColor.withOpacity(0.18),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_progressLabel(task),
                      style: TextStyle(
                          fontSize: 11,
                          color: progressTextColor)),
                  Text('${(task.totalProgress * 100).round()}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: progressTextColor)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _progressLabel(Task task) {
    int total = 0, done = 0;
    for (final m in task.milestones) {
      total += m.steppingStones.length;
      done += m.steppingStones.where((s) => s.isCompleted).length;
    }
    if (total == 0) return 'No stepping stones yet';
    return '$done / $total steps done';
  }
}