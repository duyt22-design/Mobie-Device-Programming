import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';

class GoogleAuthService {
  // Singleton pattern
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  final DatabaseService _dbService = DatabaseService();

  /// Đăng nhập bằng Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Đăng xuất trước để luôn hiển thị popup chọn tài khoản
      await _googleSignIn.signOut();
      
      // Thực hiện đăng nhập
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Người dùng hủy đăng nhập
        return {
          'success': false,
          'error': 'Đăng nhập bị hủy',
        };
      }

      // Lấy thông tin chi tiết
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Lấy thông tin user
      final String email = googleUser.email;
      final String displayName = googleUser.displayName ?? '';
      final String? photoUrl = googleUser.photoUrl;
      
      // Kiểm tra xem user đã tồn tại trong database chưa
      final existingUser = await _dbService.getUserByEmail(email);
      
      if (existingUser != null) {
        // User đã tồn tại, đăng nhập
        // Cập nhật thông tin nếu cần
        await _dbService.updateUserGoogleInfo(
          userId: existingUser['id'],
          displayName: displayName,
          photoUrl: photoUrl,
        );
        
        // QUAN TRỌNG: Lưu session cho user đã tồn tại
        await _dbService.saveUserSession(existingUser);
        
        return {
          'success': true,
          'user': existingUser,
          'isNewUser': false,
        };
      } else {
        // User chưa tồn tại, tạo mới
        final result = await _dbService.registerWithGoogle(
          email: email,
          fullName: displayName,
          photoUrl: photoUrl,
        );
        
        if (result['success'] == true) {
          return {
            'success': true,
            'user': result['user'],
            'isNewUser': true,
          };
        } else {
          return {
            'success': false,
            'error': result['error'] ?? 'Không thể tạo tài khoản',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi đăng nhập: ${e.toString()}',
      };
    }
  }

  /// Đăng xuất Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Lỗi đăng xuất Google: $e');
    }
  }

  /// Kiểm tra trạng thái đăng nhập
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return await _googleSignIn.signInSilently();
  }

  /// Ngắt kết nối tài khoản Google
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      print('Lỗi ngắt kết nối Google: $e');
    }
  }
}

