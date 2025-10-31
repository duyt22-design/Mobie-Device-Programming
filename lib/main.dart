import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_settings.dart';
import 'config/app_localizations.dart';
import 'screens/face_enrollment_screen.dart';
import 'services/database_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/task_management_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/history_screen.dart';
import 'screens/user_list_screen.dart';
import 'screens/user_detail_screen.dart';
import 'screens/drawing_view_screen.dart';
import 'screens/notifications_screen.dart';
import 'utils/drawing_capture.dart';
import 'models/drawing_point.dart';
import 'widgets/leaderboard_widget.dart';

void main() {
  runApp(const DrawingApp());
}

class DrawingApp extends StatefulWidget {
  const DrawingApp({super.key});

  @override
  State<DrawingApp> createState() => _DrawingAppState();
}

class _DrawingAppState extends State<DrawingApp> {
  void updateSettings() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppLocalizations.get('app_title'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: AppSettings.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(onSettingsChanged: updateSettings),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => MainScreen(onSettingsChanged: updateSettings),
      },
    );
  }
}

// Màn hình chính với Bottom Navigation
class MainScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  
  const MainScreen({super.key, this.onSettingsChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final UserProfile userProfile = UserProfile();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      TaskListScreen(
        onSettingsChanged: widget.onSettingsChanged,
        userProfile: userProfile,
        showAppBar: false,
      ),
      UserProfileScreen(
        userProfile: userProfile,
        onSettingsChanged: widget.onSettingsChanged,
        showAppBar: false,
      ),
      NewsScreen(
        userProfile: userProfile,
        showAppBar: false,
      ),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.task_alt),
            label: AppLocalizations.get('tasks'),
            tooltip: AppLocalizations.get('tasks'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.get('my_profile'),
            tooltip: AppLocalizations.get('my_profile'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.newspaper),
            label: AppLocalizations.get('news'),
            tooltip: AppLocalizations.get('news'),
          ),
        ],
      ),
    );
  }
}

// Model cho nhiệm vụ
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

// Model cho lịch sử hoàn thành
class TaskHistory {
  final String taskTitle;
  final DateTime completedAt;
  final double score;
  final int timeUsed; // seconds

  TaskHistory({
    required this.taskTitle,
    required this.completedAt,
    required this.score,
    required this.timeUsed,
  });
}

// Model cho thông tin người dùng
class UserProfile {
  String name;
  String email;
  int totalTasksCompleted;
  double averageScore;
  int rank;
  List<TaskHistory> history;

  UserProfile({
    this.name = 'Nguyễn Văn A',
    this.email = 'nguyenvana@uef.edu.vn',
    this.totalTasksCompleted = 0,
    this.averageScore = 0.0,
    this.rank = 0,
    List<TaskHistory>? history,
  }) : history = history ?? [];

  void addHistory(TaskHistory taskHistory) {
    history.insert(0, taskHistory);
    totalTasksCompleted = history.length;
    if (history.isNotEmpty) {
      averageScore = history.map((h) => h.score).reduce((a, b) => a + b) / history.length;
    }
  }
}

enum TaskType {
  freeDrawing,
  colorCircle,
  colorSquare,
  colorStar,
  colorHeart,
  colorHouse,
  rainbow,
}

