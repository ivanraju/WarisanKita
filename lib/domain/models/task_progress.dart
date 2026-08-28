class TaskProgress {
  final String userId;
  final String taskId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int progressSeconds;
  final DateTime? trackingStartedAt;

  const TaskProgress({
    required this.userId,
    required this.taskId,
    required this.isCompleted,
    required this.completedAt,
    required this.progressSeconds,
    required this.trackingStartedAt,
  });

  factory TaskProgress.fromMap(Map<String, dynamic> map) {
    return TaskProgress(
      userId: _requiredString(map, 'user_id'),
      taskId: _requiredString(map, 'task_id'),
      isCompleted: _requiredBool(map, 'is_completed'),
      completedAt: _optionalDateTime(map['completed_at']),
      progressSeconds: _requiredInt(map, 'progress_seconds'),
      trackingStartedAt: _optionalDateTime(map['tracking_started_at']),
    );
  }

  factory TaskProgress.fromJson(Map<String, dynamic> json) =>
      TaskProgress.fromMap(json);

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Task progress field "$key" is missing or invalid.',
      );
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is bool) return value;
    throw FormatException('Task progress field "$key" is missing or invalid.');
  }

  static int _requiredInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value.toInt();
    throw FormatException('Task progress field "$key" is missing or invalid.');
  }

  static DateTime? _optionalDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
