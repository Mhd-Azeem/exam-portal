import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/theme/app_theme.dart';
import 'screens/overview_screen.dart';
import 'screens/students_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/marks_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/leaderboard_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
    _NavItem(Icons.people_outline, Icons.people, 'Students'),
    _NavItem(Icons.book_outlined, Icons.book, 'Subjects'),
    _NavItem(Icons.edit_note_outlined, Icons.edit_note, 'Marks'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Attendance'),
    _NavItem(Icons.folder_open_outlined, Icons.folder, 'Resources'),
    _NavItem(Icons.leaderboard_outlined, Icons.leaderboard, 'Leaderboard'),
  ];

  static const _screens = [
    OverviewScreen(),
    StudentsScreen(),
    SubjectsScreen(),
    MarksScreen(),
    AttendanceScreen(),
    ResourcesScreen(),
    AdminLeaderboardScreen(),
  ];

  static const _fabScreens = {4: null}; // Attendance uses save in screen
  // Screens that show a FAB for adding items
  static final Map<int, Widget Function(BuildContext)> _fabBuilders = {
    1: (ctx) => FloatingActionButton(
          heroTag: 'fab_student',
          onPressed: () {
            final state = ctx.findAncestorStateOfType<_AdminShellState>();
            state?._showStudentForm(ctx);
          },
          child: const Icon(Icons.person_add_outlined),
        ),
    2: (ctx) => FloatingActionButton(
          heroTag: 'fab_subject',
          onPressed: () {
            final state = ctx.findAncestorStateOfType<_AdminShellState>();
            state?._showSubjectForm(ctx);
          },
          child: const Icon(Icons.add),
        ),
    5: (ctx) => FloatingActionButton(
          heroTag: 'fab_resource',
          onPressed: () => showDialog(
              context: ctx,
              builder: (_) => const ResourceUploadDialog()),
          child: const Icon(Icons.upload_outlined),
        ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                color: AppColors.primary,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 28),
                    ),
                    SizedBox(height: 12),
                    Text('Admin Panel',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text('Team Maestro',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _navItems.length,
                  itemBuilder: (_, i) {
                    final item = _navItems[i];
                    final selected = _selectedIndex == i;
                    return ListTile(
                      leading: Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: selected,
                      selectedTileColor:
                          AppColors.primary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      onTap: () {
                        setState(() => _selectedIndex = i);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.arrow_back,
                    color: AppColors.textSecondary, size: 20),
                title: const Text('Back to Home'),
                onTap: () {
                  Navigator.of(context).pop(); // close drawer
                  Navigator.of(context).pop(); // go back to landing
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: _fabBuilders.containsKey(_selectedIndex)
          ? Builder(
              builder: (ctx) =>
                  _fabBuilders[_selectedIndex]!(ctx))
          : null,
    );
  }

  void _showStudentForm(BuildContext context) {
    // Delegate to StudentsScreen's form — trigger via a shared method
    // For simplicity, navigate to Students tab first
    setState(() => _selectedIndex = 1);
  }

  void _showSubjectForm(BuildContext context) {
    setState(() => _selectedIndex = 2);
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
