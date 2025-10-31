class UserProfile {
  String name;
  String email;
  int totalTasksCompleted;
  double averageScore;
  int rank;
  List<TaskHistory> history;

  UserProfile({
    this.name = 'Người dùng',
    this.email = 'user@example.com',
    this.totalTasksCompleted = 0,
    this.averageScore = 0.0,
    this.rank = 0,
    List<TaskHistory>? history,
  }) : history = history ?? [];

  void addHistory(TaskHistory record) {
    history.insert(0, record);
    totalTasksCompleted++;
    
    // Tính điểm trung bình
    double total = 0;
    for (var h in history) {
      total += h.score;
    }
    averageScore = history.isEmpty ? 0 : total / history.length;
  }
}

class TaskHistory {
  final String taskTitle;
  final double score;
  final int timeUsed;
  final DateTime completedAt;

  TaskHistory({
    required this.taskTitle,
    required this.score,
    required this.timeUsed,
    required this.completedAt,
  });
}

