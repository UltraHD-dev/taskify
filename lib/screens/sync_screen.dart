import 'package:flutter/material.dart';
import 'package:taskify/services/sync_service.dart';
import 'package:taskify/widgets/sync_qr_widget.dart';

class SyncScreen extends StatefulWidget {
  final SyncService syncService;

  const SyncScreen({required this.syncService, super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isSyncing = false;

  Future<void> _handleSyncComplete() async {
    setState(() => _isSyncing = true);
    try {
      await widget.syncService.prepareSyncData();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Синхронизация завершена')),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка синхронизации: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Синхронизация'),
      ),
      body: Center(
        child: _isSyncing
            ? const CircularProgressIndicator()
            : SyncQRWidget(
                syncService: widget.syncService,
                onSyncComplete: _handleSyncComplete,
              ),
      ),
    );
  }
}