import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyCFApp());
}

class MyCFApp extends StatelessWidget {
  const MyCFApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myCF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF497E66),
        scaffoldBackgroundColor: const Color(0xFFF4F7F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF497E66),
          primary: const Color(0xFF497E66),
        ),
      ),
      // 🌿 使用 FutureBuilder 确保 Firebase 稳稳初始化完毕后再渲染首屏
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // ❌ 如果初始化中途发生错误，在屏幕上打印出来提示
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Firebase Error: ${snapshot.error}')),
            );
          }

          // ✨ 握手成功！百分之百安全地进入你的专属 Welcome Back 登录大屏
          if (snapshot.connectionState == ConnectionState.done) {
            return const LoginScreen();
          }

          // ⏳ 在 Firebase 还没连接成功的零点几秒内，显示一个优雅的园艺绿转圈圈小动画
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF497E66)),
              ),
            ),
          );
        },
      ),
    );
  }
}