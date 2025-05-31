import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskify/models/task.dart';
import 'package:taskify/screens/task_dialog.dart';
import 'package:taskify/widgets/qr_scanner.dart';
import 'package:taskify/widgets/task_tile.dart' as tile;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:window_manager/window_manager.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with WindowListener {
  List<Task> tasks = [];
  bool showCompleted = true;
  List<String> categories = [];
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
      _initWindow();
    }

    tz.initializeTimeZones();
    _initNotifications();
    _loadTasks().then((_) => _checkExpiredTasks());
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _initWindow() async {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 700),
      minimumSize: Size(350, 600),
      maximumSize: Size(500, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('tasks');
    if (tasksJson == null) return;

    try {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      if (mounted) {
        setState(() {
          tasks = decoded.map((t) => Task.fromJson(t)).toList();
          categories = tasks
              .map((task) => task.category)
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList();
        });
        _rescheduleAllNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки задач')),
        );
      }
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'tasks', jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  Future<void> _rescheduleAllNotifications() async {
    await notificationsPlugin.cancelAll();
    for (final task in tasks) {
      await _scheduleNotification(task);
    }
  }

  Future<void> _scheduleNotification(Task task) async {
    if (task.dueDate == null || task.isCompleted) return;

    await notificationsPlugin.zonedSchedule(
      task.id.hashCode,
      'Задача истекает: ${task.title}',
      task.description.isNotEmpty ? task.description : 'Без описания',
      tz.TZDateTime.from(task.dueDate!, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Уведомления о задачах',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Удален параметр uiLocalNotificationDateInterpretation
    );
  }

  Future<void> _checkExpiredTasks() async {
    final now = DateTime.now();
    final expiredTasks = tasks.where((task) =>
        task.dueDate != null &&
        task.dueDate!.isBefore(now) &&
        !task.isCompleted);

    if (expiredTasks.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Просроченные задачи'),
          content: SingleChildScrollView(
            child: Column(
              children: expiredTasks
                  .map((task) => ListTile(
                        title: Text(task.title),
                        subtitle:
                            Text('Просрочено: ${_formatDate(task.dueDate!)}'),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showTaskDialog({Task? task}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        categories: categories,
        onSave: (newTask) async {
          if (!mounted) return;

          setState(() {
            if (task == null) {
              tasks.add(newTask);
              if (!categories.contains(newTask.category)) {
                categories.add(newTask.category);
              }
            } else {
              final index = tasks.indexWhere((t) => t.id == newTask.id);
              if (index != -1) tasks[index] = newTask;
            }
          });
          await _saveTasks();
          await _scheduleNotification(newTask);
        },
      ),
    );
    await _loadTasks();
  }

  Future<void> _toggleTaskComplete(String taskId) async {
    if (!mounted) return;

    setState(() {
      final task = tasks.firstWhere((t) => t.id == taskId);
      task.isCompleted = !task.isCompleted;
      task.updatedAt = DateTime.now();
    });
    await _saveTasks();
    await notificationsPlugin.cancel(taskId.hashCode);
  }

  Future<void> _deleteTask(String taskId) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить задачу?'),
            content: const Text('Задача будет удалена навсегда.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldDelete && mounted) {
      setState(() => tasks.removeWhere((t) => t.id == taskId));
      await _saveTasks();
      await notificationsPlugin.cancel(taskId.hashCode);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = showCompleted
        ? tasks
        : tasks.where((task) => !task.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Менеджер задач'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QrScanner(tasks: tasks),
                ),
              );
              if (result != null && mounted) {
                setState(() => tasks = result);
                await _saveTasks();
                _rescheduleAllNotifications();
              }
            },
          ),
          IconButton(
            icon: Icon(showCompleted ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => showCompleted = !showCompleted),
          ),
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
            IconButton(
              icon: const Icon(Icons.minimize),
              onPressed: () async => await windowManager.minimize(),
            ),
            IconButton(
              icon: const Icon(Icons.crop_square),
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
          ],
        ],
      ),
      body: filteredTasks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) => tile.TaskTile(
                task: filteredTasks[index],
                onToggleComplete: () =>
                    _toggleTaskComplete(filteredTasks[index].id),
                onEdit: () => _showTaskDialog(task: filteredTasks[index]),
                onDelete: () => _deleteTask(filteredTasks[index].id),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Нет задач',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
