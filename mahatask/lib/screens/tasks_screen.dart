import 'package:flutter/material.dart';

import '../services/task_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with AutomaticKeepAliveClientMixin {
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
      backgroundColor: const Color(0xFF161616),
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
                    const Text(
                      'Create Task',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Scope', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text('Personal'),
                          selected: selectedScope == TaskScope.personal,
                          onSelected: (_) => setModalState(() => selectedScope = TaskScope.personal),
                        ),
                        ChoiceChip(
                          label: const Text('Group'),
                          selected: selectedScope == TaskScope.group,
                          onSelected: (_) => setModalState(() => selectedScope = TaskScope.group),
                        ),
                      ],
                    ),
                    if (selectedScope == TaskScope.group) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GroupOption>(
                        value: selectedGroup,
                        dropdownColor: const Color(0xFF262626),
                        decoration: _inputDecoration('Choose group'),
                        iconEnabledColor: Colors.white,
                        items: _groups
                            .map(
                              (group) => DropdownMenuItem<GroupOption>(
                                value: group,
                                child: Text(group.name, style: const TextStyle(color: Colors.white)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => setModalState(() => selectedGroup = value),
                      ),
                      if (_groups.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Kamu belum punya group. Buat/join group dulu untuk task group.',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Task title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Description (optional)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskPriority>(
                      value: selectedPriority,
                      dropdownColor: const Color(0xFF262626),
                      decoration: _inputDecoration('Priority'),
                      iconEnabledColor: Colors.white,
                      items: const [
                        DropdownMenuItem(value: TaskPriority.low, child: Text('LOW', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: TaskPriority.medium, child: Text('MEDIUM', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: TaskPriority.high, child: Text('HIGH', style: TextStyle(color: Colors.white))),
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
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white,
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
                      Text(validationMessage!, style: const TextStyle(color: Colors.redAccent)),
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
                                final description = descriptionController.text.trim();

                                if (title.isEmpty) {
                                  setModalState(() => validationMessage = 'Title wajib diisi.');
                                  return;
                                }
                                if (selectedScope == TaskScope.group && selectedGroup == null) {
                                  setModalState(() => validationMessage = 'Pilih group dulu untuk task group.');
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                try {
                                  final createdTask = await _taskService.createTask(
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
                                  final message = error.toString().replaceFirst('Exception: ', '');
                                  if (!mounted) return;
                                  setModalState(() => validationMessage = message);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task berhasil dibuat.')),
      );
    }
  }

  Future<void> _updateStatus(TaskItem task, String status) async {
    try {
      final updated = await _taskService.updateTaskStatus(taskId: task.id, status: status);
      if (!mounted) return;
      setState(() {
        _tasks = _tasks.map((t) => t.id == task.id ? updated : t).toList(growable: false);
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
      backgroundColor: const Color(0xFF0D0D0D),
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
              Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final todo = _tasks.where((task) => task.status == 'TODO').toList(growable: false);
    final inProgress = _tasks.where((task) => task.status == 'IN_PROGRESS').toList(growable: false);
    final done = _tasks.where((task) => task.status == 'DONE').toList(growable: false);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh, color: Colors.white54),
                    ),
                    IconButton(
                      onPressed: _openCreateTaskSheet,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 30),
                    ),
                  ],
                ),
              ],
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Buat dan kelola task personal atau group.', style: TextStyle(color: Colors.white54)),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _TaskStatRow(label: 'Total Tasks', value: total.toString(), color: const Color(0xFF8E8FFA)),
          _TaskStatRow(label: 'To Do', value: todo.toString(), color: const Color(0xFFFFB84C)),
          _TaskStatRow(label: 'In Progress', value: inProgress.toString(), color: const Color(0xFF79E0EE)),
          _TaskStatRow(label: 'Completed', value: done.toString(), color: const Color(0xFF98D8AA)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white10,
                  child: Text(
                    tasks.length.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Belum ada task.', style: TextStyle(color: Colors.white30)),
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
  const _TaskTile({
    required this.task,
    this.onStatusChanged,
    this.onDelete,
  });

  final TaskItem task;
  final Future<void> Function(TaskItem task, String status)? onStatusChanged;
  final Future<void> Function(TaskItem task)? onDelete;

  @override
  Widget build(BuildContext context) {
    final dueText = task.dueDate == null
        ? 'No deadline'
        : 'Due ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF1E1E1E),
                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete?.call(task);
                    return;
                  }
                  onStatusChanged?.call(task, value);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'IN_PROGRESS', child: Text('Set In Progress')),
                  PopupMenuItem(value: 'DONE', child: Text('Set Done')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: task.isGroupTask ? Colors.deepPurple.withOpacity(0.35) : Colors.blueGrey.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  task.isGroupTask ? 'GROUP' : 'PERSONAL',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(task.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Priority: ${task.priority}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 12),
              Text(dueText, style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
