import 'package:flutter/material.dart';
import 'package:taskify/models/task.dart';

class TaskDialog extends StatefulWidget {
  final Task? task;
  final List<String> categories;
  final Function(Task) onSave;
  final Function(List<String>) onCategoriesUpdated;

  const TaskDialog({
    super.key,
    this.task,
    required this.categories,
    required this.onSave,
    required this.onCategoriesUpdated,
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
  late List<String> _workingCategories;

  // Стандартные категории
  static const List<String> _defaultCategories = [
    'Не срочно',
    'Срочно',
    'Важно',
  ];

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
    
    // Создаем рабочую копию категорий
    _workingCategories = List<String>.from(widget.categories);
    
    // Добавляем стандартные категории, если их нет
    for (final defaultCategory in _defaultCategories) {
      if (!_workingCategories.contains(defaultCategory)) {
        _workingCategories.insert(0, defaultCategory);
      }
    }
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Категория',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showCategoryManagementDialog,
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('Управление'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Existing categories chips
                      if (_workingCategories.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _workingCategories.map((category) {
                                final isSelected = _selectedCategory == category;
                                final isDefault = _defaultCategories.contains(category);
                                return FilterChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isDefault)
                                        const Icon(Icons.star, size: 16),
                                      if (isDefault)
                                        const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          category,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? category : null;
                                    });
                                  },
                                  backgroundColor: isDefault 
                                      ? Theme.of(context).colorScheme.secondaryContainer
                                      : Theme.of(context).colorScheme.surface,
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
    if (newCategory.isNotEmpty && !_workingCategories.contains(newCategory)) {
      setState(() {
        _workingCategories.add(newCategory);
        _selectedCategory = newCategory;
        _categoryController.clear();
      });
    } else if (_workingCategories.contains(newCategory)) {
      setState(() {
        _selectedCategory = newCategory;
        _categoryController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Категория уже существует')),
      );
    }
  }

  void _showCategoryManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Управление категориями'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Нажмите на категорию для удаления:'),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _workingCategories.map((category) {
                        final isDefault = _defaultCategories.contains(category);
                        return ActionChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isDefault) ...[
                                const Icon(Icons.star, size: 16),
                                const SizedBox(width: 4),
                              ],
                              Text(category),
                              if (!isDefault) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.close, size: 16),
                              ],
                            ],
                          ),
                          onPressed: isDefault ? null : () {
                            setDialogState(() {
                              _workingCategories.remove(category);
                              if (_selectedCategory == category) {
                                _selectedCategory = null;
                              }
                            });
                            setState(() {});
                          },
                          backgroundColor: isDefault 
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.surface,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Стандартные категории нельзя удалить', 
                     style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Готово'),
            ),
          ],
        ),
      ),
    );
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

      // Обновляем категории в родительском компоненте
      widget.onCategoriesUpdated(_workingCategories);
      widget.onSave(task);
      Navigator.pop(context);
    }
  }
}