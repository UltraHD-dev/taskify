import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:taskify/models/task.dart';
import 'package:taskify/models/file.dart';

class YandexDiskSync {
  static const String _authUrl = 'https://oauth.yandex.ru/authorize';
  static const String _tokenUrl = 'https://oauth.yandex.ru/token';
  static const String _apiUrl = 'https://cloud-api.yandex.net/v1/disk';
  
  // Вам нужно будет зарегистрировать приложение на https://oauth.yandex.ru/
  // и получить свои client_id и client_secret
  static const String _clientId = 'YOUR_CLIENT_ID'; // Замените на ваш
  static const String _clientSecret = 'YOUR_CLIENT_SECRET'; // Замените на ваш
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Connectivity _connectivity = Connectivity();
  
  static const String _tokenKey = 'yandex_access_token';
  static const String _refreshTokenKey = 'yandex_refresh_token';
  static const String _syncEnabledKey = 'sync_enabled';
  static const String _tasksPath = '/taskify/tasks.json';
  static const String _filesPath = '/taskify/files.json';
  static const String _lastSyncKey = 'last_sync_time';
  
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Проверяет, есть ли сохраненный токен
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Проверяет, включена ли синхронизация
  Future<bool> isSyncEnabled() async {
    final enabled = await _storage.read(key: _syncEnabledKey);
    return enabled == 'true';
  }

  /// Включает/выключает синхронизацию
  Future<void> setSyncEnabled(bool enabled) async {
    await _storage.write(key: _syncEnabledKey, value: enabled.toString());
    if (enabled) {
      startAutoSync();
    } else {
      stopAutoSync();
    }
  }

  /// Получает URL для авторизации
  String getAuthUrl() {
    return '$_authUrl?response_type=code&client_id=$_clientId';
  }

