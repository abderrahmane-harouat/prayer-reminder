import 'dart:ui' as ui;
import 'package:athan_app_v2/screens/home_screen.dart';
import 'package:athan_app_v2/screens/recitation_plan_screen.dart';
import 'package:athan_app_v2/screens/settings_screen.dart';
import 'package:athan_app_v2/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const RecitationPlanScreen(),
    const SettingsScreen(),
  ];

  final List<IconData> _iconList = [
    CupertinoIcons.house_fill,
    CupertinoIcons.book,
    CupertinoIcons.settings,
  ];

  final List<String> _labelList = ['الرئيسية', 'التلاوة', 'الإعدادات'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(top: 12, bottom: 8),
          child: CupertinoTabBar(
            height: 65,
            items: List.generate(
              _iconList.length,
              (index) => BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(_iconList[index], size: 26),
                ),
                label: _labelList[index],
              ),
            ),
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
      ),
    );
  }
}
