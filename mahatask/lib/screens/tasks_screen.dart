import 'package:flutter/material.dart';

import '../services/task_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with AutomaticKeepAliveClientMixin {
  final TaskService _taskService = TaskService();

  bool _isLoading = true;
  String? _error;

  List<TaskItem> _tasks = const <TaskItem>[];
  List<GroupOption> _groups = const <GroupOption>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _taskService.fetchTasks(),
        _taskService.fetchGroups(),
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = (results[0] as List<TaskItem>);
        _groups = (results[1] as List<GroupOption>);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openCreateTaskSheet() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fieldText = isDark ? Colors.white : const Color(0xFF0F172A);
    final dropdownBg = isDark ? const Color(0xFF262626) : Colors.white;
    final iconColor = isDark ? Colors.white : const Color(0xFF334155);
    final outline = isDark ? Colors.white24 : const Color(0xFFD1D9E6);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var selectedScope = TaskScope.personal;
    var selectedPriority = TaskPriority.medium;
    GroupOption? selectedGroup = _groups.isNotEmpty ? _groups.first : null;
    DateTime? selectedDueDate;
    String? validationMessage;
    var isSubmitting = false;
    var sheetClosed = false;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDueDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDueDate ?? now,
                firstDate: now,
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) {
                setModalState(() {
                  selectedDueDate = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Task',
                      style: TextStyle(
                        color: fieldText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scope',
                      style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text('Personal'),
                          selected: selectedScope == TaskScope.personal,
                          onSelected: (_) => setModalState(
                            () => selectedScope = TaskScope.personal,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Group'),
                          selected: selectedScope == TaskScope.group,
                          onSelected: (_) => setModalState(
                            () => selectedScope = TaskScope.group,
                          ),
                        ),
                      ],
                    ),
                    if (selectedScope == TaskScope.group) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GroupOption>(
                        value: selectedGroup,
                        dropdownColor: dropdownBg,
                        decoration: _inputDecoration('Choose group'),
                        iconEnabledColor: iconColor,
                        items: _groups
                            .map(
                              (group) => DropdownMenuItem<GroupOption>(
                                value: group,
                                child: Text(
                                  group.name,
                                  style: TextStyle(color: fieldText),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) =>
                            setModalState(() => selectedGroup = value),
                      ),
                      if (_groups.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Kamu belum punya group. Buat/join group dulu untuk task group.',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: fieldText),
                      decoration: _inputDecoration('Task title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      style: TextStyle(color: fieldText),
                      decoration: _inputDecoration('Description (optional)'),
                    ),
                    const SizedBox(height: 12),
                      DropdownButtonFormField<TaskPriority>(
                      value: selectedPriority,
                      dropdownColor: dropdownBg,
                      decoration: _inputDecoration('Priority'),
                      iconEnabledColor: iconColor,
                      items: [
                        DropdownMenuItem(
                          value: TaskPriority.low,
                          child: Text(
                            'LOW',
                            style: TextStyle(color: fieldText),
                          ),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.medium,
                          child: Text(
                            'MEDIUM',
                            style: TextStyle(color: fieldText),
                          ),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.high,
                          child: Text(
                            'HIGH',
                            style: TextStyle(color: fieldText),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: outline),
                        foregroundColor: fieldText,
                      ),
                      onPressed: pickDueDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        selectedDueDate == null
                            ? 'Set deadline (optional)'
                            : 'Deadline: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}',
                      ),
                    ),
                    if (validationMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        validationMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final description = descriptionController.text
                                    .trim();

                                if (title.isEmpty) {
                                  setModalState(
                                    () => validationMessage =
                                        'Title wajib diisi.',
                                  );
                                  return;
                                }
                                if (selectedScope == TaskScope.group &&
                                    selectedGroup == null) {
                                  setModalState(
                                    () => validationMessage =
                                        'Pilih group dulu untuk task group.',
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                try {
                                  final createdTask = await _taskService
                                      .createTask(
                                        title: title,
                                        description: description,
                                        priority: selectedPriority,
                                        scope: selectedScope,
                                        groupId: selectedGroup?.id,
                                        dueDate: selectedDueDate,
                                      );
                                  if (!mounted) return;
                                  setState(() {
                                    _tasks = <TaskItem>[createdTask, ..._tasks];
                                  });
                                  sheetClosed = true;
                                  Navigator.pop(context, true);
                                } catch (error) {
                                  final message = error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  );
                                  if (!mounted) return;
                                  setModalState(
                                    () => validationMessage = message,
                                  );
                                } finally {
                                  if (!sheetClosed) {
                                    setModalState(() => isSubmitting = false);
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text('Create Task'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (created == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task berhasil dibuat.')));
    }
  }

  Future<void> _updateStatus(TaskItem task, String status) async {
    try {
      final updated = await _taskService.updateTaskStatus(
        taskId: task.id,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _tasks = _tasks
            .map((t) => t.id == task.id ? updated : t)
            .toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    try {
      await _taskService.deleteTask(task.id);
      if (!mounted) return;
      setState(() {
        _tasks = _tasks.where((t) => t.id != task.id).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final content = _buildBody();

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _openCreateTaskSheet,
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final todo = _tasks
        .where((task) => task.status == 'TODO')
        .toList(growable: false);
    final inProgress = _tasks
        .where((task) => task.status == 'IN_PROGRESS')
        .toList(growable: false);
    final done = _tasks
        .where((task) => task.status == 'DONE')
        .toList(growable: false);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadData,
                      icon: Icon(Icons.refresh, color: subColor),
                    ),
                    IconButton(
                      onPressed: _openCreateTaskSheet,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.cyanAccent,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Buat dan kelola task personal atau group.',
                style: TextStyle(color: subColor),
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryCard(
              total: _tasks.length,
              todo: todo.length,
              inProgress: inProgress.length,
              done: done.length,
            ),
            const SizedBox(height: 20),
            _TaskSection(
              title: 'To Do',
              accentColor: const Color(0xFFFFB84C),
              tasks: todo,
              onStatusChanged: _updateStatus,
              onDelete: _deleteTask,
            ),
            const SizedBox(height: 14),
            _TaskSection(
              title: 'In Progress',
              accentColor: const Color(0xFF79E0EE),
              tasks: inProgress,
              onStatusChanged: _updateStatus,
              onDelete: _deleteTask,
            ),
            const SizedBox(height: 14),
            _TaskSection(
              title: 'Done',
              accentColor: const Color(0xFF98D8AA),
              tasks: done,
              onStatusChanged: _updateStatus,
              onDelete: _deleteTask,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int total,
    required int todo,
    required int inProgress,
    required int done,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _TaskStatRow(
            label: 'Total Tasks',
            value: total.toString(),
            color: const Color(0xFF8E8FFA),
          ),
          _TaskStatRow(
            label: 'To Do',
            value: todo.toString(),
            color: const Color(0xFFFFB84C),
          ),
          _TaskStatRow(
            label: 'In Progress',
            value: inProgress.toString(),
            color: const Color(0xFF79E0EE),
          ),
          _TaskStatRow(
            label: 'Completed',
            value: done.toString(),
            color: const Color(0xFF98D8AA),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hint = isDark ? Colors.white38 : const Color(0xFF64748B);
    final fill = isDark ? Colors.white10 : const Color(0xFFF8FAFC);
    final enabled = isDark ? Colors.white12 : const Color(0xFFD1D9E6);
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: hint),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: enabled),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.cyanAccent),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.accentColor,
    required this.tasks,
    this.onStatusChanged,
    this.onDelete,
  });

  final String title;
  final Color accentColor;
  final List<TaskItem> tasks;
  final Future<void> Function(TaskItem task, String status)? onStatusChanged;
  final Future<void> Function(TaskItem task)? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark ? Colors.white.withOpacity(0.04) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final badgeBg = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
    final badgeText = isDark ? Colors.white70 : const Color(0xFF334155);
    final emptyColor = isDark ? Colors.white30 : const Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(Icons.circle, color: accentColor, size: 10),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: badgeBg,
                  child: Text(
                    tasks.length.toString(),
                    style: TextStyle(color: badgeText, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Belum ada task.',
                  style: TextStyle(color: emptyColor),
                ),
              ),
            ),
          if (tasks.isNotEmpty)
            ...tasks.map((task) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: _TaskTile(
                  task: task,
                  onStatusChanged: onStatusChanged,
                  onDelete: onDelete,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, this.onStatusChanged, this.onDelete});

  final TaskItem task;
  final Future<void> Function(TaskItem task, String status)? onStatusChanged;
  final Future<void> Function(TaskItem task)? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white54 : const Color(0xFF64748B);
    final chipText = isDark ? Colors.white70 : const Color(0xFF334155);
    final tileBg = isDark ? Colors.white10 : const Color(0xFFF8FAFC);
    final menuIcon = isDark ? Colors.white54 : const Color(0xFF64748B);
    final dueText = task.dueDate == null
        ? 'No deadline'
        : 'Due ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                icon: Icon(
                  Icons.more_vert,
                  color: menuIcon,
                  size: 18,
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete?.call(task);
                    return;
                  }
                  onStatusChanged?.call(task, value);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'IN_PROGRESS',
                    child: Text('Set In Progress'),
                  ),
                  PopupMenuItem(value: 'DONE', child: Text('Set Done')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: task.isGroupTask
                      ? Colors.deepPurple.withOpacity(0.35)
                      : Colors.blueGrey.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  task.isGroupTask ? 'GROUP' : 'PERSONAL',
                  style: TextStyle(
                    color: chipText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              style: TextStyle(color: chipText, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Priority: ${task.priority}',
                style: TextStyle(color: muted, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Text(
                dueText,
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskStatRow extends StatelessWidget {
  const _TaskStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : const Color(0xFF475569);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
