import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskify/models/sync_data.dart';
import 'package:taskify/services/task_storage.dart';

class SyncService {
  static const String _deviceIdKey = 'device_id';
  static const String _lastSyncTimeKey = 'last_sync_time';
  final TaskStorage _taskStorage;
  final SharedPreferences _prefs;
  final String deviceId;

  SyncService._(this._taskStorage, this._prefs, this.deviceId);

  static Future<SyncService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = await TaskStorage.initialize(); // Исправлено
    
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return SyncService._(storage, prefs, deviceId);
  }
  Future<DateTime?> getLastSyncTime() async {
    final timeStr = _prefs.getString(_lastSyncTimeKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setString(_lastSyncTimeKey, time.toIso8601String());
  }

  Future<SyncData> prepareSyncData() async {
    final tasks = await _taskStorage.loadTasks();
    final deletedTaskIds = await _taskStorage.getDeletedTaskIds();
    final lastSyncTime = await getLastSyncTime() ?? DateTime.now();

    return SyncData(
      deviceId: deviceId,
      lastSyncTime: lastSyncTime,
      tasks: tasks,
      deletedTaskIds: deletedTaskIds,
    );
  }

  Future<void> processSyncData(SyncData incomingData) async {
    if (incomingData.deviceId == deviceId) return;

    final localTasks = await _taskStorage.loadTasks();
    final localTaskMap = {for (var task in localTasks) task.id: task};
    
    // Process deleted tasks
    for (final deletedId in incomingData.deletedTaskIds) {
      await _taskStorage.deleteTask(deletedId);
      localTaskMap.remove(deletedId);
    }

    // Process incoming tasks
    for (final incomingTask in incomingData.tasks) {
      final localTask = localTaskMap[incomingTask.id];
      
      if (localTask == null) {
        // New task - add it
        await _taskStorage.saveTask(incomingTask);
      } else if (incomingTask.modifiedAt.isAfter(localTask.modifiedAt)) {
        // Incoming task is newer - update local
        await _taskStorage.saveTask(incomingTask);
      }
    }

    // Update last sync time
    await setLastSyncTime(DateTime.now());
  }
}