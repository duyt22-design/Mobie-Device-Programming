import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../config/app_localizations.dart';
import '../config/app_settings.dart';
import '../main.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with AutomaticKeepAliveClientMixin {
  final _dbService = DatabaseService();
  List<Map<String, dynamic>> _recentTasks = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Auto-refresh mỗi 5 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_isLoading && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }
    
    final tasks = await _dbService.fetchRecentTasks();
    final notifs = await _dbService.fetchNotifications();
    
    if (mounted) {
      setState(() {
        _recentTasks = tasks;
        _notifications = notifs.where((n) => n['type'] == 'achievement').toList();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    await _dbService.markNotificationAsRead(id);
    _loadData();
  }

  Future<void> _delete(int id) async {
    await _dbService.deleteNotification(id);
    _loadData();
  }

  Future<void> _navigateToTask(Map<String, dynamic> task) async {
    // Lấy thông tin user hiện tại
    final currentUser = await _dbService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập lại')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DrawingScreen(
            task: DrawingTask(
              id: task['id'],
              title: task['title'] ?? '',
              description: task['description'] ?? '',
              type: task['type'] ?? 'freestyle',
              timeLimit: task['timeLimit'] ?? 300,
            ),
            userProfile: UserProfile(
              name: currentUser['name'] ?? '',
              email: currentUser['email'] ?? '',
              totalTasksCompleted: currentUser['totalTasksCompleted'] ?? 0,
              averageScore: (currentUser['averageScore'] ?? 0.0).toDouble(),
              rank: currentUser['rank'] ?? 0,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign, color: Colors.white),
            SizedBox(width: 8),
            Text('Tin tức'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.purple.shade600],
            ),
          ),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: _loadData,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ========== NHIỆM VỤ MỚI ==========
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue.shade600, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Nhiệm vụ mới',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _recentTasks.isEmpty ? Colors.grey : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_recentTasks.length} tasks',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_isRefreshing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // DEBUG: Test button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        print('🔴 DEBUG: Manual test button clicked');
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Loaded ${_recentTasks.length} tasks. Check console!'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.bug_report),
                      label: Text('TEST: Load Tasks (${_recentTasks.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_recentTasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa có nhiệm vụ mới nào',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._recentTasks.map((task) => _buildTaskCard(task)),
                  
                  const SizedBox(height: 32),
                  
                  // ========== PHẦN THƯỞNG ==========
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Phần thưởng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_notifications.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.card_giftcard, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Hoàn thành nhiệm vụ để nhận phần thưởng!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._notifications.map((notif) => _buildNotificationCard(notif)),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final createdAt = DateTime.parse(task['createdAt']);
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    final isNew = diff.inHours < 48; // Mới trong vòng 2 ngày

    Color taskColor;
    IconData taskIcon;
    
    switch (task['type']) {
      case 'star':
        taskColor = Colors.yellow.shade100;
        taskIcon = Icons.star;
        break;
      case 'rainbow':
        taskColor = Colors.purple.shade100;
        taskIcon = Icons.auto_awesome;
        break;
      default:
        taskColor = Colors.blue.shade100;
        taskIcon = Icons.brush;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: taskColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToTask(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    taskIcon,
                    size: 32,
                    color: taskColor == Colors.yellow.shade100 
                        ? Colors.amber.shade700 
                        : taskColor == Colors.purple.shade100
                            ? Colors.purple.shade700
                            : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task['description'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // NEW badge
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final isUnread = notif['isRead'] == 0;

    return Dismissible(
      key: Key('notif_${notif['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _delete(notif['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? Colors.amber.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? Colors.amber.shade200 : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 28,
            ),
          ),
          title: Text(
            notif['title'] ?? '',
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notif['message'] ?? ''),
              const SizedBox(height: 4),
              Text(
                _formatTime(notif['createdAt']),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: isUnread
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            if (isUnread) {
              _markAsRead(notif['id']);
            }
          },
        ),
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
      if (diff.inDays < 1) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
