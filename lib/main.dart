import 'dart:io';
import 'package:flutter/material.dart';
import 'package:taskify/screens/task_list_screen.dart';
import 'package:taskify/screens/file_manager_screen.dart';
import 'package:taskify/screens/settings_screen.dart';
import 'package:taskify/theme/app_theme.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация window_manager для десктопных платформ
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }
  
  runApp(const TaskifyApp());
}

class TaskifyApp extends StatefulWidget {
  const TaskifyApp({super.key});

  @override
  State<TaskifyApp> createState() => _TaskifyAppState();
}

class _TaskifyAppState extends State<TaskifyApp> {
  int _selectedIndex = 0; 

  static const List<Widget> _screens = <Widget>[
    TaskListScreen(),
    FileManagerScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskify - Твой Менеджер задач',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: IndexedStack( 
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box),
              label: 'Задачи', 
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: 'Файлы', 
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Настройки',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
