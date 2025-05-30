import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:task_manager/models/task.dart';

class QrScanner extends StatefulWidget {
  final List<Task> tasks;

  const QrScanner({super.key, required this.tasks});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateQrData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _generateQrData() {
    final tasksJson = jsonEncode(widget.tasks.map((task) => task.toJson()).toList());
    setState(() {
      _qrData = tasksJson;
    });
  }

  void _importTasks() {
    try {
      final String input = _textController.text.trim();
      if (input.isEmpty) {
        _showError('Введите данные для импорта');
        return;
      }

      final List<dynamic> decoded = jsonDecode(input);
      final List<Task> importedTasks = decoded.map((t) => Task.fromJson(t)).toList();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Импорт задач'),
          content: Text('Найдено ${importedTasks.length} задач. Импортировать?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, importedTasks);
              },
              child: const Text('Импортировать'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Ошибка при импорте данных: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _copyToClipboard() {
    // Для простоты показываем диалог с данными
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR данные'),
        content: SingleChildScrollView(
          child: SelectableText(_qrData),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Синхронизация задач'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'Экспорт'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Импорт'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExportTab(),
          _buildImportTab(),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'QR-код для экспорта ваших задач:',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_qrData.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy),
            label: const Text('Показать данные'),
          ),
          const SizedBox(height: 10),
          Text(
            'Задач в QR-коде: ${widget.tasks.length}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Вставьте JSON данные для импорта задач:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Вставьте JSON данные здесь...',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _importTasks,
              icon: const Icon(Icons.download),
              label: const Text('Импортировать задачи'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Примечание: Это заменит все текущие задачи',
            style: TextStyle(color: Colors.orange, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}