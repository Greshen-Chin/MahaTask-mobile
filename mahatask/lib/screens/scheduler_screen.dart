import 'package:flutter/material.dart';

import '../services/scheduler_service.dart';
import '../services/task_service.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> with AutomaticKeepAliveClientMixin {
  final SchedulerService _service = SchedulerService();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDay = DateTime.now();

  bool _loading = true;
  String? _error;
  List<ScheduleItem> _schedules = const <ScheduleItem>[];
  List<TaskItem> _deadlines = const <TaskItem>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _service.fetchSchedules(),
        _service.fetchDeadlines(),
      ]);
      if (!mounted) return;
      setState(() {
        _schedules = results[0] as List<ScheduleItem>;
        _deadlines = results[1] as List<TaskItem>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final body = SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scheduler',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Monthly calendar, timeline, and upcoming deadlines.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 18),
            _buildMonthCalendar(),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            else if (_error != null)
              _buildError()
            else ...[
              _buildDailyTimeline(),
              const SizedBox(height: 16),
              _buildUpcomingDeadlines(),
            ],
          ],
        ),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: body,
    );
  }

  Widget _buildMonthCalendar() {
    final monthLabel = _monthName(_focusedMonth.month);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthLabel ${_focusedMonth.year}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_right, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Expanded(child: Center(child: Text('Mon', style: TextStyle(color: Colors.white38, fontSize: 11)))),
              Expanded(child: Center(child: Text('Tue', style: TextStyle(color: Colors.white38, fontSize: 11)))),
              Expanded(child: Center(child: Text('Wed', style: TextStyle(color: Colors.white38, fontSize: 11)))),
              Expanded(child: Center(child: Text('Thu', style: TextStyle(color: Colors.white38, fontSize: 11)))),
              Expanded(child: Center(child: Text('Fri', style: TextStyle(color: Colors.white38, fontSize: 11)))),
              Expanded(child: Center(child: Text('Sat', style: TextStyle(color: Colors.white38, fontSize: 11)))),
              Expanded(child: Center(child: Text('Sun', style: TextStyle(color: Colors.white38, fontSize: 11)))),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final index = row * 7 + col;
                        final dayNum = index - leadingEmpty + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox(height: 34);
                        }
                        final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                        final selected = _isSameDate(date, _selectedDay);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = date),
                          child: Container(
                            height: 34,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: selected ? Colors.cyanAccent.withOpacity(0.25) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$dayNum',
                                style: TextStyle(
                                  color: selected ? Colors.cyanAccent : Colors.white70,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDailyTimeline() {
    final daily = _schedules
        .where((item) => _isSameDate(item.startTime, _selectedDay))
        .toList(growable: false)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Timeline (${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year})',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (daily.isEmpty)
            const Text('No schedule for this day.', style: TextStyle(color: Colors.white38))
          else
            ...daily.map((item) {
              final start = _hhmm(item.startTime);
              final end = _hhmm(item.endTime);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('$start - $end', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlines() {
    final upcoming = _deadlines
        .where((task) => task.dueDate != null)
        .toList(growable: false)
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Deadlines',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            const Text('No upcoming deadlines.', style: TextStyle(color: Colors.white38))
          else
            ...upcoming.take(8).map((task) {
              final due = task.dueDate!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(task.title, style: const TextStyle(color: Colors.white)),
                    ),
                    Text(
                      '${due.day}/${due.month}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
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
      'December',
    ];
    return names[month - 1];
  }

  String _hhmm(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
