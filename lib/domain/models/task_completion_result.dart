import 'package:warisan_kita/domain/models/task_progress.dart';

class TaskCompletionResult {
  final TaskProgress progress;
  final int? xpAwarded;

  const TaskCompletionResult({required this.progress, this.xpAwarded});

  factory TaskCompletionResult.fromMap(Map<String, dynamic> map) {
    final progressValue = map['progress'];
    if (progressValue is! Map) {
      throw const FormatException('Task completion progress is missing.');
    }
    final xpValue = map['xp_awarded'];
    final parsedXp = xpValue is num
        ? xpValue.toInt()
        : int.tryParse(xpValue?.toString() ?? '');
    return TaskCompletionResult(
      progress: TaskProgress.fromMap(Map<String, dynamic>.from(progressValue)),
      xpAwarded: parsedXp == null || parsedXp < 0 ? null : parsedXp,
    );
  }
}
