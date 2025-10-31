enum TaskType {
  freeDrawing,
  colorCircle,
  colorSquare,
  colorStar,
  colorHeart,
  colorHouse,
  rainbow,
}

class DrawingTask {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final int timeLimit; // seconds
  bool isCompleted;

  DrawingTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.timeLimit = 300, // default 5 minutes
    this.isCompleted = false,
  });
}

enum DrawingTool { pen, eraser }

