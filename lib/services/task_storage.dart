import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskify/models/task.dart';

class TaskStorage {
  static const String _tasksKey = 'tasks';
  static const String _deletedTasksKey = 'deleted_tasks';
  final SharedPreferences _prefs;

  TaskStorage(this._prefs);

  static Future<TaskStorage> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return TaskStorage(prefs);
  }

  Future<List<Task>> loadTasks() async {
    final tasksJson = _prefs.getString(_tasksKey);
    if (tasksJson == null) return [];

    final List<dynamic> tasksList = jsonDecode(tasksJson);
    return tasksList.map((json) => Task.fromJson(json)).toList();
  }

  Future<void> saveTask(Task task) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }

    await _saveTasks(tasks);
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await loadTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks(tasks);
    
    final deletedTaskIds = await getDeletedTaskIds();
    deletedTaskIds.add(taskId);
    await _saveDeletedTaskIds(deletedTaskIds);
  }

  Future<List<String>> getDeletedTaskIds() async {
    final deletedJson = _prefs.getString(_deletedTasksKey);
    if (deletedJson == null) return [];

    final List<dynamic> deletedList = jsonDecode(deletedJson);
    return deletedList.map((id) => id.toString()).toList();
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    final tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await _prefs.setString(_tasksKey, tasksJson);
  }

  Future<void> _saveDeletedTaskIds(List<String> deletedIds) async {
    final deletedJson = jsonEncode(deletedIds);
    await _prefs.setString(_deletedTasksKey, deletedJson);
  }
}