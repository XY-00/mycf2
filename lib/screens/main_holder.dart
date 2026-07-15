import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'plant_profile_screen.dart';
import 'analytic_screen.dart';
import 'eco_impact_screen.dart';
import 'setting_screen.dart';

class MainHolder extends StatefulWidget {
  const MainHolder({Key? key}) : super(key: key);

  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const DashboardScreen(),
    const PlantProfileScreen(),
    const AnalyticScreen(),
    const EcoImpactScreen(),
    const SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // 👑 命令 1：在外层套一个全物理视窗固定的 Container 墙纸，让全部 Page 的背景与 login/register 100% 联动一体！
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/app_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // 👑 保持透明，确保每个子页面的精美底层壁纸完美穿透显示
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF497E66),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          items: [
            BottomNavigationBarItem(
                icon: Image.asset('assets/my_ic_home.png', width: 24, height: 24, color: Colors.grey),
                activeIcon: Image.asset('assets/my_ic_home.png', width: 24, height: 24, color: const Color(0xFF497E66)),
                label: 'Home'
            ),
            // 👑 命令 2：将原本的 'Profile' 标签正式换成要求的 'Plant' 标签，其余自制资产图标配置完美不动
            BottomNavigationBarItem(
                icon: Image.asset('assets/my_ic_profile.png', width: 24, height: 24, color: Colors.grey),
                activeIcon: Image.asset('assets/my_ic_profile.png', width: 24, height: 24, color: const Color(0xFF497E66)),
                label: 'Plant'
            ),
            BottomNavigationBarItem(
                icon: Image.asset('assets/my_ic_analytic.png', width: 24, height: 24, color: Colors.grey),
                activeIcon: Image.asset('assets/my_ic_analytic.png', width: 24, height: 24, color: const Color(0xFF497E66)),
                label: 'Analytic'
            ),
            BottomNavigationBarItem(
                icon: Image.asset('assets/my_ic_eco.png', width: 24, height: 24, color: Colors.grey),
                activeIcon: Image.asset('assets/my_ic_eco.png', width: 24, height: 24, color: const Color(0xFF497E66)),
                label: 'Eco Impact'
            ),
            BottomNavigationBarItem(
                icon: Image.asset('assets/my_ic_settings.png', width: 24, height: 24, color: Colors.grey),
                activeIcon: Image.asset('assets/my_ic_settings.png', width: 24, height: 24, color: const Color(0xFF497E66)),
                label: 'Setting'
            ),
          ],
        ),
      ),
    );
  }
}