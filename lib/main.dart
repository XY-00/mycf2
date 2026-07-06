import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyCFApp());
}

class MyCFApp extends StatelessWidget {
  // ✨ 修复黄包车警告：改成了最新的 super.key 现代语法
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
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Firebase Connecting Info: ${snapshot.error}',
                    // ✨ 核心修复：手抖错字已改正为正确的 TextAlign.center
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return const LoginScreen();
          }

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