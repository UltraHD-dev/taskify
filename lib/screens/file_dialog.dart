import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:taskify/models/file.dart';

class FileDialog extends StatefulWidget {
  final AppFile? file;
  final List<String> categories;
  final Function(List<String>) onCategoriesUpdated;
  final Function(AppFile) onSave;

  const FileDialog({
    super.key,
    this.file,
    required this.categories,
    required this.onCategoriesUpdated,
    required this.onSave,
  });

  @override
  State<FileDialog> createState() => _FileDialogState();
}

class _FileDialogState extends State<FileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _newCategoryController;
  late TextEditingController _newTagController;

  String? _selectedCategory;
  List<String> _tags = [];
  List<String> _availableCategories = [];
  bool _isCreatingNewCategory = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.file?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.file?.description ?? '');
    _newCategoryController = TextEditingController();
    _newTagController = TextEditingController();

    _selectedCategory =
        widget.file?.category.isNotEmpty == true ? widget.file!.category : null;
    _tags = List<String>.from(widget.file?.tags ?? []);
    _availableCategories = List<String>.from(widget.categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final newTag = _newTagController.text.trim();
    if (newTag.isNotEmpty && !_tags.contains(newTag)) {
      setState(() {
        _tags.add(newTag);
      });
      _newTagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addNewCategory() {
    final newCategory = _newCategoryController.text.trim();
    if (newCategory.isNotEmpty && !_availableCategories.contains(newCategory)) {
      setState(() {
        _availableCategories.add(newCategory);
        _selectedCategory = newCategory;
        _isCreatingNewCategory = false;
      });
      widget.onCategoriesUpdated(_availableCategories);
      _newCategoryController.clear();
    }
  }

  void _saveFile() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя файла не может быть пустым')),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите категорию')),
      );
      return;
    }

    final updatedFile = widget.file?.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
          category: _selectedCategory!,
          tags: _tags,
          updatedAt: DateTime.now(),
        ) ??
        AppFile(
          name: _nameController.text,
          extension: '',
          size: 0,
          data: Uint8List(0),
          mimeType: '',
          description: _descriptionController.text,
          category: _selectedCategory!,
          tags: _tags,
        );

    widget.onSave(updatedFile);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.file == null ? 'Добавить файл' : 'Редактировать файл'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя файла',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildTagInputSection(),
            if (widget.file != null) ...[
              const SizedBox(height: 16),
              _buildFileInfo(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveFile,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Категория',
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixIcon: _isCreatingNewCategory
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isCreatingNewCategory = false;
                        _newCategoryController.clear();
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _isCreatingNewCategory = true;
                        _selectedCategory = null;
                      });
                    },
                  ),
          ),
          isEmpty: _selectedCategory == null,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: const Text('Выберите категорию'),
              isExpanded: true,
              onChanged: _isCreatingNewCategory
                  ? null
                  : (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
              items: _availableCategories.map<DropdownMenuItem<String>>(
                (String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                },
              ).toList(),
            ),
          ),
        ),
        if (_isCreatingNewCategory) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCategoryController,
                  decoration: const InputDecoration(
                    hintText: 'Новая категория',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addNewCategory(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _addNewCategory,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Размер: ${_formatFileSize(widget.file!.size)}'),
        Text('Тип: ${widget.file!.mimeType}'),
        Text('Создан: ${_formatDate(widget.file!.createdAt)}'),
        Text('Обновлен: ${_formatDate(widget.file!.updatedAt)}'),
      ],
    );
  }

  Widget _buildTagInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Теги:'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _tags
              .map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newTagController,
                decoration: const InputDecoration(
                  hintText: 'Добавить тег',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}