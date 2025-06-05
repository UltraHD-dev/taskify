import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskify/screens/task_list_screen.dart';
import 'package:taskify/screens/sync_screen.dart';
import 'package:taskify/services/sync_service.dart';
import 'package:taskify/services/theme_service.dart';

class MainScreen extends StatefulWidget {
  final SyncService syncService;

  const MainScreen({required this.syncService, super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskify'),
        actions: [
          IconButton(
            icon: Icon(
              themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeService.setThemeMode(
                themeService.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
            },
            tooltip: themeService.isDarkMode ? 'Светлая тема' : 'Темная тема',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TaskListScreen(syncService: widget.syncService),
          SyncScreen(syncService: widget.syncService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync),
            label: 'Синхронизация',
          ),
        ],
      ),
    );
  }
}