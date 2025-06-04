import 'package:flutter/material.dart';
import 'package:taskify/models/file.dart' as model_file;
import 'package:taskify/service/file_storage.dart';
import 'package:taskify/screens/file_dialog.dart';
import 'package:taskify/widgets/file_tile.dart';
import 'package:file_picker/file_picker.dart' as file_picker_lib;
import 'package:taskify/widgets/file_qr_display.dart';
import 'package:taskify/screens/qr_scaner_screen.dart'; // Добавлен импорт
import 'package:permission_handler/permission_handler.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<model_file.AppFile> allFiles = [];
  List<model_file.AppFile> files = [];
  List<String> categories = [];
  String? selectedCategory;
  model_file.FileType? selectedFileType;
  bool isLoading = false;
  final Set<String> selectedFiles = {};
  bool isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFilesAndCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilesAndCategories() async {
    setState(() => isLoading = true);
    try {
      final loadedFiles = await FileStorage.loadFiles();
      final loadedCategories = await FileStorage.loadCategories();
      if (!mounted) return;
      setState(() {
        allFiles = loadedFiles;
        categories = loadedCategories;
      });
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки файлов: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickFiles() async {
    final result = await file_picker_lib.FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: file_picker_lib.FileType.any,
    );

    if (result != null && mounted) {
      setState(() => isLoading = true);
      final newFiles = <model_file.AppFile>[];
      for (final platformFile in result.files) {
        if (platformFile.bytes != null) {
          final newFile = model_file.AppFile(
            name: platformFile.name.split('.').first,
            extension: platformFile.extension ?? '',
            size: platformFile.size,
            data: platformFile.bytes!,
            // Исправлено: убрано обращение к несуществующему свойству mimeType
            mimeType: _getMimeTypeFromExtension(platformFile.extension ?? ''),
          );
          newFiles.add(newFile);
        }
      }

      for (final file in newFiles) {
        await FileStorage.saveFile(file);
      }
      await _loadFilesAndCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добавлено ${newFiles.length} файл(ов)'),
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  // Добавлен метод для определения MIME типа по расширению
  String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _editFile(model_file.AppFile file) async {
    final updatedCategories = List<String>.from(categories);
    final resultFile = await showDialog<model_file.AppFile>(
      context: context,
      builder: (context) => FileDialog(
        file: file,
        categories: updatedCategories,
        onCategoriesUpdated: (newCategories) {
          setState(() {
            categories = newCategories;
          });
          FileStorage.saveCategories(newCategories);
        },
        onSave: (editedFile) {
          Navigator.of(context).pop(editedFile);
        },
      ),
    );

    if (resultFile != null) {
      setState(() => isLoading = true);
      await FileStorage.saveFile(resultFile);
      await _loadFilesAndCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл "${resultFile.fullName}" обновлен')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteFile(model_file.AppFile file) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text('Вы уверены, что хотите удалить "${file.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() => isLoading = true);
      final success = await FileStorage.deleteFile(file.id);
      if (success) {
        await _loadFilesAndCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Файл "${file.fullName}" удален')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления файла "${file.fullName}"')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  void _toggleSelection(String fileId) {
    setState(() {
      if (selectedFiles.contains(fileId)) {
        selectedFiles.remove(fileId);
      } else {
        selectedFiles.add(fileId);
      }
      isSelectionMode = selectedFiles.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedFiles.clear();
      isSelectionMode = false;
    });
  }

  Future<void> _exportSelectedFiles() async {
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите файлы для экспорта')),
      );
      return;
    }

    final filesToExport =
        allFiles.where((file) => selectedFiles.contains(file.id)).toList();
    final jsonData = FileStorage.exportFilesToJson(filesToExport);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileQrDisplayScreen(jsonData: jsonData),
      ),
    );
  }

  Future<void> _importFilesFromQr() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Исправлено: проверка mounted перед использованием context
      if (!mounted) return;
      
      final qrData = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (qrData != null && mounted) {
        setState(() => isLoading = true);
        try {
          final importedFiles = FileStorage.importFilesFromJson(qrData);
          int importedCount = 0;
          for (final file in importedFiles) {
            await FileStorage.saveFile(file);
            importedCount++;
          }
          await _loadFilesAndCategories();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Импортировано $importedCount файл(ов)')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка импорта файлов: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() => isLoading = false);
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешение на камеру отклонено.'),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      files = allFiles.where((file) {
        final matchesSearch = _searchQuery.isEmpty ||
            file.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            file.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            file.tags
                .any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));

        final matchesCategory = selectedCategory == null ||
            selectedCategory == '' ||
            file.category == selectedCategory;

        final matchesFileType = selectedFileType == null ||
            file.fileType == selectedFileType;

        return matchesSearch && matchesCategory && matchesFileType;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      selectedCategory = null;
      selectedFileType = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode
            ? Text('${selectedFiles.length} выбрано')
            : const Text('Менеджер файлов'),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Поделиться выбранными файлами',
              onPressed: _exportSelectedFiles,
            )
          else
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Фильтры',
              onPressed: () => _showFilterBottomSheet(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск файлов...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                      )
                    : null,
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _applyFilters();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : files.isEmpty
                    ? _buildNoResultsWidget(context)
                    : ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final isSelected = selectedFiles.contains(file.id);
                          return FileTile(
                            file: file,
                            isSelected: isSelected,
                            isSelectionMode: isSelectionMode,
                            onTap: () {
                              if (isSelectionMode) {
                                _toggleSelection(file.id);
                              } else {
                                _editFile(file);
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                isSelectionMode = true;
                                _toggleSelection(file.id);
                              });
                            },
                            onEdit: () => _editFile(file),
                            onDelete: () async {
                              await _deleteFile(file);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isSelectionMode)
            FloatingActionButton(
              heroTag: 'addFileButton',
              onPressed: _pickFiles,
              tooltip: 'Добавить файл',
              child: const Icon(Icons.add),
            ),
          const SizedBox(height: 16),
          if (!isSelectionMode)
            FloatingActionButton(
              heroTag: 'importQrButton',
              onPressed: _importFilesFromQr,
              tooltip: 'Импортировать по QR',
              child: const Icon(Icons.qr_code_scanner),
            ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    String? tempSelectedCategory = selectedCategory;
    model_file.FileType? tempSelectedFileType = selectedFileType;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Фильтры',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempSelectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Все категории'),
                      ),
                      ...categories.map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          )),
                    ],
                    onChanged: (value) {
                      modalSetState(() {
                        tempSelectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<model_file.FileType>(
                    value: tempSelectedFileType,
                    decoration: const InputDecoration(
                      labelText: 'Тип файла',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Все типы'),
                      ),
                      ...model_file.FileType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_getFileTypeDisplayName(type)),
                          )),
                    ],
                    onChanged: (value) {
                      modalSetState(() {
                        tempSelectedFileType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            modalSetState(() {
                              tempSelectedCategory = null;
                              tempSelectedFileType = null;
                            });
                            setState(() {
                              selectedCategory = null;
                              selectedFileType = null;
                            });
                            _resetFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Сбросить'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCategory = tempSelectedCategory;
                              selectedFileType = tempSelectedFileType;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Применить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoResultsWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              // Исправлено: заменен withOpacity на withValues
              color: colorScheme.primary.withValues(alpha: 0.7),
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
                    // Исправлено: заменен withOpacity на withValues
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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
    }
  }
}