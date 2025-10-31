import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final _dbService = DatabaseService();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _dbService.fetchTasksFromAPI();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTaskTypeLabel(String type) {
    const typeMap = {
      'freeDrawing': 'Vẽ tự do',
      'colorCircle': 'Tô màu hình tròn',
      'colorSquare': 'Tô màu hình vuông',
      'colorStar': 'Tô màu ngôi sao',
      'colorHeart': 'Tô màu trái tim',
      'colorHouse': 'Tô màu ngôi nhà',
      'rainbow': 'Vẽ cầu vồng',
    };
    return typeMap[type] ?? type;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteTask(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa nhiệm vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _dbService.deleteTaskFromAPI(id);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xóa nhiệm vụ thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            _loadTasks();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể xóa nhiệm vụ!'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showTaskDialog({Map<String, dynamic>? task}) {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?['title'] ?? '');
    final descController = TextEditingController(text: task?['description'] ?? '');
    String selectedType = task?['type'] ?? 'freeDrawing';
    int timeLimit = task?['timeLimit'] ?? 300;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Sửa Nhiệm Vụ' : 'Thêm Nhiệm Vụ Mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên nhiệm vụ
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhiệm vụ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Mô tả
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Loại nhiệm vụ
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại nhiệm vụ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'freeDrawing', child: Text('Vẽ tự do')),
                    DropdownMenuItem(value: 'colorCircle', child: Text('Tô màu hình tròn')),
                    DropdownMenuItem(value: 'colorSquare', child: Text('Tô màu hình vuông')),
                    DropdownMenuItem(value: 'colorStar', child: Text('Tô màu ngôi sao')),
                    DropdownMenuItem(value: 'colorHeart', child: Text('Tô màu trái tim')),
                    DropdownMenuItem(value: 'colorHouse', child: Text('Tô màu ngôi nhà')),
                    DropdownMenuItem(value: 'rainbow', child: Text('Vẽ cầu vồng')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Thời gian giới hạn
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời gian giới hạn: ${_formatTime(timeLimit)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: timeLimit.toDouble(),
                      min: 60,
                      max: 600,
                      divisions: 54,
                      label: _formatTime(timeLimit),
                      onChanged: (value) {
                        setDialogState(() => timeLimit = value.toInt());
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('1:00', style: TextStyle(fontSize: 12)),
                        const Text('10:00', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descController.text.trim();

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập tên nhiệm vụ!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final taskData = {
                  'title': title,
                  'description': description,
                  'type': selectedType,
                  'timeLimit': timeLimit,
                  'isCompleted': task?['isCompleted'] ?? 0,
                };

                try {
                  bool success;
                  if (isEditing) {
                    success = await _dbService.updateTaskInAPI(task['id'], taskData);
                  } else {
                    success = await _dbService.addTaskToAPI(taskData);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Cập nhật thành công!' : 'Thêm nhiệm vụ thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadTasks();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thao tác thất bại!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Lưu' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Nhiệm Vụ'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có nhiệm vụ nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade300, Colors.purple.shade300],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.task_alt, color: Colors.white),
                          ),
                          title: Text(
                            task['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                task['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getTaskTypeLabel(task['type'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 14,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTime(task['timeLimit'] ?? 300),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showTaskDialog(task: task),
                                tooltip: 'Sửa',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteTask(task['id']),
                                tooltip: 'Xóa',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhiệm vụ'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }
}

