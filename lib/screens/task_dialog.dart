import 'package:flutter/material.dart';
import 'package:task_manager/models/task.dart';

class TaskDialog extends StatefulWidget {
  final Task? task;
  final List<String> categories;
  final Function(Task) onSave;

  const TaskDialog({
    super.key,
    this.task,
    required this.categories,
    required this.onSave,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  late String _title;
  late String _description;
  late String _category;
  late DateTime? _dueDate;
  late TimeOfDay? _dueTime;

  @override
  void initState() {
    super.initState();
    _title = widget.task?.title ?? '';
    _description = widget.task?.description ?? '';
    _category = widget.task?.category ?? '';
    _dueDate = widget.task?.dueDate;
    _dueTime = _dueDate != null 
        ? TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute)
        : null;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Новая задача' : 'Редактировать задачу'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (value) => 
                    value?.isEmpty ?? true ? 'Введите название' : null,
                onSaved: (value) => _title = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 3,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      onSaved: (value) => _category = value ?? '',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_categoryController.text.isNotEmpty) {
                        setState(() {
                          _category = _categoryController.text;
                          _categoryController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _dueDate = date);
                        }
                      },
                      child: Text(
                        _dueDate == null 
                            ? 'Выберите дату' 
                            : '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}',
                      ),
                    ),
                  ),
                  if (_dueDate != null)
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _dueTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => _dueTime = time);
                          }
                        },
                        child: Text(
                          _dueTime == null 
                              ? 'Выберите время' 
                              : '${_dueTime!.hour}:${_dueTime!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      final dueDateTime = _dueDate != null && _dueTime != null
          ? DateTime(
              _dueDate!.year,
              _dueDate!.month,
              _dueDate!.day,
              _dueTime!.hour,
              _dueTime!.minute,
            )
          : null;

      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        description: _description,
        category: _category,
        isCompleted: widget.task?.isCompleted ?? false,
        dueDate: dueDateTime,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(task);
      Navigator.pop(context);
    }
  }
}