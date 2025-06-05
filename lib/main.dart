import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:taskify/screens/main_screen.dart';
import 'package:taskify/services/sync_service.dart';
import 'package:taskify/services/theme_service.dart';
import 'package:taskify/theme/app_theme.dart';
import 'package:taskify/controllers/animation_controller.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await windowManager.ensureInitialized();

  await windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setMinimumSize(const Size(800, 600));
    await windowManager.setMaximumSize(const Size(1200, 800));
    await windowManager.setSize(const Size(1000, 700));
    await windowManager.center();
    await windowManager.show();
    await windowManager.setFullScreen(false);
    await windowManager.setResizable(true);
  });

  final syncService = await SyncService.initialize();
  final themeService = await ThemeService.initialize();
  final animationController = CustomAnimationController();

  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: animationController),
      ],
      child: MyApp(syncService: syncService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final SyncService syncService;

  const MyApp({required this.syncService, super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          title: 'Taskify',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: MainScreen(syncService: syncService),
        );
      },
    );
  }
}