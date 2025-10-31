import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  
  const SplashScreen({super.key, this.onSettingsChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Đợi 2 giây để hiển thị splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Kiểm tra đã đăng nhập chưa
    final isLoggedIn = await _dbService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Đã đăng nhập -> vào app
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // Chưa đăng nhập -> màn hình login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.purple.shade400,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.palette,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),

              // App name
              const Text(
                'Drawing App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ứng dụng vẽ & tô màu',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 50),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

