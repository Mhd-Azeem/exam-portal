import 'package:flutter/material.dart';
import '../shared/theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/marks_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  static const _tabs = [
    DashboardScreen(),
    MarksScreen(),
    AttendanceScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  static const _labels = [
    'Dashboard', 'Marks', 'Attendance', 'Leaderboard', 'Profile',
  ];

  static const _icons = [
    Icons.grid_view_outlined,
    Icons.bar_chart_outlined,
    Icons.calendar_today_outlined,
    Icons.emoji_events_outlined,
    Icons.person_outline,
  ];

  static const _selectedIcons = [
    Icons.grid_view,
    Icons.bar_chart,
    Icons.calendar_today,
    Icons.emoji_events,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_labels[_currentIndex]),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.school, color: AppColors.primary),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: List.generate(
          _tabs.length,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_selectedIcons[i], color: AppColors.primary),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}
