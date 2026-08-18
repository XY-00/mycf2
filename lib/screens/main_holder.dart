// lib/main_holder.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  
  // 👑 配合 KeepAlive 的 PageController
  late final PageController _pageController;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _globalSystemControlSubscription;
  bool _hasTriggeredWaterAlert = false;

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
    _initGlobalWaterRealtime(); // 👑 启动主容器的全局水箱监听

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

  // 👑 核心：在主容器 24 小时全局监听水箱，不管在哪个页面、无论首页有没有被缓存，都能立刻检测并报警+刷新
  void _initGlobalWaterRealtime() {
    _globalSystemControlSubscription = Supabase.instance.client
        .channel('public:main_holder_system_control_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'system_control',
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) {
              var rawNormal = data['is_water_normal'];
              bool isNormal = true;
              if (rawNormal is bool) {
                isNormal = rawNormal;
              } else if (rawNormal is String) {
                isNormal = rawNormal.toLowerCase() == 'true';
              } else if (rawNormal is num) {
                isNormal = rawNormal != 0;
              }

              // 如果水箱空了（false），且还没触发过警报，立刻播放声音 + 弹窗横幅
              if (!isNormal && !_hasTriggeredWaterAlert) {
                _hasTriggeredWaterAlert = true;
                HardwareStatusManager.triggerTankEmptyAlert();
              } else if (isNormal) {
                _hasTriggeredWaterAlert = false;
              }

              // 强制刷新主容器，带动所有子页面状态同步更新
              if (mounted) setState(() {});
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _globalSystemControlSubscription?.unsubscribe();
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
            body: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // 禁用滑动切换，保留滚动记忆
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