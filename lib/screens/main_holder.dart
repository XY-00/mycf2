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
    return Scaffold(
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
          BottomNavigationBarItem(
              icon: Image.asset('assets/my_ic_profile.png', width: 24, height: 24, color: Colors.grey),
              activeIcon: Image.asset('assets/my_ic_profile.png', width: 24, height: 24, color: const Color(0xFF497E66)),
              label: 'Profile'
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
    );
  }
}