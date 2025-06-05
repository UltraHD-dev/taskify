import 'package:flutter/material.dart';
import 'package:taskify/models/task.dart';

class TaskDialog extends StatefulWidget {
  final Task? task;
  final Function(Task) onSave;
  final List<String> categories;
  final Function(List<String>) onCategoriesUpdated;

  const TaskDialog({
    super.key,
    this.task,
    required this.onSave,
    required this.categories,
    required this.onCategoriesUpdated,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _isCompleted = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedCategory = widget.task?.category ?? '';
    _selectedDueDate = widget.task?.dueDate;
    _selectedDueTime = widget.task?.dueDate != null
        ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
        : null;
    _isCompleted = widget.task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDueTime?.hour ?? 0,
          _selectedDueTime?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDueTime = picked;
        if (_selectedDueDate != null) {
          _selectedDueDate = DateTime(
            _selectedDueDate!.year,
            _selectedDueDate!.month,
            _selectedDueDate!.day,
            picked.hour,
            picked.minute,
          );
        } else {
          final now = DateTime.now();
          _selectedDueDate = DateTime(
            now.year,
            now.month,
            now.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  void _addNewCategory(String category) {
    if (category.isNotEmpty &&
        !widget.categories.contains(category)) {
      final updatedCategories = List<String>.from(widget.categories)..add(category);
      widget.onCategoriesUpdated(updatedCategories);
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      dueDate: _selectedDueDate,
      isCompleted: _isCompleted,
      createdAt: widget.task?.createdAt,
    );
    
    widget.onSave(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.task == null ? 'Новая задача' : 'Редактировать задачу',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите название задачи';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите описание задачи';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...widget.categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }),
                    const DropdownMenuItem(
                      value: 'new',
                      child: Text('+ Добавить новую категорию'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == 'new') {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final textController = TextEditingController();
                          return AlertDialog(
                            title: const Text('Новая категория'),
                            content: TextField(
                              controller: textController,
                              decoration: const InputDecoration(
                                labelText: 'Название категории',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _addNewCategory(textController.text);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Добавить'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      setState(() {
                        _selectedCategory = value ?? '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDueDate != null
                              ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                              : 'Выбрать дату',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectTime(context),
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          _selectedDueTime != null
                              ? '${_selectedDueTime!.hour}:${_selectedDueTime!.minute.toString().padLeft(2, '0')}'
                              : 'Выбрать время',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Завершено'),
                  value: _isCompleted,
                  onChanged: (bool value) {
                    setState(() {
                      _isCompleted = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveTask,
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}