import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class FileQrDisplayScreen extends StatefulWidget {
  final String jsonData;

  const FileQrDisplayScreen({super.key, required this.jsonData});

  @override
  State<FileQrDisplayScreen> createState() => _FileQrDisplayScreenState();
}

class _FileQrDisplayScreenState extends State<FileQrDisplayScreen> {
  final GlobalKey _qrKey = GlobalKey();
  Map<String, dynamic>? _exportData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseExportData();
  }

  void _parseExportData() {
    try {
      final decodedData = jsonDecode(widget.jsonData);
      if (decodedData is Map<String, dynamic>) {
        _exportData = decodedData;
        if (_exportData!['type'] != 'files' || _exportData!['files'] == null) {
          _errorMessage = 'Неверный формат данных QR-кода.';
          _exportData = null;
        }
      } else {
        _errorMessage = 'Данные QR-кода не в ожидаемом формате.';
        _exportData = null;
      }
    } catch (e) {
      _errorMessage = 'Не удалось декодировать данные QR: $e';
      _exportData = null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareQrCode() async {
    if (_qrKey.currentContext == null) {
      return;
    }

    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Мой QR-код файла!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обмене QR-кодом: $e')),
        );
      }
    }
  }

  void _showDataDetails() {
    if (_exportData == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детали данных QR-кода'),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(_exportData),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
        title: const Text('QR-код файла'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: RepaintBoundary(
                          key: _qrKey,
                          child: QrImageView(
                            data: widget.jsonData,
                            version: QrVersions.auto,
                            size: 280.0,
                            gapless: true,
                            backgroundColor: Colors.white,
                            errorStateBuilder: (cxt, err) {
                              return const Center(
                                child: Text(
                                  'Упс! Что-то пошло не так при генерации QR-кода.',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const Text(
                        'Отсканируйте этот QR-код для импорта файлов.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Инструкции по импорту:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                  '1. Откройте приложение на другом устройстве.'),
                              const SizedBox(height: 4),
                              const Text(
                                  '2. Перейдите в раздел "Менеджер файлов".'),
                              const SizedBox(height: 4),
                              const Text('3. Нажмите "Импортировать по QR".'),
                              const SizedBox(height: 4),
                              const Text('4. Наведите камеру на этот QR-код.'),
                              const SizedBox(height: 4),
                              const Text('5. Подтвердите импорт файла.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _shareQrCode,
                                icon: const Icon(Icons.share_outlined),
                                label: const Text('Поделиться QR'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _showDataDetails,
                                icon: const Icon(Icons.info_outline),
                                label: const Text('Детали'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}