  /// Обменивает код авторизации на токен доступа
  Future<bool> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _tokenKey, value: data['access_token']);
        await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка обмена кода на токен: $e');
      return false;
    }
  }

  /// Обновляет токен доступа
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _tokenKey, value: data['access_token']);
        await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка обновления токена: $e');
      return false;
    }
  }

  /// Получает токен доступа
  Future<String?> _getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Выполняет API запрос с автоматическим обновлением токена
  Future<http.Response?> _makeRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    String? token = await _getAccessToken();
    if (token == null) return null;

    final defaultHeaders = {
      'Authorization': 'OAuth $token',
      'Content-Type': 'application/json',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    http.Response response;
    final uri = Uri.parse('$_apiUrl$path');

    try {
      switch (method.toLowerCase()) {
        case 'get':
          response = await http.get(uri, headers: defaultHeaders);
          break;
        case 'put':
          response = await http.put(uri, headers: defaultHeaders, body: body);
          break;
        case 'delete':
          response = await http.delete(uri, headers: defaultHeaders);
          break;
        default:
          return null;
      }

      // Если токен истек, обновляем и повторяем запрос
      if (response.statusCode == 401) {
        if (await _refreshToken()) {
          token = await _getAccessToken();
          defaultHeaders['Authorization'] = 'OAuth $token';
          
          switch (method.toLowerCase()) {
            case 'get':
              response = await http.get(uri, headers: defaultHeaders);
              break;
            case 'put':
              response = await http.put(uri, headers: defaultHeaders, body: body);
              break;
            case 'delete':
              response = await http.delete(uri, headers: defaultHeaders);
              break;
          }
        }
      }

      return response;
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      return null;
    }
  }

  /// Создает папку на Яндекс.Диске
  Future<bool> _createFolder(String path) async {
    final response = await _makeRequest('PUT', '/resources?path=$path');
    return response != null && (response.statusCode == 201 || response.statusCode == 409);
  }

  /// Проверяет наличие интернета
  Future<bool> _hasInternet() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || 
           result.contains(ConnectivityResult.wifi);
  }

  /// Синхронизирует задачи с облаком
  Future<bool> syncTasks(List<Task> localTasks) async {
    if (_isSyncing) return false;
    if (!await _hasInternet()) return false;
    if (!await isSyncEnabled()) return false;

    _isSyncing = true;
    try {
      // Создаем папку, если её нет
      await _createFolder('/taskify');

      // Получаем задачи из облака
      final cloudTasks = await _downloadTasks();
      
      // Объединяем задачи (конфликты разрешаются по времени изменения)
      final mergedTasks = _mergeTasks(localTasks, cloudTasks);
      
      // Загружаем обратно в облако
      await _uploadTasks(mergedTasks);
      
      // Обновляем время последней синхронизации
      await _storage.write(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );
      
      return true;
    } catch (e) {
      print('Ошибка синхронизации задач: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Скачивает задачи из облака
  Future<List<Task>> _downloadTasks() async {
    try {
      // Получаем ссылку на скачивание
      final response = await _makeRequest('GET', '/resources/download?path=$_tasksPath');
      
      if (response == null || response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final downloadUrl = data['href'];
      
      // Скачиваем файл
      final fileResponse = await http.get(Uri.parse(downloadUrl));
      
      if (fileResponse.statusCode == 200) {
        final tasksData = jsonDecode(utf8.decode(fileResponse.bodyBytes)) as List;
        return tasksData.map((t) => Task.fromJson(t)).toList();
      }
      
      return [];
    } catch (e) {
      print('Ошибка скачивания задач: $e');
      return [];
    }
  }

  /// Загружает задачи в облако
  Future<bool> _uploadTasks(List<Task> tasks) async {
    try {
      // Получаем ссылку на загрузку
      final response = await _makeRequest(
        'GET',
        '/resources/upload?path=$_tasksPath&overwrite=true',
      );
      
      if (response == null || response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);
      final uploadUrl = data['href'];
      
      // Загружаем файл
      final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        body: utf8.encode(tasksJson),
        headers: {'Content-Type': 'application/json'},
      );
      
      return uploadResponse.statusCode == 201;
    } catch (e) {
      print('Ошибка загрузки задач: $e');
      return false;
    }
  }

  /// Объединяет локальные и облачные задачи
  List<Task> _mergeTasks(List<Task> local, List<Task> cloud) {
    final Map<String, Task> merged = {};
    
    // Добавляем все локальные задачи
    for (final task in local) {
      merged[task.id] = task;
    }
    
    // Добавляем облачные задачи, разрешая конфликты по времени изменения
    for (final task in cloud) {
      if (!merged.containsKey(task.id)) {
        merged[task.id] = task;
      } else {
        final localTask = merged[task.id]!;
        if (task.updatedAt.isAfter(localTask.updatedAt)) {
          merged[task.id] = task;
        }
      }
    }
    
    return merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Синхронизирует файлы с облаком
  Future<bool> syncFiles(List<AppFile> localFiles) async {
    if (_isSyncing) return false;
    if (!await _hasInternet()) return false;
    if (!await isSyncEnabled()) return false;

    _isSyncing = true;
    try {
      await _createFolder('/taskify');
      
      final cloudFiles = await _downloadFiles();
      final mergedFiles = _mergeFiles(localFiles, cloudFiles);
      
      await _uploadFiles(mergedFiles);
      
      await _storage.write(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );
      
      return true;
    } catch (e) {
      print('Ошибка синхронизации файлов: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Скачивает файлы из облака
  Future<List<AppFile>> _downloadFiles() async {
    try {
      final response = await _makeRequest('GET', '/resources/download?path=$_filesPath');
      
      if (response == null || response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final downloadUrl = data['href'];
      
      final fileResponse = await http.get(Uri.parse(downloadUrl));
      
      if (fileResponse.statusCode == 200) {
        final filesData = jsonDecode(utf8.decode(fileResponse.bodyBytes)) as List;
        return filesData.map((f) => AppFile.fromJson(f)).toList();
      }
      
      return [];
    } catch (e) {
      print('Ошибка скачивания файлов: $e');
      return [];
    }
  }

  /// Загружает файлы в облако
  Future<bool> _uploadFiles(List<AppFile> files) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/resources/upload?path=$_filesPath&overwrite=true',
      );
      
      if (response == null || response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);
      final uploadUrl = data['href'];
      
      final filesJson = jsonEncode(files.map((f) => f.toJson()).toList());
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        body: utf8.encode(filesJson),
        headers: {'Content-Type': 'application/json'},
      );
      
      return uploadResponse.statusCode == 201;
    } catch (e) {
      print('Ошибка загрузки файлов: $e');
      return false;
    }
  }

  /// Объединяет локальные и облачные файлы
  List<AppFile> _mergeFiles(List<AppFile> local, List<AppFile> cloud) {
    final Map<String, AppFile> merged = {};
    
    for (final file in local) {
      merged[file.id] = file;
    }
    
    for (final file in cloud) {
      if (!merged.containsKey(file.id)) {
        merged[file.id] = file;
      } else {
        final localFile = merged[file.id]!;
        if (file.updatedAt.isAfter(localFile.updatedAt)) {
          merged[file.id] = file;
        }
      }
    }
    
    return merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Получает время последней синхронизации
  Future<DateTime?> getLastSyncTime() async {
    final timeStr = await _storage.read(key: _lastSyncKey);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  /// Запускает автоматическую синхронизацию каждые 5 минут
  void startAutoSync() {
    stopAutoSync();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      // Синхронизация будет запущена из экранов
    });
  }

  /// Останавливает автоматическую синхронизацию
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Выход из аккаунта
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _syncEnabledKey);
    await _storage.delete(key: _lastSyncKey);
    stopAutoSync();
  }

  /// Проверяет статус синхронизации
  bool get isSyncing => _isSyncing;
}
