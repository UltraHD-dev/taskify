import 'package:taskify/models/task.dart';

class SyncData {
  final String deviceId;
  final DateTime lastSyncTime;
  final List<Task> tasks;
  final List<String> deletedTaskIds;

  SyncData({
    required this.deviceId,
    required this.lastSyncTime,
    required this.tasks,
    required this.deletedTaskIds,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'lastSyncTime': lastSyncTime.toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'deletedTaskIds': deletedTaskIds,
      };

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      deviceId: json['deviceId'],
      lastSyncTime: DateTime.parse(json['lastSyncTime']),
      tasks: (json['tasks'] as List)
          .map((t) => Task.fromJson(t))
          .toList(),
      deletedTaskIds: (json['deletedTaskIds'] as List)
          .map((id) => id.toString())
          .toList(),
    );
  }
}