import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/navigation_provider.dart';
import '../services/session_store.dart';
import '../services/task_service.dart';
import '../services/unread_provider.dart';
import '../widgets/dashboard/bottom_nav_bar.dart';
import 'messages_screen.dart';
import 'scheduler_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final unread = context.watch<UnreadProvider>().totalUnread;
    const pages = <Widget>[
      _HomeDashboardTab(),
      TasksScreen(embedded: true),
      SchedulerScreen(embedded: true),
      MessagesScreen(embedded: true),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: IndexedStack(index: nav.index, children: pages),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: nav.index,
        onTap: (value) => context.read<NavigationProvider>().setIndex(value),
        messagesUnread: unread,
      ),
    );
  }
}

class _HomeDashboardTab extends StatefulWidget {
  const _HomeDashboardTab();

  @override
  State<_HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<_HomeDashboardTab> with AutomaticKeepAliveClientMixin {
  final TaskService _taskService = TaskService();

  bool _loading = true;
  List<TaskItem> _tasks = const <TaskItem>[];
  List<TaskRecommendation> _recommendations = const <TaskRecommendation>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final results = await Future.wait<dynamic>([
        _taskService.fetchTasks(),
        _taskService.fetchRecommendations(availableMinutes: 120, limit: 3, algorithm: 'auto'),
      ]);
      final tasks = results[0] as List<TaskItem>;
      final recommendations = results[1] as List<TaskRecommendation>;
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _recommendations = recommendations;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tasks = const <TaskItem>[];
        _recommendations = const <TaskRecommendation>[];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final name = SessionStore.user?.name?.trim();
    final safeName = (name != null && name.isNotEmpty) ? name : 'User';
    final total = _tasks.length;
    final done = _tasks.where((t) => t.status == 'DONE').length;
    final inProgress = _tasks.where((t) => t.status == 'IN_PROGRESS').length;
    final doneRate = total == 0 ? 0.0 : done / total;
    final now = DateTime.now();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.circle, color: Colors.greenAccent, size: 9),
                  SizedBox(width: 6),
                  Text('Online status', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                icon: const Icon(Icons.settings_outlined, color: Colors.white70),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Good afternoon, ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                        children: [
                          TextSpan(
                            text: safeName,
                            style: const TextStyle(color: Color(0xFFB882FF)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You have ${total - done > 0 ? total - done : 0} active tasks today.',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _DateCard(now: now),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _CircularStatCard(
                  value: '$total',
                  label: 'TOTAL TASKS',
                  footer: '${total - done > 0 ? total - done : 0} left',
                  color: const Color(0xFF7FAEFF),
                  progress: total == 0 ? 0 : 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CircularStatCard(
                  value: '$done',
                  label: 'COMPLETED',
                  footer: '${(doneRate * 100).toStringAsFixed(0)}% Done',
                  color: const Color(0xFF8BFFB0),
                  progress: doneRate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CircularStatCard(
                  value: '$inProgress',
                  label: 'IN PROGRESS',
                  footer: 'Active',
                  color: const Color(0xFFFFD66E),
                  progress: total == 0 ? 0 : inProgress / total,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Text('STUDY GROUP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.read<NavigationProvider>().setIndex(3),
                  child: const Text('Open hub', style: TextStyle(color: Color(0xFFB882FF), fontSize: 11)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.groups_outlined, color: Color(0xFFB882FF), size: 16),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Productivity pulse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const Text('Your daily consistency score', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 14),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 90,
                        width: 90,
                        child: CircularProgressIndicator(
                          value: doneRate,
                          strokeWidth: 8,
                          color: const Color(0xFF8BFFB0),
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      Text(
                        '${(doneRate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    "You're one productive streak away from leveling up your day.",
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _priorityFocusCard(context),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Today's Flow", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    Spacer(),
                    Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 14),
                  ],
                ),
                SizedBox(height: 2),
                Text('Upcoming plan', style: TextStyle(color: Colors.white38, fontSize: 10)),
                SizedBox(height: 28),
                Center(
                  child: Icon(Icons.circle, color: Colors.white10, size: 24),
                ),
                SizedBox(height: 18),
                Center(
                  child: Text(
                    'No events today, enjoy your free time!',
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityFocusCard(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final items = _recommendations;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11222C), Color(0xFF19171F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 6),
              Text('Priority Focus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Text('No recommendation available.', style: TextStyle(color: Colors.white38, fontSize: 11))
          else
            ...items.take(2).map((item) {
              return Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text(
                            '${item.priority} - ${item.estimatedMinutes}m - score ${item.score.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => nav.setIndex(1),
                      child: const Text('Open'),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    const weekdays = <String>['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(weekdays[now.weekday - 1], style: const TextStyle(color: Colors.white38, fontSize: 9)),
          const SizedBox(height: 2),
          Text('${now.day} ${months[now.month - 1]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CircularStatCard extends StatelessWidget {
  const _CircularStatCard({
    required this.value,
    required this.label,
    required this.footer,
    required this.color,
    required this.progress,
  });

  final String value;
  final String label;
  final String footer;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            width: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 4,
                  color: color,
                  backgroundColor: Colors.white12,
                ),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8), textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(footer, style: TextStyle(color: color.withOpacity(0.9), fontSize: 9)),
        ],
      ),
    );
  }
}