// Màn hình danh sách nhiệm vụ
class TaskListScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  final UserProfile? userProfile;
  final bool showAppBar;
  
  const TaskListScreen({
    super.key,
    this.onSettingsChanged,
    this.userProfile,
    this.showAppBar = true,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final UserProfile userProfile;
  final _dbService = DatabaseService();
  List<DrawingTask> tasks = [];
  List<int> _completedTaskIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    userProfile = widget.userProfile ?? UserProfile();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    
    try {
      final tasksData = await _dbService.fetchTasksFromAPI();
      
      // Load completed task IDs
      final completedIds = await _dbService.fetchCompletedTaskIds();
      
      setState(() {
        tasks = tasksData.map<DrawingTask>((data) {
          final taskId = int.tryParse(data['id'].toString()) ?? 0;
          final isCompleted = completedIds.contains(taskId);
          
          // Map task type
          TaskType type = TaskType.freeDrawing;
          final taskType = data['type']?.toString().toLowerCase() ?? '';
          if (taskType.contains('circle')) {
            type = TaskType.colorCircle;
          } else if (taskType.contains('square')) {
            type = TaskType.colorSquare;
          } else if (taskType.contains('star')) {
            type = TaskType.colorStar;
          } else if (taskType.contains('heart')) {
            type = TaskType.colorHeart;
          } else if (taskType.contains('house')) {
            type = TaskType.colorHouse;
          } else if (taskType.contains('rainbow')) {
            type = TaskType.rainbow;
          }
          
          return DrawingTask(
            id: data['id'].toString(),
            title: data['title'] ?? 'Task',
            description: data['description'] ?? '',
            type: type,
            timeLimit: (data['timeLimit'] as int?) ?? 300,
            isCompleted: isCompleted, // Set completed status from database
          );
        }).toList();
        _completedTaskIds = completedIds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      // Fallback to default tasks
      setState(() {
        tasks = _getDefaultTasks();
        _isLoading = false;
      });
    }
  }

  Map<String, String> _localizedLabelsForType(TaskType type) {
    switch (type) {
      case TaskType.freeDrawing:
        return {
          'title': AppLocalizations.get('free_drawing'),
          'desc': AppLocalizations.get('free_drawing_desc'),
        };
      case TaskType.colorCircle:
        return {
          'title': AppLocalizations.get('color_circle'),
          'desc': AppLocalizations.get('color_circle_desc'),
        };
      case TaskType.colorSquare:
        return {
          'title': AppLocalizations.get('color_square'),
          'desc': AppLocalizations.get('color_square_desc'),
        };
      case TaskType.colorStar:
        return {
          'title': AppLocalizations.get('color_star'),
          'desc': AppLocalizations.get('color_star_desc'),
        };
      case TaskType.colorHeart:
        return {
          'title': AppLocalizations.get('color_heart'),
          'desc': AppLocalizations.get('color_heart_desc'),
        };
      case TaskType.colorHouse:
        return {
          'title': AppLocalizations.get('color_house'),
          'desc': AppLocalizations.get('color_house_desc'),
        };
      case TaskType.rainbow:
        return {
          'title': AppLocalizations.get('rainbow'),
          'desc': AppLocalizations.get('rainbow_desc'),
        };
    }
  }

  List<DrawingTask> _getDefaultTasks() => [
    DrawingTask(
      id: '1',
      title: AppLocalizations.get('free_drawing'),
      description: AppLocalizations.get('free_drawing_desc'),
      type: TaskType.freeDrawing,
    ),
    DrawingTask(
      id: '2',
      title: AppLocalizations.get('color_circle'),
      description: AppLocalizations.get('color_circle_desc'),
      type: TaskType.colorCircle,
    ),
    DrawingTask(
      id: '3',
      title: AppLocalizations.get('color_square'),
      description: AppLocalizations.get('color_square_desc'),
      type: TaskType.colorSquare,
    ),
    DrawingTask(
      id: '4',
      title: AppLocalizations.get('color_star'),
      description: AppLocalizations.get('color_star_desc'),
      type: TaskType.colorStar,
    ),
    DrawingTask(
      id: '5',
      title: AppLocalizations.get('color_heart'),
      description: AppLocalizations.get('color_heart_desc'),
      type: TaskType.colorHeart,
    ),
    DrawingTask(
      id: '6',
      title: AppLocalizations.get('color_house'),
      description: AppLocalizations.get('color_house_desc'),
      type: TaskType.colorHouse,
    ),
    DrawingTask(
      id: '7',
      title: AppLocalizations.get('rainbow'),
      description: AppLocalizations.get('rainbow_desc'),
      type: TaskType.rainbow,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    int completedTasks = tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(AppLocalizations.get('tasks_title')),
              centerTitle: true,
              elevation: 2,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userProfile: userProfile,
                          onSettingsChanged: () {
                            widget.onSettingsChanged?.call();
                            setState(() {});
                          },
                        ),
                      ),
                    );
                    // Reload tasks khi quay về (có thể đã thay đổi từ task management)
                    _loadTasks();
                  },
                ),
              ],
            )
          : null,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.get('loading_tasks')),
                ],
              ),
            )
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.get('completed')}: $completedTasks/${tasks.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: task.isCompleted
                          ? Colors.green
                          : Colors.blue.shade300,
                      child: Icon(
                        task.isCompleted ? Icons.check : Icons.palette,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(task.description),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DrawingScreen(
                            task: task,
                            userProfile: userProfile,
                          ),
                        ),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          task.isCompleted = true;
                          userProfile.addHistory(result['history'] as TaskHistory);
                        });
                        
                        // Reload tasks to get updated status
                        _loadTasks();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Màn hình vẽ
