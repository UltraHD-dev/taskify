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
  late TextEditingController _categoryController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isCompleted = false;
  bool _showCategoryInput = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _categoryController = TextEditingController();
    _selectedDate = widget.task?.dueDate;
    _selectedTime = widget.task?.dueDate != null
        ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
        : null;
    _isCompleted = widget.task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название задачи')),
      );
      return;
    }

    DateTime? dueDate;
    if (_selectedDate != null) {
      dueDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime?.hour ?? 0,
        _selectedTime?.minute ?? 0,
      );
    }

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      category: _categoryController.text,
      dueDate: dueDate,
      isCompleted: _isCompleted,
      createdAt: widget.task?.createdAt,
      modifiedAt: widget.task?.modifiedAt,
    );

    widget.onSave(task);
    Navigator.of(context).pop();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate);
      _selectTime();
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null && mounted) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.task == null ? 'Новая задача' : 'Редактировать задачу',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (!_showCategoryInput) ...[
              DropdownButtonFormField<String>(
                value: widget.task?.category.isEmpty ?? true ? null : widget.task?.category,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  ...widget.categories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      )),
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Новая категория'),
                  ),
                ],
                onChanged: (value) {
                  if (value == '') {
                    setState(() => _showCategoryInput = true);
                  } else {
                    _categoryController.text = value ?? '';
                  }
                },
              ),
            ] else ...[
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Новая категория',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showCategoryInput = false),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Выбрать дату'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectedDate = null;
                      _selectedTime = null;
                    }),
                  ),
                ],
              ],
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTime == null
                      ? 'Выбрать время'
                      : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isCompleted,
              onChanged: (value) => setState(() => _isCompleted = value!),
              title: const Text('Завершено'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _handleSave,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}