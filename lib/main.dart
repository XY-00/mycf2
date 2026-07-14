import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👑 第 1 点：完全移除了原本的 Firebase 初始化 FutureBuilder，直接通过官方 SDK 初始化 Supabase
  // 请将这里的 URL 和 Anon Key 替换为你自己在 Supabase 后台获取到的真实凭证
  await Supabase.initialize(
    url: 'https://yrvalkaylotehefojwqy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlydmFsa2F5bG90ZWhlZm9qd3F5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3NDkyMTgsImV4cCI6MjA5OTMyNTIxOH0.BsC1vomzUNlEPWtiYSilBmj1AKsU_B9CqET4jzbn2_I',
  );

  runApp(const MyCFApp());
}

class MyCFApp extends StatelessWidget {
  const MyCFApp({super.key});

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
      home: const LoginScreen(),
    );
  }
}