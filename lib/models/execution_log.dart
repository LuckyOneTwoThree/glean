/// 执行日志模型
/// 用于记录采集/评分/简报生成的执行状态
class ExecutionLog {
  final String id;
  final String taskType; // "fetch" | "score" | "briefing"
  final String status; // "success" | "failed"
  final int startedAt;
  final int? completedAt;
  final int? duration;
  final String? errorMessage;
  final String? details;
  final String? label;

  const ExecutionLog({
    required this.id,
    required this.taskType,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.duration,
    this.errorMessage,
    this.details,
    this.label,
  });

  factory ExecutionLog.fromMap(Map<String, dynamic> map) {
    return ExecutionLog(
      id: map['id'] as String,
      taskType: map['task_type'] as String,
      status: map['status'] as String,
      startedAt: map['started_at'] as int,
      completedAt: map['completed_at'] as int?,
      duration: map['duration'] as int?,
      errorMessage: map['error_message'] as String?,
      details: map['details'] as String?,
      label: map['label'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_type': taskType,
      'status': status,
      'started_at': startedAt,
      'completed_at': completedAt,
      'duration': duration,
      'error_message': errorMessage,
      'details': details,
      'label': label,
    };
  }
}
