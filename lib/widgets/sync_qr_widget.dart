import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taskify/services/sync_service.dart';

class SyncQRWidget extends StatefulWidget {
  final SyncService syncService;
  final Function() onSyncComplete;

  const SyncQRWidget({
    required this.syncService,
    required this.onSyncComplete,
    super.key,
  });

  @override
  State<SyncQRWidget> createState() => _SyncQRWidgetState();
}

class _SyncQRWidgetState extends State<SyncQRWidget> {
  String? _qrData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _prepareSyncData();
  }

  Future<void> _prepareSyncData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final syncData = await widget.syncService.prepareSyncData();
      if (!mounted) return;

      final jsonData = jsonEncode(syncData.toJson());
      setState(() {
        _qrData = jsonData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      _showError('Ошибка подготовки данных: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _qrData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Ошибка генерации QR-кода'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _prepareSyncData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QrImageView(
            data: _qrData!,
            version: QrVersions.auto,
            size: 300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Отсканируйте этот QR-код на другом устройстве\n'
            'для синхронизации задач',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _prepareSyncData().then((_) {
                if (mounted) {
                  _showSuccess('QR-код обновлен');
                }
              });
            },
            child: const Text('Обновить QR-код'),
          ),
        ],
      ),
    );
  }
}