import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager/models/task.dart';

class TaskStorage {
  static const _tasksKey = 'tasks';

  /// Загружает список задач из локального хранилища
  static Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_tasksKey);
      
      if (tasksJson == null || tasksJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(tasksJson);
      return decoded.map((taskJson) {
        try {
          return Task.fromJson(taskJson as Map<String, dynamic>);
        } catch (e) {
          // Пропускаем поврежденные записи
          return null;
        }
      }).where((task) => task != null).cast<Task>().toList();
      
    } catch (e) {
      // В случае любой ошибки возвращаем пустой список
      return [];
    }
  }

  /// Сохраняет список задач в локальное хранилище
  static Future<bool> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = jsonEncode(
        tasks.map((task) => task.toJson()).toList()
      );
      
      return await prefs.setString(_tasksKey, tasksJson);
    } catch (e) {
      // Возвращаем false в случае ошибки сохранения
      return false;
    }
  }

  /// Очищает все сохраненные задачи
  static Future<bool> clearTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_tasksKey);
    } catch (e) {
      return false;
    }
  }

  /// Проверяет, есть ли сохраненные задачи
  static Future<bool> hasTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_tasksKey);
    } catch (e) {
      return false;
    }
  }

  /// Получает количество сохраненных задач без их загрузки
  static Future<int> getTasksCount() async {
    try {
      final tasks = await loadTasks();
      return tasks.length;
    } catch (e) {
      return 0;
    }
  }
}