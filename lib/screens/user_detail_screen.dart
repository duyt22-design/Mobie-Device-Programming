import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'drawing_view_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _dbService = DatabaseService();
  Map<String, dynamic>? _userInfo;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // Lấy thông tin user
      final userInfo = await _dbService.fetchUserById(widget.userId);
      
      // Lấy lịch sử (cần fetch theo userId cụ thể)
      // Tạm thời call API trực tiếp
      final response = await DatabaseService().fetchUserHistoryById(widget.userId);
      
      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _history = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUserRole(String newRole) async {
    try {
      final success = await _dbService.updateUserProfile(
        userId: widget.userId,
        name: _userInfo?['name'],
        email: _userInfo?['email'],
        role: newRole,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật role thành: ${newRole == 'admin' ? 'Admin' : 'User'}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUserData(); // Reload data
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật role'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi cập nhật role'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAvatar(String? avatarBase64, String? gender) {
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(avatarBase64);
        return CircleAvatar(
          radius: 60,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        return _buildDefaultAvatar(gender);
      }
    }
    return _buildDefaultAvatar(gender);
  }

  Widget _buildDefaultAvatar(String? gender) {
    IconData icon;
    Color color;
    
    switch (gender) {
      case 'male':
        icon = Icons.face;
        color = Colors.blue.shade400;
        break;
      case 'female':
        icon = Icons.face_3;
        color = Colors.pink.shade400;
        break;
      default:
        icon = Icons.person;
        color = Colors.grey.shade400;
    }
    
    return CircleAvatar(
      radius: 60,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, size: 70, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadUserData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // User info header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.purple.shade400],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildAvatar(_userInfo?['avatar'], _userInfo?['gender']),
                          const SizedBox(height: 16),
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _userInfo?['email'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Xếp hạng',
                              '#${_userInfo?['rank'] ?? 0}',
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Điểm TB',
                              (_userInfo?['averageScore'] ?? 0).toStringAsFixed(1),
                              Icons.star,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Hoàn thành',
                              '${_userInfo?['totalTasksCompleted'] ?? 0}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Role Management
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildRoleManagement(),
                    ),

                    // History
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history, color: Colors.blue, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Lịch sử vẽ (${_history.length})',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _history.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'Chưa có lịch sử nào',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _history.length,
                                  itemBuilder: (context, index) {
                                    final item = _history[index];
                                    return _buildHistoryCard(item);
                                  },
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

  Widget _buildRoleManagement() {
    final currentRole = _userInfo?['role'] ?? 'user';
    final isAdmin = currentRole == 'admin';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: isAdmin ? Colors.red : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Phân quyền',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAdmin ? Colors.red.shade200 : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAdmin ? Icons.verified_user : Icons.person,
                          color: isAdmin ? Colors.red : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAdmin ? 'ADMIN' : 'USER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAdmin ? Colors.red : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showRoleChangeDialog(currentRole);
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Đổi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleChangeDialog(String currentRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thay đổi phân quyền'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bạn muốn thay đổi quyền của ${widget.userName} thành:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('User'),
                subtitle: const Text('Quyền thường'),
                tileColor: currentRole == 'user' ? Colors.blue.shade50 : null,
                onTap: () {
                  Navigator.pop(context);
                  if (currentRole != 'user') {
                    _updateUserRole('user');
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: const Text('Admin'),
                subtitle: const Text('Toàn quyền quản trị'),
                tileColor: currentRole == 'admin' ? Colors.red.shade50 : null,
                onTap: () {
                  Navigator.pop(context);
                  if (currentRole != 'admin') {
                    _updateUserRole('admin');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final String? drawingData = item['drawingData'];
    final double score = (item['score'] ?? 0).toDouble();
    final int timeUsed = item['timeUsed'] ?? 0;
    final String taskTitle = item['taskTitle'] ?? 'Unknown Task';
    final String completedAt = item['completedAt'] ?? '';
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: drawingData != null && drawingData.isNotEmpty
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DrawingViewScreen(
                      drawingData: drawingData,
                      taskTitle: taskTitle,
                      score: score,
                      timeUsed: timeUsed,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: drawingData != null && drawingData.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(drawingData),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported, color: Colors.grey);
                          },
                        ),
                      )
                    : const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          score.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timer, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${(timeUsed / 60).floor()}:${(timeUsed % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(completedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (drawingData != null && drawingData.isNotEmpty)
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

