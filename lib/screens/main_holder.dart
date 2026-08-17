// lib/main_holder.dart (或者你对应的导航容器文件名)
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dashboard_screen.dart';
import 'plant_profile_screen.dart';
import 'analytic_screen.dart';
import 'eco_impact_screen.dart';
import 'setting_screen.dart';
import 'hardware_status_manager.dart';

class MainHolder extends StatefulWidget {
  const MainHolder({Key? key}) : super(key: key);

  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> {
  int _currentIndex = 0;
  
  // 👑 核心：引入 PageController 来配合 KeepAlive 缓存所有页面的滚动位置
  late final PageController _pageController;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final List<Widget> _pages = const [
    DashboardScreen(),
    PlantProfileScreen(),
    AnalyticScreen(),
    EcoImpactScreen(),
    SettingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _initNotifications();

    // 整个 App 生命周期的全局唯一监控启动入口
    HardwareStatusManager.initNotifications(_notificationsPlugin);
    HardwareStatusManager.startMonitoring(() {
      if (mounted) setState(() {});
    });
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  @override
  void dispose() {
    _pageController.dispose();
    HardwareStatusManager.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/app_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            color: Colors.white.withOpacity(0.78),
          ),
          Scaffold(
            backgroundColor: Colors.transparent, 
            // 👑 核心修改：用 PageView 替换原本的 _pages[_currentIndex]，实现页面状态和滚动位置永久记忆
            body: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // 禁用左右滑动切换，只允许通过底部导航栏点击切换
              children: _pages,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                // 👑 使用 jumpToPage 配合子页面的 KeepAlive，切走再回来绝对不会回到顶部
                _pageController.jumpToPage(index);
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF497E66),
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
              items: [
                BottomNavigationBarItem(
                    icon: Image.asset('assets/my_ic_home.png', width: 22, height: 22, color: Colors.grey),
                    activeIcon: Image.asset('assets/my_ic_home.png', width: 22, height: 22, color: const Color(0xFF497E66)),
                    label: 'Home'
                ),
                BottomNavigationBarItem(
                    icon: Image.asset('assets/my_ic_profile.png', width: 22, height: 22, color: Colors.grey),
                    activeIcon: Image.asset('assets/my_ic_profile.png', width: 22, height: 22, color: const Color(0xFF497E66)),
                    label: 'Plant'
                ),
                BottomNavigationBarItem(
                    icon: Image.asset('assets/my_ic_analytic.png', width: 22, height: 22, color: Colors.grey),
                    activeIcon: Image.asset('assets/my_ic_analytic.png', width: 22, height: 22, color: const Color(0xFF497E66)),
                    label: 'Analytic'
                ),
                BottomNavigationBarItem(
                    icon: Image.asset('assets/my_ic_eco.png', width: 22, height: 22, color: Colors.grey),
                    activeIcon: Image.asset('assets/my_ic_eco.png', width: 22, height: 22, color: const Color(0xFF497E66)),
                    label: 'Eco Impact'
                ),
                BottomNavigationBarItem(
                    icon: Image.asset('assets/my_ic_settings.png', width: 22, height: 22, color: Colors.grey),
                    activeIcon: Image.asset('assets/my_ic_settings.png', width: 22, height: 22, color: const Color(0xFF497E66)),
                    label: 'Setting'
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}