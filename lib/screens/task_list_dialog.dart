import 'package:flutter/material.dart';
import 'package:taskify/models/task.dart';
import 'package:taskify/screens/task_dialog.dart';

class TaskListDialog extends StatefulWidget {
  final List<Task> tasks;
  final Function(List<Task>) onTasksUpdated;
  final List<String> categories;
  final Function(List<String>) onCategoriesUpdated;

  const TaskListDialog({
    super.key,
    required this.tasks,
    required this.onTasksUpdated,
    required this.categories,
    required this.onCategoriesUpdated,
  });

  @override
  State<TaskListDialog> createState() => _TaskListDialogState();
}

class _TaskListDialogState extends State<TaskListDialog> {
  List<Task> _tasks = [];
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks);
  }

  List<Task> _getFilteredTasks() {
    return _tasks.where((task) {
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          task.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _addNewTask() {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        onSave: (task) {
          setState(() {
            _tasks.add(task);
          });
          widget.onTasksUpdated(_tasks);
        },
        categories: widget.categories,
        onCategoriesUpdated: widget.onCategoriesUpdated,
      ),
    );
  }

  void _editTask(int index, Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        task: task,
        onSave: (updatedTask) {
          setState(() {
            _tasks[index] = updatedTask;
          });
          widget.onTasksUpdated(_tasks);
        },
        categories: widget.categories,
        onCategoriesUpdated: widget.onCategoriesUpdated,
      ),
    );
  }

  void _deleteTask(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: const Text('Вы уверены, что хотите удалить эту задачу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tasks.removeAt(index);
              });
              widget.onTasksUpdated(_tasks);
              Navigator.pop(context);
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        isCompleted: !task.isCompleted,
      );
    });
    widget.onTasksUpdated(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            AppBar(
              title: const Text('Список задач'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addNewTask,
                ),
              ],
            ),
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
                      ...widget.categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (_) => _toggleTaskCompletion(
                        _tasks.indexWhere((t) => t.id == task.id),
                      ),
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
                            'Срок: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year} '
                            '${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
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
                          onPressed: () => _editTask(
                            _tasks.indexWhere((t) => t.id == task.id),
                            task,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTask(
                            _tasks.indexWhere((t) => t.id == task.id),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}