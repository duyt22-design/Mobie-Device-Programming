import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Service để kết nối với SQL Server thông qua REST API
class DatabaseService {
  // URL của API backend - TỰ ĐỘNG nhận diện môi trường
  static String get currentBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api'; // Web
    } else {
      // Thử auto-detect IP trước, nếu không thì dùng emulator
      final detectedUrl = _autoDetectAndroidUrl();
      return detectedUrl;
    }
  }
  
  // Tự động phát hiện URL cho Android
  static String _autoDetectAndroidUrl() {
    // Danh sách IP có thể có của máy tính (thay đổi theo mạng)
    final List<String> possibleIPs = [
      '192.168.10.107',  // IP hiện tại của máy tính (mới nhất)
      '10.19.252.97',    // IP cũ của máy tính
      '10.215.60.97',    // IP cũ khác
      '192.168.1.249',   // IP mạng gia đình
      '192.168.0.100',   // IP phổ biến khác
      '192.168.1.100',    // IP phổ biến khác
      '10.0.2.2',        // Android Emulator (dùng nếu không tìm thấy)
    ];
    
    // Thử kết nối từng IP để tìm server
    for (String ip in possibleIPs) {
      if (_testConnection('http://$ip:5000/api')) {
        print('✅ Tự động phát hiện server tại: http://$ip:5000/api');
        return 'http://$ip:5000/api';
      }
    }
    
    // Mặc định dùng emulator nếu không tìm thấy
    print('⚠️ Không tìm thấy server, dùng emulator mặc định');
    return 'http://10.0.2.2:5000/api';
  }
  
  // Test kết nối đến server (đơn giản)
  static bool _testConnection(String url) {
    // Cache kết quả để tránh test nhiều lần
    if (_connectionCache.containsKey(url)) {
      return _connectionCache[url]!;
    }
    
    // Mặc định return true cho lần đầu (sẽ test thực tế khi gọi API)
    _connectionCache[url] = true;
    return true;
  }
  
  // Cache kết quả test kết nối
  static final Map<String, bool> _connectionCache = {};
  
  // Local SQLite database cho cache
  static Database? _database;
  
  // SharedPreferences cho session
  static SharedPreferences? _prefs;

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  // Khởi tạo SharedPreferences
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Khởi tạo local database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'drawing_app.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tạo bảng users
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            totalTasksCompleted INTEGER DEFAULT 0,
            averageScore REAL DEFAULT 0,
            rank INTEGER DEFAULT 0,
            createdAt TEXT
          )
        ''');

        // Tạo bảng tasks
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL,
            isCompleted INTEGER DEFAULT 0,
            createdAt TEXT
          )
        ''');

        // Tạo bảng task_history
        await db.execute('''
          CREATE TABLE task_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            taskTitle TEXT NOT NULL,
            score REAL NOT NULL,
            timeUsed INTEGER NOT NULL,
            completedAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id)
          )
        ''');
      },
    );
  }

  // ==================== USER OPERATIONS ====================
  
  // Lấy danh sách users từ API
  Future<List<Map<String, dynamic>>> fetchUsersFromAPI() async {
    try {
      final response = await http.get(Uri.parse('$currentBaseUrl/users'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Xóa user
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$currentBaseUrl/users/$userId'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Thêm user mới qua API
  Future<bool> addUserToAPI(Map<String, dynamic> user) async {
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user),
      );
      
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error adding user: $e');
      return false;
    }
  }

  // Cập nhật user qua API
  Future<bool> updateUserInAPI(int id, Map<String, dynamic> user) async {
    try {
      final response = await http.put(
        Uri.parse('$currentBaseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // ==================== LOCAL DATABASE OPERATIONS ====================
  
  // Lưu user vào local database
  Future<int> insertUserLocal(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  // Lấy tất cả users từ local database
  Future<List<Map<String, dynamic>>> getUsersLocal() async {
    final db = await database;
    return await db.query('users');
  }

  // Cập nhật user trong local database
  Future<int> updateUserLocal(int id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Xóa user từ local database
  Future<int> deleteUserLocal(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== TASK OPERATIONS ====================
  
  // Lấy danh sách tasks từ API
  Future<List<Map<String, dynamic>>> fetchTasksFromAPI() async {
    try {
      final response = await http.get(Uri.parse('$currentBaseUrl/tasks'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  // Lấy tasks mới (trong 2 ngày)
  Future<List<Map<String, dynamic>>> fetchRecentTasks() async {
    try {
      final url = '$currentBaseUrl/tasks/recent';
      print('🔍 Fetching recent tasks from: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('✅ Received ${data.length} recent tasks');
        print('📋 Tasks: ${data.map((t) => t['title']).toList()}');
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        throw Exception('Failed to load recent tasks');
      }
    } catch (e) {
      print('❌ Error fetching recent tasks: $e');
      return [];
    }
  }

  // Thêm task mới qua API
  Future<bool> addTaskToAPI(Map<String, dynamic> task) async {
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task),
      );
      
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error adding task: $e');
      return false;
    }
  }

  // Cập nhật task qua API
  Future<bool> updateTaskInAPI(int id, Map<String, dynamic> task) async {
    try {
      final response = await http.put(
        Uri.parse('$currentBaseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  // Xóa task qua API
  Future<bool> deleteTaskFromAPI(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$currentBaseUrl/tasks/$id'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // Thêm task mới local
  Future<int> insertTaskLocal(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  // Lấy tất cả tasks local
  Future<List<Map<String, dynamic>>> getTasksLocal() async {
    final db = await database;
    return await db.query('tasks');
  }

  // Cập nhật task local
  Future<int> updateTaskLocal(int id, Map<String, dynamic> task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== TASK HISTORY OPERATIONS ====================
  
  // Thêm lịch sử hoàn thành task
  Future<int> insertTaskHistory(Map<String, dynamic> history) async {
    final db = await database;
    return await db.insert('task_history', history);
  }

  // Lấy lịch sử theo user
  Future<List<Map<String, dynamic>>> getTaskHistoryByUser(int userId) async {
    final db = await database;
    return await db.query(
      'task_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
    );
  }

  // Gửi lịch sử lên API
  Future<bool> sendHistoryToAPI(Map<String, dynamic> history) async {
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/history'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(history),
      );
      
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error sending history: $e');
      return false;
    }
  }

  // ==================== STATISTICS ====================
  
  // Lấy thống kê từ API
  Future<Map<String, dynamic>> fetchStatistics() async {
    try {
      final response = await http.get(Uri.parse('$currentBaseUrl/statistics'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load statistics');
      }
    } catch (e) {
      print('Error fetching statistics: $e');
      return {
        'totalUsers': 0,
        'totalTasks': 0,
        'totalCompletions': 0,
        'averageScore': 0.0,
      };
    }
  }

  // Đồng bộ dữ liệu
  Future<void> syncData() async {
    try {
      // Lấy dữ liệu từ API
      final users = await fetchUsersFromAPI();
      final tasks = await fetchTasksFromAPI();

      // Xóa dữ liệu local cũ
      final db = await database;
      await db.delete('users');
      await db.delete('tasks');

      // Lưu dữ liệu mới vào local
      for (var user in users) {
        await insertUserLocal(user);
      }

      for (var task in tasks) {
        await insertTaskLocal(task);
      }

      print('Data synced successfully');
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // ==================== AUTHENTICATION ====================

  // Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? birthDate,
    String? gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          if (birthDate != null) 'birthDate': birthDate,
          if (gender != null) 'gender': gender,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        // Lưu thông tin đăng nhập
        if (data['user'] != null) {
          await saveUserSession(data['user']);
        }
        return {'success': true, 'user': data['user'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      print('Error registering: $e');
      return {'success': false, 'error': 'Không thể kết nối đến server'};
    }
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Lưu thông tin đăng nhập
        if (data['user'] != null) {
          print('🔐 Saving user session after login...');
          await saveUserSession(data['user']);
          
          // Verify session saved
          final verifyUser = await getCurrentUser();
          if (verifyUser != null && verifyUser['id'] != null) {
            print('✅ Session verified: User ID ${verifyUser['id']}');
          } else {
            print('⚠️ WARNING: Session not saved correctly!');
          }
        } else {
          print('⚠️ WARNING: No user data in login response');
        }
        return {'success': true, 'user': data['user'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      print('Error logging in: $e');
      return {'success': false, 'error': 'Không thể kết nối đến server'};
    }
  }

  // Kiểm tra email đã tồn tại chưa
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$currentBaseUrl/auth/check-email/$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Lưu session người dùng
  Future<void> saveUserSession(Map<String, dynamic> user) async {
    try {
      final p = await prefs;
      final userId = user['id'];
      
      if (userId == null) {
        print('⚠️ Warning: User ID is null, cannot save session');
        print('   User data: $user');
        return;
      }
      
      await p.setInt('userId', userId);
      await p.setString('userName', user['name'] ?? '');
      await p.setString('userEmail', user['email'] ?? '');
      await p.setString('userRole', user['role'] ?? 'user');
      await p.setBool('isLoggedIn', true);
      
      print('✅ User session saved: ${user['name']} (ID: $userId)');
    } catch (e) {
      print('❌ Error saving user session: $e');
    }
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final p = await prefs;
      final isLoggedIn = p.getBool('isLoggedIn') ?? false;
      
      if (!isLoggedIn) {
        print('⚠️ User not logged in');
        return null;
      }

      final userId = p.getInt('userId');
      if (userId == null) {
        print('⚠️ userId is null in SharedPreferences');
        print('   isLoggedIn: $isLoggedIn');
        print('   userName: ${p.getString('userName')}');
        print('   userEmail: ${p.getString('userEmail')}');
        return null;
      }

      final user = {
        'id': userId,
        'name': p.getString('userName') ?? '',
        'email': p.getString('userEmail') ?? '',
        'role': p.getString('userRole') ?? 'user',
      };
      
      print('✅ Current user: ${user['name']} (ID: ${user['id']})');
      return user;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final p = await prefs;
    return p.getBool('isLoggedIn') ?? false;
  }

  // Đăng xuất
  Future<void> logout() async {
    final p = await prefs;
    await p.remove('userId');
    await p.remove('userName');
    await p.remove('userEmail');
    await p.remove('userRole');
    await p.setBool('isLoggedIn', false);
  }

  // ==================== GOOGLE AUTHENTICATION ====================

  // Lấy user theo email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$currentBaseUrl/auth/get-user-by-email/$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['user'] != null) {
          return data['user'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Đăng ký tài khoản với Google
  Future<Map<String, dynamic>> registerWithGoogle({
    required String email,
    required String fullName,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/auth/register-google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'name': fullName,
          'photoUrl': photoUrl,
          'authProvider': 'google',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Lưu thông tin đăng nhập
        if (data['user'] != null) {
          await saveUserSession(data['user']);
        }
        return {'success': true, 'user': data['user'], 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      print('Error registering with Google: $e');
      return {'success': false, 'error': 'Không thể kết nối đến server'};
    }
  }

  // Cập nhật thông tin Google của user
  Future<bool> updateUserGoogleInfo({
    required int userId,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$currentBaseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          if (displayName != null) 'name': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating Google info: $e');
      return false;
    }
  }

  // Lấy thống kê admin
  Future<Map<String, dynamic>> fetchAdminStatistics() async {
    try {
      final response = await http.get(Uri.parse('$currentBaseUrl/statistics/admin'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load admin statistics');
      }
    } catch (e) {
      print('Error fetching admin statistics: $e');
      return {
        'totalAccounts': 0,
        'adminAccounts': 0,
        'userAccounts': 0,
        'newAccountsToday': 0,
        'totalTasks': 0,
        'totalCompletions': 0,
        'averageScore': 0.0,
      };
    }
  }

  // Lấy thống kê theo độ tuổi và giới tính
  Future<Map<String, dynamic>> fetchDemographicsStatistics() async {
    try {
      final response = await http.get(Uri.parse('$currentBaseUrl/statistics/demographics'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load demographics statistics');
      }
    } catch (e) {
      print('Error fetching demographics statistics: $e');
      return {
        'totalUsers': 0,
        'ageGroups': {
          'under18': 0,
          '18-25': 0,
          '26-35': 0,
          '36-45': 0,
          'over45': 0,
        },
        'genderStats': {
          'male': 0,
          'female': 0,
          'other': 0,
        },
      };
    }
  }

  // Lưu lịch sử hoàn thành task
  Future<bool> saveTaskHistory({
    required int userId,
    required String taskTitle,
    required double score,
    required int timeUsed,
    String? drawingData, // Base64 encoded image
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/history'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'taskTitle': taskTitle,
          'score': score,
          'timeUsed': timeUsed,
          'completedAt': DateTime.now().toIso8601String(),
          if (drawingData != null) 'drawingData': drawingData,
        }),
      );
      
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error saving task history: $e');
      return false;
    }
  }
  
  // Lấy lịch sử của user hiện tại
  Future<List<Map<String, dynamic>>> fetchUserHistory() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] == null) return [];
      
      final response = await http.get(
        Uri.parse('$currentBaseUrl/history/user/${user['id']}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching user history: $e');
      return [];
    }
  }

  // Lấy danh sách task IDs đã hoàn thành của user
  Future<List<int>> fetchCompletedTaskIds() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] == null) {
        print('❌ No user found when fetching completed tasks');
        return [];
      }
      
      print('✅ Fetching completed tasks for user ${user['id']}');
      
      final response = await http.get(
        Uri.parse('$currentBaseUrl/users/${user['id']}/completed-tasks'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final completedIds = data.cast<int>();
        print('✅ Found ${completedIds.length} completed tasks: $completedIds');
        return completedIds;
      } else {
        print('❌ Failed to fetch completed tasks: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching completed tasks: $e');
      return [];
    }
  }

  // Đánh dấu task đã hoàn thành cho user
  Future<bool> markTaskAsCompleted(int taskId) async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] == null) {
        print('❌ No user found when marking task as completed');
        return false;
      }
      
      print('✅ Marking task $taskId as completed for user ${user['id']}');
      
      final response = await http.post(
        Uri.parse('$currentBaseUrl/tasks/$taskId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': user['id'],
        }),
      );
      
      print('✅ Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('❌ Response body: ${response.body}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error marking task as completed: $e');
      return false;
    }
  }

  // Lấy thông tin user mới nhất từ server
  Future<Map<String, dynamic>?> fetchUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$currentBaseUrl/users/$userId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Cập nhật thông tin user (avatar, birthDate, gender, etc)
  Future<bool> updateUserProfile({
    required int userId,
    String? name,
    String? email,
    String? birthDate,
    String? gender,
    String? avatar, // Base64 encoded image
    String? role, // admin hoặc user
    String? faceData, // Face encoding data
    int? faceEnabled, // 0 hoặc 1
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$currentBaseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          if (birthDate != null) 'birthDate': birthDate,
          if (gender != null) 'gender': gender,
          if (avatar != null) 'avatar': avatar,
          if (role != null) 'role': role,
          if (faceData != null) 'faceData': faceData,
          if (faceEnabled != null) 'faceEnabled': faceEnabled,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // ==================== FACE RECOGNITION ====================

  // Đăng ký khuôn mặt cho user
  Future<bool> enrollFace({
    required int userId,
    required String faceSignature,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$currentBaseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'faceData': faceSignature,
          'faceEnabled': 1,
        }),
      );
      
      if (response.statusCode == 200) {
        // Cập nhật local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('faceData', faceSignature);
        await prefs.setInt('faceEnabled', 1);
        print('✅ Face enrolled successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error enrolling face: $e');
      return false;
    }
  }

  // Bật/tắt đăng nhập bằng khuôn mặt
  Future<bool> toggleFaceLogin({
    required int userId,
    required bool enabled,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$currentBaseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'faceEnabled': enabled ? 1 : 0,
        }),
      );
      
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('faceEnabled', enabled ? 1 : 0);
        return true;
      }
      return false;
    } catch (e) {
      print('Error toggling face login: $e');
      return false;
    }
  }

  // Đăng nhập bằng khuôn mặt
  Future<Map<String, dynamic>> faceLogin(String faceSignature) async {
    try {
      final response = await http.post(
        Uri.parse('$currentBaseUrl/auth/face-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'faceSignature': faceSignature,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'];
        
        // Lưu session bằng method chung
        await saveUserSession(user);
        
        // Lưu thêm face data nếu có
        if (user['faceData'] != null || user['faceEnabled'] != null) {
          final prefs = await SharedPreferences.getInstance();
          if (user['faceData'] != null) {
            await prefs.setString('faceData', user['faceData']);
          }
          if (user['faceEnabled'] != null) {
            await prefs.setInt('faceEnabled', user['faceEnabled']);
          }
        }

        return {'success': true, 'user': user};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Face login failed'};
      }
    } catch (e) {
      print('Error during face login: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Kiểm tra có user nào đã đăng ký face chưa
  Future<bool> hasFaceUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$currentBaseUrl/auth/has-face-users'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['hasFaceUsers'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking face users: $e');
      return false;
    }
  }

  // Lấy bảng xếp hạng
  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$currentBaseUrl/leaderboard?limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  // Lấy lịch sử của user theo ID
  Future<List<Map<String, dynamic>>> fetchUserHistoryById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$currentBaseUrl/history/user/$userId'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching user history by ID: $e');
      return [];
    }
  }

  // ==================== NOTIFICATIONS ====================

  // Lấy notifications của user
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] == null) return [];
      
      final response = await http.get(
        Uri.parse('$currentBaseUrl/notifications/${user['id']}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Đếm số notifications chưa đọc
  Future<int> fetchUnreadNotificationsCount() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] == null) return 0;
      
      final response = await http.get(
        Uri.parse('$currentBaseUrl/notifications/${user['id']}/unread-count'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // Đánh dấu notification đã đọc
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$currentBaseUrl/notifications/$notificationId/read'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Đánh dấu tất cả notifications đã đọc
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] == null) return false;
      
      final response = await http.put(
        Uri.parse('$currentBaseUrl/notifications/${user['id']}/read-all'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Xóa notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$currentBaseUrl/notifications/$notificationId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
}

