import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:taskify/models/task.dart';
import 'package:taskify/screens/task_list_screen.dart';
import 'package:taskify/services/sync_service.dart';

class FileManagerScreen extends StatefulWidget {
  final SyncService syncService;
  final List<Task> tasks;
  final Function(List<Task>) onTasksImported;

  const FileManagerScreen({
    super.key,
    required this.syncService,
    required this.tasks,
    required this.onTasksImported,
  });

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      setState(() => _files = files);
    } catch (e) {
      _showError('Ошибка при загрузке файлов: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportTasks() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'tasks_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      final tasksJson = jsonEncode(widget.tasks.map((t) => t.toJson()).toList());
      await file.writeAsString(tasksJson);

      await _loadFiles();
      _showSuccess('Задачи экспортированы в файл $fileName');
    } catch (e) {
      _showError('Ошибка при экспорте задач: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importTasks() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      
      final List<dynamic> jsonList = jsonDecode(content);
      final importedTasks = jsonList.map((json) => Task.fromJson(json)).toList();

      widget.onTasksImported(importedTasks);
      _showSuccess('Задачи успешно импортированы');
    } catch (e) {
      _showError('Ошибка при импорте задач: $e');
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      final file = XFile(filePath); 
      await SharePlus.instance.share(ShareParams(
        text: 'Экспортированные задачи',
        files: [file], 
      ));
    } catch (e) {
      _showError('Ошибка при отправке файла: $e');
    }
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
      await _loadFiles();
      _showSuccess('Файл успешно удален');
    } catch (e) {
      _showError('Ошибка при удалении файла: $e');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление файлами'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportTasks,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Экспортировать задачи'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _importTasks,
                          icon: const Icon(Icons.download),
                          label: const Text('Импортировать задачи'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _files.isEmpty
                      ? const Center(
                          child: Text('Нет экспортированных файлов'),
                        )
                      : ListView.builder(
                          itemCount: _files.length,
                          itemBuilder: (context, index) {
                            final file = _files[index];
                            final fileName = file.path.split('/').last;
                            return ListTile(
                              leading: const Icon(Icons.file_present),
                              title: Text(fileName),
                              subtitle: FutureBuilder<FileStat>(
                                future: file.stat(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Text('Загрузка...');
                                  }
                                  final modified = snapshot.data!.modified;
                                  return Text(
                                    'Изменен: ${modified.day}/${modified.month}/${modified.year} '
                                    '${modified.hour}:${modified.minute}',
                                  );
                                },
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share),
                                    onPressed: () => _shareFile(file.path),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Удалить файл?'),
                                        content: Text(
                                          'Вы уверены, что хотите удалить файл $fileName?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteFile(file.path);
                                            },
                                            child: const Text(
                                              'Удалить',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskListScreen(
                            syncService: widget.syncService,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Просмотр задач'),
                  ),
                ),
              ],
            ),
    );
  }
}