class DrawingScreen extends StatefulWidget {
  final DrawingTask task;
  final UserProfile userProfile;

  const DrawingScreen({
    super.key,
    required this.task,
    required this.userProfile,
  });

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<DrawingPoint?> points = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;
  DrawingTool selectedTool = DrawingTool.pen;
  
  // Timer variables
  Timer? _timer;
  late int _remainingSeconds; // Lấy từ task.timeLimit
  bool _timeExpired = false;
  late DateTime _startTime;
  
  // Key để capture canvas
  final GlobalKey _canvasKey = GlobalKey();

  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.task.timeLimit; // Lấy thời gian từ task
    _startTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _timeExpired = true;
          _showTimeExpiredDialog();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Capture canvas thành base64 image
  Future<String?> _captureDrawing() async {
    try {
      RenderRepaintBoundary? boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      // Capture canvas
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      
      Uint8List pngBytes = byteData.buffer.asUint8List();
      String base64Image = base64Encode(pngBytes);
      
      return base64Image;
    } catch (e) {
      debugPrint('Error capturing drawing: $e');
      return null;
    }
  }

  void _showTimeExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('Hết giờ!'),
          ],
        ),
        content: Text(
          'Thời gian ${widget.task.timeLimit ~/ 60} phút đã hết!\n\nBạn có muốn tiếp tục vẽ hay hoàn thành nhiệm vụ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: const Text('Quay lại'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _remainingSeconds = widget.task.timeLimit; // Reset về timeLimit ban đầu
                _timeExpired = false;
                _startTimer();
              });
            },
            child: Text('Thêm ${widget.task.timeLimit ~/ 60} phút'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeTask();
            },
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Xác định màu cho timer dựa trên thời gian còn lại
    Color timerColor = _remainingSeconds > 60
        ? Colors.green
        : _remainingSeconds > 30
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        actions: [
          // Hiển thị thời gian còn lại
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: timerColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _timeExpired ? Icons.timer_off : Icons.timer,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              setState(() {
                if (points.isNotEmpty) {
                  points.removeLast();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                points.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _completeTask();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh công cụ
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Công cụ vẽ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolButton(
                      DrawingTool.pen,
                      Icons.edit,
                      'Bút',
                    ),
                    _buildToolButton(
                      DrawingTool.eraser,
                      Icons.cleaning_services,
                      'Tẩy',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Độ dày nét vẽ
                Row(
                  children: [
                    const SizedBox(width: 16),
                    const Text('Độ dày:'),
                    Expanded(
                      child: Slider(
                        value: strokeWidth,
                        min: 1.0,
                        max: 20.0,
                        onChanged: (value) {
                          setState(() {
                            strokeWidth = value;
                          });
                        },
                      ),
                    ),
                    Text('${strokeWidth.toInt()}'),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
          // Bảng màu
          Container(
            height: 60,
            color: Colors.grey.shade200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = colors[index];
                      selectedTool = DrawingTool.pen;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == colors[index]
                            ? Colors.black
                            : Colors.grey,
                        width: selectedColor == colors[index] ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Canvas vẽ
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  points.add(
                    DrawingPoint(
                      offset: details.localPosition,
                      paint: Paint()
                        ..color = selectedTool == DrawingTool.eraser
                            ? Colors.white
                            : selectedColor
                        ..strokeWidth = strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  points.add(
                    DrawingPoint(
                      offset: details.localPosition,
                      paint: Paint()
                        ..color = selectedTool == DrawingTool.eraser
                            ? Colors.white
                            : selectedColor
                        ..strokeWidth = strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  points.add(null);
                });
              },
              child: Container(
                color: Colors.white,
                child: CustomPaint(
                  painter: DrawingPainter(
                    points: points,
                    taskType: widget.task.type,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = selectedTool == tool;
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          iconSize: 32,
          color: isSelected ? Colors.blue : Colors.grey,
          onPressed: () {
            setState(() {
              selectedTool = tool;
            });
          },
        ),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _completeTask() async {
    _timer?.cancel(); // Dừng timer khi hoàn thành
    
    // Tính thời gian đã sử dụng
    final timeUsed = DateTime.now().difference(_startTime).inSeconds;
    
    // Tính điểm dựa trên thời gian (100 điểm nếu hoàn thành nhanh)
    double score = 100.0;
    if (_timeExpired) {
      score = max(50.0, 100.0 - ((timeUsed - widget.task.timeLimit) / 10)); // Giảm điểm nếu quá giờ
    } else {
      score = min(100.0, 70.0 + (_remainingSeconds / 10)); // Càng nhanh càng cao điểm
    }
    
    // Tạo lịch sử
    final history = TaskHistory(
      taskTitle: widget.task.title,
      completedAt: DateTime.now(),
      score: score,
      timeUsed: timeUsed,
    );
    
    // Capture hình vẽ
    String? drawingBase64;
    try {
      drawingBase64 = await DrawingCapture.captureDrawing(points: points);
    } catch (e) {
      debugPrint('Error capturing drawing: $e');
    }
    
    // Lưu vào database qua API
    Map<String, dynamic>? updatedUser;
    try {
      final currentUser = await DatabaseService().getCurrentUser();
      if (currentUser != null) {
        final success = await DatabaseService().saveTaskHistory(
          userId: currentUser['id'],
          taskTitle: widget.task.title,
          score: score,
          timeUsed: timeUsed,
          drawingData: drawingBase64, // Lưu hình vẽ
        );
        
        // Lấy thông tin user mới sau khi cập nhật điểm và rank
        if (success) {
          updatedUser = await DatabaseService().fetchUserById(currentUser['id']);
        }
      }
    } catch (e) {
      debugPrint('Error saving task history: $e');
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            const Text('Hoàn thành nhiệm vụ!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _timeExpired
                  ? 'Bạn đã hoàn thành nhiệm vụ này!\nHãy thử thách mình với thời gian ngắn hơn lần sau!'
                  : 'Xuất sắc! Bạn đã hoàn thành nhiệm vụ với thời gian còn lại: ${_formatTime(_remainingSeconds)}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Điểm: ${score.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (updatedUser != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Điểm TB: ${(updatedUser['averageScore'] ?? 0).toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Hạng: #${updatedUser['rank'] ?? 0}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Tổng: ${updatedUser['totalTasksCompleted'] ?? 0} nhiệm vụ',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Save task completion to database
              final taskId = int.tryParse(widget.task.id);
              if (taskId != null) {
                try {
                  await DatabaseService().markTaskAsCompleted(taskId);
                } catch (e) {
                  debugPrint('Error marking task as completed: $e');
                }
              }
              
              Navigator.of(context).pop();
              Navigator.of(context).pop({
                'completed': true,
                'history': history,
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

enum DrawingTool { pen, eraser }

// Màn hình thông tin người dùng
class UserProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onSettingsChanged;
  final bool showAppBar;

  const UserProfileScreen({
    super.key,
    required this.userProfile,
    this.onSettingsChanged,
    this.showAppBar = true,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isEditing = false;
  Map<String, dynamic>? _adminStats;
  bool _isLoadingStats = true;
  bool _isAdmin = false; // Kiểm tra quyền admin
  
  // Avatar, birthDate, gender
  String? _avatarBase64;
  DateTime? _selectedBirthDate;
  String _selectedGender = 'other'; // male, female, other
  
  // Face Recognition
  bool _faceEnabled = false;
  bool _hasFaceData = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadAdminStats();
    _loadFaceData();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final user = await _dbService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _nameController.text = user['name'] ?? widget.userProfile.name;
          _emailController.text = user['email'] ?? widget.userProfile.email;
          widget.userProfile.name = user['name'] ?? widget.userProfile.name;
          widget.userProfile.email = user['email'] ?? widget.userProfile.email;
        });
      } else {
        setState(() {
          _nameController.text = widget.userProfile.name;
          _emailController.text = widget.userProfile.email;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _nameController.text = widget.userProfile.name;
        _emailController.text = widget.userProfile.email;
      });
    }
  }

  Future<void> _loadFaceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _faceEnabled = (prefs.getInt('faceEnabled') ?? 0) == 1;
          _hasFaceData = prefs.getString('faceData') != null;
        });
      }
    } catch (e) {
      debugPrint('Error loading face data: $e');
    }
  }

  Future<void> _checkUserRole() async {
    final user = await _dbService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isAdmin = user?['role'] == 'admin';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _avatarBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi chọn ảnh')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = await _dbService.getCurrentUser();
      if (user == null) return;

      final success = await _dbService.updateUserProfile(
        userId: user['id'],
        name: _nameController.text,
        email: _emailController.text,
        birthDate: _selectedBirthDate?.toIso8601String(),
        gender: _selectedGender,
        avatar: _avatarBase64,
      );

      if (mounted) {
        if (success) {
          widget.userProfile.name = _nameController.text;
          widget.userProfile.email = _emailController.text;
          
          setState(() {
            _isEditing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.get('profile_updated'))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.get('profile_update_error'))),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.get('profile_update_error'))),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  // Face Recognition Methods
  Future<void> _enrollFace() async {
    final user = await _dbService.getCurrentUser();
    if (user == null) return;

    if (!mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FaceEnrollmentScreen(
          userId: user['id'],
          userName: user['name'],
        ),
      ),
    );

    if (result == true) {
      // Enrollment successful
      await _loadFaceData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã đăng ký khuôn mặt thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _toggleFaceLogin(bool enabled) async {
    final user = await _dbService.getCurrentUser();
    if (user == null) return;

    final success = await _dbService.toggleFaceLogin(
      userId: user['id'],
      enabled: enabled,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _faceEnabled = enabled;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? '✅ Đã bật đăng nhập bằng khuôn mặt' 
                : '❌ Đã tắt đăng nhập bằng khuôn mặt'
            ),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi thay đổi cài đặt'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAdminStats() async {
    try {
      final stats = await _dbService.fetchAdminStatistics();
      if (mounted) {
        setState(() {
          _adminStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _getTaskIcon(String taskTitle) {
    if (taskTitle.contains('Tròn')) return '⭕';
    if (taskTitle.contains('Vuông')) return '⬛';
    if (taskTitle.contains('Sao')) return '⭐';
    if (taskTitle.contains('Tim')) return '❤️';
    if (taskTitle.contains('Nhà')) return '🏠';
    if (taskTitle.contains('Vồng')) return '🌈';
    return '🎨';
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Tính xếp hạng dựa trên điểm trung bình
    if (widget.userProfile.averageScore >= 90) {
      widget.userProfile.rank = 1;
    } else if (widget.userProfile.averageScore >= 75) {
      widget.userProfile.rank = 5;
    } else if (widget.userProfile.averageScore >= 60) {
      widget.userProfile.rank = 10;
    } else {
      widget.userProfile.rank = 20;
    }

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(AppLocalizations.get('user_profile')),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  tooltip: _isEditing ? AppLocalizations.get('save') : AppLocalizations.get('edit'),
                  onPressed: () {
                    if (_isEditing) {
                      _saveProfile(); // Lưu profile khi đang edit
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                children: [
                  // Header title (only show ADMIN badge for admin users)
                  if (_isAdmin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.get('admin').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // Avatar với nút chọn ảnh
                  Stack(
                    children: [
                      _avatarBase64 != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: MemoryImage(
                                base64Decode(_avatarBase64!),
                              ),
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.blue.shade400,
                              ),
                            ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade400,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tên
                  _isEditing
                      ? TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        )
                      : Text(
                          widget.userProfile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 8),
                  // Email
                  _isEditing
                      ? TextField(
                          controller: _emailController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        )
                      : Text(
                          widget.userProfile.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                  // Ngày sinh và Giới tính khi đang edit
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    // Ngày sinh
                    ElevatedButton.icon(
                      onPressed: _selectBirthDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedBirthDate != null
                            ? 'Ngày sinh: ${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : 'Chọn ngày sinh',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Giới tính
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Giới tính: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedGender,
                          dropdownColor: Colors.blue.shade700,
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'male', child: Text('Nam')),
                            DropdownMenuItem(value: 'female', child: Text('Nữ')),
                            DropdownMenuItem(value: 'other', child: Text('Khác')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedGender = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // FACE RECOGNITION SETTINGS
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.face_retouching_natural,
                            color: Colors.blue.shade600,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.get('face_login'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _hasFaceData 
                            ? Colors.green.shade50 
                            : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasFaceData 
                                ? Icons.check_circle 
                                : Icons.warning,
                              color: _hasFaceData 
                                ? Colors.green 
                                : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _hasFaceData
                                  ? AppLocalizations.get('face_registered')
                                  : AppLocalizations.get('face_not_registered'),
                                style: TextStyle(
                                  color: _hasFaceData 
                                    ? Colors.green.shade700 
                                    : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Enroll Button
                      if (!_hasFaceData)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _enrollFace,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(AppLocalizations.get('register_face')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      
                      // Toggle + Re-enroll
                      if (_hasFaceData) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.get('allow_face_login'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Switch(
                              value: _faceEnabled,
                              onChanged: _toggleFaceLogin,
                              activeThumbColor: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _enrollFace,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLocalizations.get('re_register')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade600,
                              side: BorderSide(color: Colors.blue.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Thống kê quản trị - CHỈ hiển thị với Admin
            if (_isAdmin)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoadingStats
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildGradientStatCard(
                          (_adminStats?['totalAccounts'] ?? 0).toString(),
                          AppLocalizations.get('total_accounts'),
                          [Colors.blue.shade400, Colors.purple.shade400],
                        ),
                        _buildGradientStatCard(
                          (_adminStats?['totalTasks'] ?? 0).toString(),
                          AppLocalizations.get('total_tasks'),
                          [Colors.purple.shade400, Colors.purple.shade600],
                        ),
                        _buildGradientStatCard(
                          (_adminStats?['totalCompletions'] ?? 0).toString(),
                          AppLocalizations.get('total_completed'),
                          [Colors.purple.shade300, Colors.purple.shade500],
                        ),
                        _buildGradientStatCard(
                          (_adminStats?['averageScore'] ?? 0).toStringAsFixed(1),
                          AppLocalizations.get('avg_score'),
                          [Colors.purple.shade500, Colors.purple.shade700],
                        ),
                      ],
                    ),
              ),
            
            // Phần quản lý - CHỈ hiển thị với Admin
            if (_isAdmin) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.blue, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.get('management'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Grid quản lý
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildAdminCard(
                    title: AppLocalizations.get('tasks'),
                    subtitle: AppLocalizations.get('add_edit_delete'),
                    icon: Icons.assignment,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TaskManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildAdminCard(
                    title: AppLocalizations.get('users_management'),
                    subtitle: AppLocalizations.get('history_drawings'),
                    icon: Icons.person_search,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UserListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildAdminCard(
                    title: AppLocalizations.get('users'),
                    subtitle: AppLocalizations.get('user_list'),
                    icon: Icons.people,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildAdminCard(
                    title: AppLocalizations.get('reports'),
                    subtitle: AppLocalizations.get('statistics'),
                    icon: Icons.bar_chart,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ], // Kết thúc if (_isAdmin)
            
            const SizedBox(height: 24),
            
            // Menu
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: Text(AppLocalizations.get('edit_profile')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: Text(AppLocalizations.get('notifications')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.green),
              title: Text(AppLocalizations.get('language')),
              subtitle: Text(
                AppSettings.language == 'vi'
                    ? AppLocalizations.get('vietnamese')
                    : AppLocalizations.get('english'),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLanguageDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.purple),
              title: Text(AppLocalizations.get('theme')),
              subtitle: Text(
                AppSettings.themeMode == ThemeMode.light
                    ? AppLocalizations.get('light_mode')
                    : AppSettings.themeMode == ThemeMode.dark
                        ? AppLocalizations.get('dark_mode')
                        : AppLocalizations.get('system_mode'),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showThemeDialog();
              },
            ),
            const Divider(),
            // Đăng xuất
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                AppLocalizations.get('logout'),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                // Hiển thị dialog xác nhận
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.get('confirm_logout')),
                    content: Text(AppLocalizations.get('confirm_logout_msg')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(AppLocalizations.get('cancel')),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(AppLocalizations.get('logout')),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && mounted) {
                  // Capture navigator before async operation
                  final navigator = Navigator.of(context);
                  // Đăng xuất
                  await DatabaseService().logout();
                  // Quay về màn hình login
                  if (mounted) {
                    navigator.pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                }
              },
            ),
            const Divider(),
            // Lịch sử hoàn thành - Navigate to HistoryScreen
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: Text(AppLocalizations.get('history')),
              subtitle: Text(AppLocalizations.get('review_drawings')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            
            // BẢNG XẾP HẠNG - Hiển thị cho tất cả users
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.get('leaderboard'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.get('top_10'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const LeaderboardWidget(limit: 10),
                ],
              ),
            ),
            
            const Divider(),
            const SizedBox(height: 16),
            
            // Old history preview (keep for backward compatibility)
            if (widget.userProfile.history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.get('recent_completions'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            widget.userProfile.history.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.get('no_history'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.userProfile.history.length,
                    itemBuilder: (context, index) {
                      final history = widget.userProfile.history[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getScoreColor(history.score).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getScoreColor(history.score).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _getTaskIcon(history.taskTitle),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          title: Text(
                            history.taskTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${AppLocalizations.get('completed_at')} ${history.completedAt.day}/${history.completedAt.month}/${history.completedAt.year} ${history.completedAt.hour}:${history.completedAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(history.timeUsed ~/ 60)}:${(history.timeUsed % 60).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(history.score),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              history.score.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(AppLocalizations.get('vietnamese')),
              value: 'vi',
              groupValue: AppSettings.language,
              onChanged: (value) {
                setState(() {
                  AppSettings.language = value!;
                  widget.onSettingsChanged?.call();
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text(AppLocalizations.get('english')),
              value: 'en',
              groupValue: AppSettings.language,
              onChanged: (value) {
                setState(() {
                  AppSettings.language = value!;
                  widget.onSettingsChanged?.call();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('theme')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.get('light_mode')),
              value: ThemeMode.light,
              groupValue: AppSettings.themeMode,
              onChanged: (value) {
                setState(() {
                  AppSettings.themeMode = value!;
                  widget.onSettingsChanged?.call();
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.get('dark_mode')),
              value: ThemeMode.dark,
              groupValue: AppSettings.themeMode,
              onChanged: (value) {
                setState(() {
                  AppSettings.themeMode = value!;
                  widget.onSettingsChanged?.call();
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalizations.get('system_mode')),
              value: ThemeMode.system,
              groupValue: AppSettings.themeMode,
              onChanged: (value) {
                setState(() {
                  AppSettings.themeMode = value!;
                  widget.onSettingsChanged?.call();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientStatCard(String value, String label, List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Màn hình tin tức
class NewsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final bool showAppBar;

  const NewsScreen({
    super.key,
    required this.userProfile,
    this.showAppBar = true,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(AppLocalizations.get('news')),
              centerTitle: true,
              elevation: 2,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          if (!widget.showAppBar)
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 16),
              child: Text(
                AppLocalizations.get('news'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Phần nhiệm vụ mới
          _buildSectionHeader(AppLocalizations.get('new_tasks'), Icons.new_releases),
          const SizedBox(height: 12),
          
          _buildNewsCard(
            title: AppLocalizations.get('color_star'),
            description: AppLocalizations.get('color_star_desc'),
            icon: '⭐',
            color: Colors.amber,
            tag: 'NEW',
          ),
          
          _buildNewsCard(
            title: AppLocalizations.get('rainbow'),
            description: AppLocalizations.get('rainbow_desc'),
            icon: '🌈',
            color: Colors.purple,
            tag: 'NEW',
          ),
          
          const SizedBox(height: 24),
          
          // Phần phần thưởng
          _buildSectionHeader(AppLocalizations.get('rewards'), Icons.card_giftcard),
          const SizedBox(height: 12),
          
          // Hiển thị phần thưởng từ lịch sử
          ...widget.userProfile.history.take(5).map((history) {
            return _buildRewardCard(
              taskTitle: history.taskTitle,
              score: history.score,
              completedAt: history.completedAt,
            );
          }),
          
          if (widget.userProfile.history.isEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.get('complete_tasks_reward'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard({
    required String title,
    required String description,
    required String icon,
    required Color color,
    required String tag,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard({
    required String taskTitle,
    required double score,
    required DateTime completedAt,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.get('congratulations'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      taskTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${completedAt.day}/${completedAt.month}/${completedAt.year}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${score.toInt()} ${AppLocalizations.get('points')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final TaskType taskType;

  DrawingPainter({required this.points, required this.taskType});

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ hình mẫu cho nhiệm vụ (nếu có)
    _drawTaskTemplate(canvas, size);

    // Vẽ các nét của người dùng
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      }
    }
  }

  void _drawTaskTemplate(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);

    switch (taskType) {
      case TaskType.colorCircle:
        canvas.drawCircle(center, 100, paint);
        break;

      case TaskType.colorSquare:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: 200, height: 200),
          paint,
        );
        break;

      case TaskType.colorStar:
        _drawStar(canvas, center, 100, paint);
        break;

      case TaskType.colorHeart:
        _drawHeart(canvas, center, 100, paint);
        break;

      case TaskType.colorHouse:
        _drawHouse(canvas, center, paint);
        break;

      case TaskType.rainbow:
        _drawRainbowGuide(canvas, center, paint);
        break;

      case TaskType.freeDrawing:
        // Không vẽ gì
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const numberOfPoints = 5;
    final angle = (pi * 2) / numberOfPoints;

    for (int i = 0; i < numberOfPoints * 2; i++) {
      final r = i.isEven ? radius : radius / 2;
      final x = center.dx + r * cos(i * angle / 2 - pi / 2);
      final y = center.dy + r * sin(i * angle / 2 - pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size / 4);

    path.cubicTo(
      center.dx - size / 2,
      center.dy - size / 4,
      center.dx - size,
      center.dy + size / 5,
      center.dx,
      center.dy + size,
    );

    path.moveTo(center.dx, center.dy + size / 4);

    path.cubicTo(
      center.dx + size / 2,
      center.dy - size / 4,
      center.dx + size,
      center.dy + size / 5,
      center.dx,
      center.dy + size,
    );

    canvas.drawPath(path, paint);
  }

  void _drawHouse(Canvas canvas, Offset center, Paint paint) {
    // Tường nhà
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 160, height: 120),
      paint,
    );

    // Mái nhà
    final roofPath = Path();
    roofPath.moveTo(center.dx - 100, center.dy - 60);
    roofPath.lineTo(center.dx, center.dy - 120);
    roofPath.lineTo(center.dx + 100, center.dy - 60);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Cửa
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 25, center.dy + 10, 50, 70),
      paint,
    );

    // Cửa sổ
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 70, center.dy - 20, 40, 40),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx + 30, center.dy - 20, 40, 40),
      paint,
    );
  }

  void _drawRainbowGuide(Canvas canvas, Offset center, Paint paint) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];

    for (int i = 0; i < colors.length; i++) {
      final arcPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;

      canvas.drawArc(
        Rect.fromCenter(
          center: center,
          width: 300 - (i * 20),
          height: 300 - (i * 20),
        ),
        pi,
        pi,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
