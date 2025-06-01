import 'package:flutter/material.dart';
import 'package:taskify/models/file.dart' as model_file; // Added prefix for local model
import 'package:taskify/service/file_storage.dart';
import 'package:taskify/screens/file_dialog.dart';
import 'package:taskify/widgets/file_tile.dart';
import 'package:file_picker/file_picker.dart' as file_picker_lib; // Added prefix for file_picker

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<model_file.AppFile> files = [];
  List<String> categories = [];
  String? selectedCategory;
  model_file.FileType? selectedFileType; // Use prefixed model_file.FileType
  bool isLoading = false;
  final Set<String> selectedFiles = {};
  bool isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _loadCategories();
    // Removed: _searchController.addListener(_onSearchChanged);
    // The TextField's onChanged callback will handle this.
  }

  @override
  void dispose() {
    // Removed: _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final loadedFiles = await FileStorage.loadFiles();
      if (mounted) {
        setState(() {
          files = loadedFiles;
          _updateCategoriesFromFiles();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки файлов: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    final loadedCategories = await FileStorage.loadFileCategories();
    if (mounted) {
      setState(() => categories = loadedCategories);
    }
  }

  void _updateCategoriesFromFiles() {
    final fileCategories = files
        .map((file) => file.category)
        .where((category) => category.isNotEmpty)
        .toSet();

    bool categoriesChanged = false;
    for (final category in fileCategories) {
      if (!categories.contains(category)) {
        categories.add(category);
        categoriesChanged = true;
      }
    }

    if (categoriesChanged && mounted) {
      categories.sort(); // Keep categories sorted
      FileStorage.saveFileCategories(categories);
    }
  }

  // --- File Picking Logic ---
  Future<void> _pickFiles() async {
    try {
      // Use prefixed file_picker_lib.FileType
      final result = await file_picker_lib.FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: file_picker_lib.FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        int addedCount = 0;
        for (final file in result.files) {
          if (file.bytes != null && file.name.isNotEmpty) {
            final parts = file.name.split('.');
            if (parts.length >= 2) {
              final name = parts.sublist(0, parts.length - 1).join('.');
              final extension = parts.last;

              final appFile = model_file.AppFile( // Use prefixed model_file.AppFile
                name: name,
                extension: extension,
                size: file.bytes!.length,
                data: file.bytes!,
                mimeType: FileStorage.getMimeType(extension),
                // Default category can be empty or a general one
                category: '', 
              );

              final success = await FileStorage.addFile(appFile);
              if (success) {
                addedCount++;
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Не удалось добавить файл: ${file.name}')),
                  );
                }
              }
            }
          }
        }

        if (addedCount > 0) {
          await _loadFiles(); // Reload files to reflect new additions and update categories
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Добавлено файлов: $addedCount')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления файлов: $e')),
        );
      }
    }
  }

  // --- Selection Mode Methods ---
  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedFiles.clear();
      }
    });
  }

  void _toggleFileSelection(String fileId) {
    setState(() {
      if (selectedFiles.contains(fileId)) {
        selectedFiles.remove(fileId);
      } else {
        selectedFiles.add(fileId);
      }
    });
  }

  void _selectAllFiles() {
    setState(() {
      final currentFilteredFiles = filteredFiles; // Cache for consistentcy
      if (selectedFiles.length == currentFilteredFiles.length && currentFilteredFiles.isNotEmpty) {
        selectedFiles.clear();
      } else {
        selectedFiles.clear();
        for (var file in currentFilteredFiles) {
          selectedFiles.add(file.id);
        }
      }
    });
  }

  Future<void> _deleteSelectedFiles() async {
    if (selectedFiles.isEmpty || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранные файлы?'),
        content: Text(
            'Вы уверены, что хотите удалить ${selectedFiles.length} файл(ов)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => isLoading = true);
      try {
        for (final fileId in Set<String>.from(selectedFiles)) { // Iterate over a copy
          await FileStorage.deleteFile(fileId);
        }
        if (mounted) {
           setState(() {
            selectedFiles.clear();
            isSelectionMode = false;
          });
          await _loadFiles(); // This will set isLoading to false
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Выбранные файлы удалены')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления файлов: $e')),
          );
           setState(() => isLoading = false); // Ensure isLoading is reset on error
        }
      }
      // No finally block for isLoading here, _loadFiles or catch handles it
    }
  }

  // --- Search and Filter Logic ---
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<model_file.AppFile> get filteredFiles {
    List<model_file.AppFile> currentFiles = files;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      currentFiles = currentFiles.where((file) {
        return file.name.toLowerCase().contains(query) ||
            file.extension.toLowerCase().contains(query) ||
            (file.category.isNotEmpty && file.category.toLowerCase().contains(query));
      }).toList();
    }

    if (selectedCategory != null) {
      currentFiles = currentFiles
          .where((file) => file.category == selectedCategory)
          .toList();
    }

    if (selectedFileType != null) {
      currentFiles = currentFiles.where((file) {
        // Ensure selectedFileType is model_file.FileType
        switch (selectedFileType!) {
          case model_file.FileType.image:
            return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                .contains(file.extension.toLowerCase());
          case model_file.FileType.pdf:
            return file.extension.toLowerCase() == 'pdf';
          case model_file.FileType.document:
            return ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp']
                .contains(file.extension.toLowerCase());
          case model_file.FileType.text:
            return ['txt', 'md', 'json', 'xml', 'csv', 'rtf']
                .contains(file.extension.toLowerCase());
          case model_file.FileType.audio:
            return ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a']
                .contains(file.extension.toLowerCase());
          case model_file.FileType.video:
            return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv']
                .contains(file.extension.toLowerCase());
          case model_file.FileType.archive:
            return ['zip', 'rar', '7z', 'tar', 'gz', 'bz2']
                .contains(file.extension.toLowerCase());
          case model_file.FileType.other:
             // For 'other', we might want to include files that don't fall into other categories
             // This logic depends on how 'other' is defined.
             // For now, let's assume it means files not matching any specific type above.
             // This can be complex to implement perfectly here without more context.
             // A simple approach: if it's not any of the above, it's 'other'.
             // However, the filter is usually exclusive.
            return true; // Or specific logic for 'other'
        }
      }).toList();
    }
    return currentFiles;
  }

  // --- Dialogs and other UI actions ---
  Future<void> _showFileDialog({model_file.AppFile? file}) async {
    if (!mounted) return;
    // Pass a copy of categories to avoid direct modification issues if FileDialog tries to change it.
    // FileDialog should use the onCategoriesUpdated callback to signal changes.
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FileDialog(
        file: file,
        categories: List<String>.from(categories), // Pass a copy
        onSave: (model_file.AppFile fileData) async {
          // This callback is triggered by FileDialog before it pops.
          // The actual saving happens here.
          // FileDialog will then pop with true, which triggers _loadFiles.
          if (!mounted) return;
          try {
            if (fileData.id.isEmpty) { // Heuristic for new file
              await FileStorage.addFile(fileData);
            } else {
              await FileStorage.updateFile(fileData);
            }
            // If a new category was potentially created and assigned within FileDialog,
            // ensure it's reflected in the main categories list.
            if (fileData.category.isNotEmpty && !categories.contains(fileData.category)) {
                 if (mounted) {
                    setState(() {
                        categories.add(fileData.category);
                        categories.sort();
                    });
                    await FileStorage.saveFileCategories(categories);
                 }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка сохранения файла: $e')),
              );
            }
            // Optionally rethrow or return a value to indicate failure to FileDialog
            // so it doesn't pop with 'true'. For now, assume it pops 'true' on attempt.
          }
        },
        onCategoriesUpdated: (List<String> updatedCategories) async {
          // This callback is triggered by FileDialog if it allows direct category list manipulation
          // (e.g., adding a new category directly to the list it holds).
          if (!mounted) return;
          setState(() {
            categories = updatedCategories; // Update local state
            categories.sort();
          });
          try {
            await FileStorage.saveFileCategories(updatedCategories); // Persist
            // No need to call _loadFiles here if FileDialog will pop(true) on save,
            // or if category update is part of a save operation.
            // If categories can be updated independently of a file save, then _loadFiles might be needed.
            // For simplicity, let's assume a save operation (which pops true) will follow category updates.
            // If not, _loadFiles() or at least _loadCategories() might be needed here.
            await _loadCategories(); // Reload categories to be safe.
            await _loadFiles(); // Reload files as their categories might have changed.

          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка обновления категорий: $e')),
              );
            }
          }
        },
      ),
    );

    if (result == true && mounted) {
      await _loadFiles(); // Reload files if FileDialog indicated success (e.g., save occurred)
    }
  }

  Future<void> _deleteFile(String fileId) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: const Text('Вы уверены, что хотите удалить этот файл?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => isLoading = true);
      try {
        await FileStorage.deleteFile(fileId);
        if (mounted) {
          selectedFiles.remove(fileId);
          await _loadFiles(); // This will set isLoading to false
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Файл удален')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления файла: $e')),
          );
          setState(() => isLoading = false); // Ensure isLoading is reset on error
        }
      }
    }
  }

  void _showStatistics() {
    if (!mounted) return;
    // Basic statistics. Can be expanded.
    int totalSize = files.fold(0, (sum, file) => sum + file.size);
    String totalSizeFormatted = (totalSize / (1024 * 1024)).toStringAsFixed(2); // MB

    Map<String, int> categoryCounts = {};
    for (var file in files) {
      categoryCounts[file.category.isEmpty ? "Без категории" : file.category] =
          (categoryCounts[file.category.isEmpty ? "Без категории" : file.category] ?? 0) + 1;
    }
    String categoryStats = categoryCounts.entries.map((e) => "${e.key}: ${e.value}").join('\n');


    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика файлов'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Всего файлов: ${files.length}'),
              Text('Общий размер: $totalSizeFormatted MB'),
              if (isSelectionMode) Text('Выбрано файлов: ${selectedFiles.length}'),
              const SizedBox(height: 10),
              const Text('Файлов по категориям:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(categoryStats.isEmpty? "Нет файлов с категориями." : categoryStats),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFilteredFiles = filteredFiles; // Cache for consistent access in build

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode
            ? 'Выбрано: ${selectedFiles.length}'
            : 'Файловый менеджер'),
        actions: [
          if (isSelectionMode) ...[
            if (selectedFiles.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteSelectedFiles,
                tooltip: 'Удалить выбранные',
              ),
            IconButton(
              icon: Icon(selectedFiles.length == currentFilteredFiles.length &&
                      currentFilteredFiles.isNotEmpty
                  ? Icons.deselect_outlined
                  : Icons.select_all_outlined),
              onPressed: currentFilteredFiles.isNotEmpty ? _selectAllFiles : null,
              tooltip: selectedFiles.length == currentFilteredFiles.length &&
                      currentFilteredFiles.isNotEmpty
                  ? 'Снять выделение'
                  : 'Выбрать все',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Отмена',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              onPressed: _showStatistics,
              tooltip: 'Статистика',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: "Фильтр",
              onSelected: (value) {
                setState(() {
                  if (value == 'all_categories') {
                    selectedCategory = null;
                  } else if (value.startsWith('category_')) {
                    selectedCategory = value.substring(9);
                  } else if (value == 'all_types') {
                    selectedFileType = null;
                  } else {
                    // Convert string back to model_file.FileType enum
                    selectedFileType = model_file.FileType.values.firstWhere(
                      (type) => type.toString() == value,
                      // orElse: () => model_file.FileType.other, // Or null if no match
                    );
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all_categories',
                  child: Text('Все категории'),
                ),
                ...categories.map((category) => PopupMenuItem(
                      value: 'category_$category',
                      child: Text(category.isEmpty ? "Без категории" : category),
                    )),
                if (categories.isNotEmpty) const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'all_types',
                  child: Text('Все типы'),
                ),
                // Use model_file.FileType for menu items
                ...model_file.FileType.values.map((type) => PopupMenuItem(
                      value: type.toString(), // Store enum as string
                      child: Text(_getFileTypeDisplayName(type)),
                    )),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (!isSelectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск файлов...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged(''); // Explicitly call to update UI
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: _onSearchChanged, // Use onChanged directly
              ),
            ),

          if (selectedCategory != null || selectedFileType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (selectedCategory != null)
                    Chip(
                      label: Text('Категория: ${selectedCategory!.isEmpty ? "Без категории" : selectedCategory}'),
                      onDeleted: () => setState(() => selectedCategory = null),
                    ),
                  if (selectedFileType != null)
                    Chip(
                      label: Text(
                          'Тип: ${_getFileTypeDisplayName(selectedFileType!)}'),
                      onDeleted: () => setState(() => selectedFileType = null),
                    ),
                ],
              ),
            ),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentFilteredFiles.isEmpty
                    ? _buildEmptyState(files.isEmpty) // Pass if original files list is empty
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentFilteredFiles.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = currentFilteredFiles[index];
                          return FileTile(
                            file: file,
                            isSelected: selectedFiles.contains(file.id),
                            isSelectionMode: isSelectionMode,
                            onTap: () {
                              if (isSelectionMode) {
                                _toggleFileSelection(file.id);
                              } else {
                                _showFileDialog(file: file);
                              }
                            },
                            onLongPress: () { // Added for convenience
                                if (!isSelectionMode) {
                                  _toggleSelectionMode();
                                  _toggleFileSelection(file.id);
                                }
                            },
                            onEdit: () => _showFileDialog(file: file), // Only if not in selection mode?
                            onDelete: () => _deleteFile(file.id), // Only if not in selection mode?
                            // onSelect is effectively onTap in selection mode or onLongPress
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton( // Changed to regular FloatingActionButton
              onPressed: _pickFiles,
              tooltip: 'Добавить файлы',
              child: const Icon(Icons.add), // Only icon
            ),
    );
  }

  Widget _buildEmptyState(bool noFilesAtAll) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (noFilesAtAll) { // No files in the storage at all
       return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_off_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Папка пуста',
                style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Нажмите кнопку "Добавить", чтобы загрузить свой первый файл.',
                style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    // Files exist, but current filter/search yields no results
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Нет результатов',
              style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить критерии поиска или сбросить фильтры.',
              style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Use model_file.FileType here
  String _getFileTypeDisplayName(model_file.FileType type) {
    switch (type) {
      case model_file.FileType.image:
        return 'Изображения';
      case model_file.FileType.pdf:
        return 'PDF';
      case model_file.FileType.document:
        return 'Документы';
      case model_file.FileType.text:
        return 'Текст';
      case model_file.FileType.audio:
        return 'Аудио';
      case model_file.FileType.video:
        return 'Видео';
      case model_file.FileType.archive:
        return 'Архивы';
      case model_file.FileType.other:
        return 'Другие';
      // No default needed if all enum values are covered
    }
  }
}
