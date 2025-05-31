import 'package:flutter/material.dart';
import 'package:taskify/models/task.dart';

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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  late DateTime? _dueDate;
  late TimeOfDay? _dueTime;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task?.title ?? '';
    _descriptionController.text = widget.task?.description ?? '';
    _selectedCategory = widget.task?.category.isNotEmpty == true ? widget.task?.category : null;
    _dueDate = widget.task?.dueDate;
    _dueTime = _dueDate != null 
        ? TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute)
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.task == null ? Icons.add_task : Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.task == null ? 'Новая задача' : 'Редактировать задачу',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название задачи',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => 
                            value?.trim().isEmpty ?? true ? 'Введите название' : null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),
                      
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание (необязательно)',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),
                      
                      // Category section
                      Text(
                        'Категория',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Existing categories chips
                      if (widget.categories.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.categories.map((category) {
                                final isSelected = _selectedCategory == category;
                                return FilterChip(
                                  label: Text(
                                    category,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? category : null;
                                    });
                                  },
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                  checkmarkColor: Theme.of(context).colorScheme.primary,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // New category input
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Новая категория',
                                prefixIcon: Icon(Icons.label),
                                border: OutlineInputBorder(),
                                hintText: 'Введите название категории',
                              ),
                              textCapitalization: TextCapitalization.words,
                              onFieldSubmitted: (value) => _addNewCategory(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addNewCategory,
                            icon: const Icon(Icons.add),
                            tooltip: 'Добавить категорию',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Date and time section
                      Text(
                        'Срок выполнения',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: _dueDate != null 
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                              child: InkWell(
                                onTap: _selectDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: _dueDate != null 
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Дата',
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _dueDate == null 
                                                  ? 'Выберите дату' 
                                                  : '${_dueDate!.day.toString().padLeft(2, '0')}.${_dueDate!.month.toString().padLeft(2, '0')}.${_dueDate!.year}',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: _dueDate != null ? FontWeight.w500 : FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              color: _dueTime != null 
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : _dueDate == null 
                                      ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.5)
                                      : null,
                              child: InkWell(
                                onTap: _dueDate == null ? null : _selectTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: _dueTime != null 
                                            ? Theme.of(context).colorScheme.primary
                                            : _dueDate == null
                                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Время',
                                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: _dueDate == null
                                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _dueTime == null 
                                                  ? 'Выберите время' 
                                                  : '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: _dueTime != null ? FontWeight.w500 : FontWeight.normal,
                                                color: _dueDate == null
                                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                                                    : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_dueDate != null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _dueDate = null;
                                _dueTime = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Очистить срок'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveTask,
                      icon: const Icon(Icons.save),
                      label: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewCategory() {
    final newCategory = _categoryController.text.trim();
    if (newCategory.isNotEmpty) {
      setState(() {
        _selectedCategory = newCategory;
        _categoryController.clear();
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (time != null && mounted) {
      setState(() => _dueTime = time);
    }
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
          : _dueDate;

      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? '',
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