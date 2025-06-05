import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskify/screens/task_list_screen.dart';
import 'package:taskify/screens/sync_screen.dart';
import 'package:taskify/services/sync_service.dart';
import 'package:taskify/services/theme_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MainScreen extends StatefulWidget {
  final SyncService syncService;

  const MainScreen({required this.syncService, super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Row(
        children: [
          // Боковая навигация
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: theme.navigationRailTheme.backgroundColor,
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withAlpha(26)
                ),
              ),
            ),
            child: Column(
              children: [
                // Заголовок приложения
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: const Duration(seconds: 2),
                            color: Colors.white54,
                          ),
                      const SizedBox(width: 16),
                      Text(
                        'Taskify',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Пункты навигации
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildNavigationItem(
                        icon: Icons.task_outlined,
                        selectedIcon: Icons.task,
                        label: 'Задачи',
                        index: 0,
                      ),
                      _buildNavigationItem(
                        icon: Icons.sync_outlined,
                        selectedIcon: Icons.sync,
                        label: 'Синхронизация',
                        index: 1,
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Нижняя часть сайдбара
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          themeService.setThemeMode(
                            themeService.isDarkMode
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          );
                        },
                        icon: Icon(
                          themeService.isDarkMode
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                        tooltip: themeService.isDarkMode
                            ? 'Светлая тема'
                            : 'Темная тема',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Основной контент
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                TaskListScreen(syncService: widget.syncService),
                SyncScreen(syncService: widget.syncService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedIndex = index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}