// lib/screens/file_dialog.dart
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
    _descriptionController = TextEditingController(text: widget.file?.description ?? '');
    _newCategoryController = TextEditingController();
    _newTagController = TextEditingController();
    
    _selectedCategory = widget.file?.category.isNotEmpty == true ? widget.file!.category : null;
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
    final tag = _newTagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _newTagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addNewCategory() {
    final category = _newCategoryController.text.trim();
    if (category.isNotEmpty && !_availableCategories.contains(category)) {
      setState(() {
        _availableCategories.add(category);
        _selectedCategory = category;
        _isCreatingNewCategory = false;
        _newCategoryController.clear();
      });
      widget.onCategoriesUpdated(_availableCategories);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название файла')),
      );
      return;
    }

    final updatedFile = widget.file?.copyWith(
      name: name,
      description: _descriptionController.text.trim(),
      category: _selectedCategory ?? '',
      tags: _tags,
    ) ?? AppFile(
      name: name,
      extension: 'txt',
      size: 0,
      data: Uint8List.fromList(const []),
      mimeType: 'text/plain',
      description: _descriptionController.text.trim(),
      category: _selectedCategory ?? '',
      tags: _tags,
    );

    widget.onSave(updatedFile);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.file == null ? Icons.add : Icons.edit,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.file == null ? 'Новый файл' : 'Редактировать файл',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Содержимое
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Информация о файле
                    if (widget.file != null) ...[
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                    ],

                    // Название
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        hintText: 'Введите название файла',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.drive_file_rename_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Описание
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        hintText: 'Введите описание файла',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Категория
                    _buildCategorySection(),
                    const SizedBox(height: 16),

                    // Теги
                    _buildTagsSection(),
                  ],
                ),
              ),
            ),

            // Кнопки действий
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final file = widget.file!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildFileTypeIcon(file.fileType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(file.size),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Создан: ${_formatDate(file.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon(FileType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case FileType.image:
        iconData = Icons.image;
        iconColor = Colors.green;
        break;
      case FileType.pdf:
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case FileType.document:
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case FileType.text:
        iconData = Icons.text_snippet;
        iconColor = Colors.grey;
        break;
      case FileType.audio:
        iconData = Icons.audio_file;
        iconColor = Colors.purple;
        break;
      case FileType.video:
        iconData = Icons.video_file;
        iconColor = Colors.orange;
        break;
      case FileType.archive:
        iconData = Icons.archive;
        iconColor = Colors.brown;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категория',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_isCreatingNewCategory) ...[
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
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _addNewCategory(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _addNewCategory,
                color: Colors.green,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isCreatingNewCategory = false;
                  _newCategoryController.clear();
                }),
                color: Colors.red,
              ),
            ],
          ),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Без категории
              ChoiceChip(
                label: const Text('Без категории'),
                selected: _selectedCategory == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = null);
                  }
                },
              ),
              // Существующие категории
              ..._availableCategories.map((category) => ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() => _selectedCategory = selected ? category : null);
                },
              )),
              // Добавить новую категорию
              ActionChip(
                label: const Text('+ Новая'),
                onPressed: () => setState(() => _isCreatingNewCategory = true),
                avatar: const Icon(Icons.add, size: 16),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Теги',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        
        // Существующие теги
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tags.map((tag) => Chip(
              label: Text('#$tag'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeTag(tag),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Поле для добавления нового тега
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
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}