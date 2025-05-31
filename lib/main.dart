import 'dart:io';
import 'package:flutter/material.dart';
import 'package:taskify/screens/task_list_screen.dart';
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

class TaskifyApp extends StatelessWidget {
  const TaskifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskify - Менеджер задач',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const TaskListScreen(),
    );
  }
}