import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      // 👑 强制全局只走浅色模式，彻底屏蔽手机系统的深色模式
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF497E66),
        scaffoldBackgroundColor: const Color(0xFFF4F7F2),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF497E66),
          primary: const Color(0xFF497E66),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF497E66),
        scaffoldBackgroundColor: const Color(0xFFF4F7F2),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF497E66),
          primary: const Color(0xFF497E66),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}