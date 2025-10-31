// Test Database Connection Script
// Chạy: dart test_database_connection.dart

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🔍 Testing Database Connection...\n');
  
  // Test 1: Kiểm tra backend có chạy không
  print('1️⃣ Testing Backend Server...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5000/api/users'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final List<dynamic> users = json.decode(responseBody);
      
      print('✅ Backend is running!');
      print('   - Status: ${response.statusCode}');
      print('   - Users count: ${users.length}');
      print('   - First user: ${users.isNotEmpty ? users[0]['name'] : 'N/A'}\n');
    } else {
      print('❌ Backend error: ${response.statusCode}\n');
    }
    client.close();
  } catch (e) {
    print('❌ Cannot connect to backend!');
    print('   Error: $e');
    print('   → Make sure backend is running: cd backend && node server_sqlite.js\n');
  }
  
  // Test 2: Kiểm tra các endpoints
  print('2️⃣ Testing API Endpoints...');
  await testEndpoint('GET', '/api/users', 'Get all users');
  await testEndpoint('GET', '/api/tasks', 'Get all tasks');
  await testEndpoint('GET', '/api/tasks/recent', 'Get recent tasks');
  await testEndpoint('GET', '/api/statistics', 'Get statistics');
  await testEndpoint('GET', '/api/leaderboard?limit=5', 'Get leaderboard');
  
  // Test 3: Kiểm tra database file
  print('\n3️⃣ Checking Database File...');
  final dbFile = File('backend/drawing_app.db');
  if (await dbFile.exists()) {
    final size = await dbFile.length();
    print('✅ Database file exists');
    print('   - Path: ${dbFile.path}');
    print('   - Size: ${(size / 1024).toStringAsFixed(2)} KB');
  } else {
    print('❌ Database file not found!');
    print('   Expected at: ${dbFile.path}');
  }
  
  print('\n✅ Test Complete!');
}

Future<void> testEndpoint(String method, String path, String description) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5000$path'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('   ✅ $description - OK');
    } else {
      print('   ❌ $description - Error ${response.statusCode}');
    }
    client.close();
  } catch (e) {
    print('   ❌ $description - Failed: $e');
  }
}

