import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../models/file.dart';

class TaskCreateDialog extends StatefulWidget {
  final Task? task;
  final List<AppFile> availableFiles;

  const TaskCreateDialog({
    super.key,
    this.task,
    required this.availableFiles,
  });

  @override
  State<TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends State<TaskCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  
  DateTime? _dueDate;
  Priority _priority = Priority.medium;
  String _category = '';
  List<String> _tags = [];
  Set<String> _selectedFileIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _priority = widget.task!.priority;
      _category = widget.task!.category;
      _tags = List.from(widget.task!.tags);
      _selectedFileIds = Set.from(widget.task!.attachedFileIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildBasicInfo(),
                  const SizedBox(height: 16),
                  _buildDateAndPriority(),
                  const SizedBox(height: 16),
                  _buildTags(),
                  const SizedBox(height: 16),
                  _buildAttachments(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ].animate(interval: 50.ms).fadeIn().slideX(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          widget.task != null ? Icons.edit_note : Icons.add_task,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          widget.task != null ? 'Редактировать задачу' : 'Новая задача',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Название',
            hintText: 'Введите название задачи',
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Пожалуйста, введите название';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Описание',
            hintText: 'Опишите задачу подробнее',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndPriority() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.event,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              _dueDate != null 
                  ? 'Дата: ${_formatDate(_dueDate!)}'
                  : 'Выберите дату',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: _selectDate,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<Priority>(
            value: _priority,
            decoration: const InputDecoration(
              labelText: 'Приоритет',
              prefixIcon: Icon(Icons.flag),
            ),
            items: Priority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Icon(priority.icon, color: priority.color, size: 20),
                    const SizedBox(width: 8),
                    Text(priority.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _priority = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'Теги',
                  hintText: 'Добавьте теги',
                  prefixIcon: Icon(Icons.tag),
                ),
                onFieldSubmitted: _addTag,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_tagController.text),
            ),
          ],
        ),
        if (_tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Прикрепленные файлы',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (widget.availableFiles.isEmpty)
          const Text('Нет доступных файлов')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableFiles.map((file) {
              final isSelected = _selectedFileIds.contains(file.id);
              return FilterChip(
                selected: isSelected,
                label: Text(file.name),
                avatar: Icon(
                  _getFileIcon(file.fileType),
                  size: 18,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFileIds.add(file.id);
                    } else {
                      _selectedFileIds.remove(file.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _saveTask,
          icon: const Icon(Icons.save),
          label: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = (widget.task ?? Task(title: '')).copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate,
        priority: _priority,
        category: _category,
        tags: _tags,
        attachedFileIds: _selectedFileIds.toList(),
      );
      
      Navigator.of(context).pop(task);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _addTag(String tag) {
    final newTag = tag.trim();
    if (newTag.isNotEmpty && !_tags.contains(newTag)) {
      setState(() {
        _tags.add(newTag);
        _tagController.clear();
      });
    }
  }

  IconData _getFileIcon(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image;
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.document:
        return Icons.article;
      case FileType.text:
        return Icons.text_snippet;
      case FileType.audio:
        return Icons.audio_file;
      case FileType.video:
        return Icons.video_file;
      case FileType.archive:
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}'
        '.${date.month.toString().padLeft(2, '0')}'
        '.${date.year}';
  }
}