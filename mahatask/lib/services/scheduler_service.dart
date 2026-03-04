import 'api_client.dart';
import 'task_service.dart';

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      startTime: DateTime.tryParse((json['startTime'] ?? '').toString()) ?? DateTime.now(),
      endTime: DateTime.tryParse((json['endTime'] ?? '').toString()) ?? DateTime.now(),
      description: json['description']?.toString(),
    );
  }
}

class SchedulerService {
  SchedulerService({
    ApiClient? client,
    TaskService? taskService,
  })  : _client = client ?? ApiClient(),
        _taskService = taskService ?? TaskService();

  final ApiClient _client;
  final TaskService _taskService;

  Future<List<ScheduleItem>> fetchSchedules() async {
    final data = await _client.get('/schedules');
    if (data is! List) return const <ScheduleItem>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ScheduleItem.fromJson)
        .toList(growable: false);
  }

  Future<List<TaskItem>> fetchDeadlines() {
    return _taskService.fetchTasks();
  }

  Future<void> createSchedule({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? groupId,
  }) async {
    await _client.post(
      '/schedules',
      body: <String, dynamic>{
        'title': title.trim(),
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        'description': (description ?? '').trim(),
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
      },
    );
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _client.delete('/schedules/$scheduleId');
  }
}
