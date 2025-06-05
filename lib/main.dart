import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:taskify/screens/main_screen.dart';
import 'package:taskify/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  final syncService = await SyncService.initialize();

  runApp(MyApp(syncService: syncService));
}

class MyApp extends StatelessWidget {
  final SyncService syncService;

  const MyApp({required this.syncService, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainScreen(syncService: syncService),
    );
  }
}