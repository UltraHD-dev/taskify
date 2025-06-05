import 'package:flutter/material.dart';
import 'package:taskify/models/task.dart';
import 'package:taskify/screens/task_dialog.dart';
import 'package:taskify/services/task_storage.dart';
import 'package:taskify/services/sync_service.dart';

class TaskListScreen extends StatefulWidget {
  final SyncService syncService;

  const TaskListScreen({
    super.key,
    required this.syncService,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late TaskStorage _taskStorage;
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  List<String> _categories = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeTaskStorage();
  }

  Future<void> _initializeTaskStorage() async {
    try {
      _taskStorage = await TaskStorage.initialize();
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка инициализации: $e')),
        );
      }
    }
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskStorage.loadTasks();
      if (!mounted) return;

      setState(() {
        _allTasks = tasks;
        _updateCategories();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задач: $e')),
      );
    }
  }

  void _updateCategories() {
    final categories = _allTasks
        .map((task) => task.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    _categories = categories;
  }

  void _applyFilters() {
    _filteredTasks = _allTasks.where((task) {
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          task.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    _filteredTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return b.modifiedAt.compareTo(a.modifiedAt);
    });
  }

  Future<void> _addTask() async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskDialog(
        onSave: (task) => Navigator.of(context).pop(task),
        categories: _categories,
        onCategoriesUpdated: (categories) {
          setState(() => _categories = categories);
        },
      ),
    );

    if (result != null) {
      await _saveTask(result);
    }
  }

  Future<void> _editTask(Task task) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        onSave: (task) => Navigator.of(context).pop(task),
        categories: _categories,
        onCategoriesUpdated: (categories) {
          setState(() => _categories = categories);
        },
      ),
    );

    if (result != null) {
      await _saveTask(result);
    }
  }

  Future<void> _saveTask(Task task) async {
    try {
      await _taskStorage.saveTask(task);
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения задачи: $e')),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('Вы уверены, что хотите удалить задачу "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskStorage.deleteTask(task.id);
        await _loadTasks();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления задачи: $e')),
        );
      }
    }
  }

  Future<void> _toggleTaskComplete(Task task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
    );
    await _saveTask(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Поиск задач...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedCategory,
                        hint: const Text('Категория'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Все категории'),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredTasks.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty && _selectedCategory == null
                                ? 'Нет задач'
                                : 'Ничего не найдено',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return ListTile(
                              leading: Checkbox(
                                value: task.isCompleted,
                                onChanged: (_) => _toggleTaskComplete(task),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.description),
                                  if (task.category.isNotEmpty)
                                    Chip(
                                      label: Text(task.category),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                    ),
                                  if (task.dueDate != null)
                                    Text(
                                      'Срок: ${task.dueDate!.day}/'
                                      '${task.dueDate!.month}/'
                                      '${task.dueDate!.year} '
                                      '${task.dueDate!.hour}:'
                                      '${task.dueDate!.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: task.dueDate!.isBefore(DateTime.now())
                                            ? Colors.red
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editTask(task),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteTask(task),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}