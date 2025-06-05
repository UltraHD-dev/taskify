import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:taskify/models/file.dart';
import 'dart:developer' as developer;

class FileStorage {
  static FileType getFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return FileType.image;
      case 'pdf':
        return FileType.pdf;
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
        return FileType.document;
      case 'txt':
      case 'md':
      case 'rtf':
        return FileType.text;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
        return FileType.audio;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return FileType.video;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return FileType.archive;
      default:
        return FileType.other;
    }
  }

  static Future<List<String>> loadCategories() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/categories.json');

      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      return decoded.cast<String>();
    } catch (e) {
      developer.log('Error loading categories: $e');
      return [];
    }
  }

  static Future<void> saveCategories(List<String> categories) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/categories.json');
      await file.writeAsString(jsonEncode(categories));
    } catch (e) {
      developer.log('Error saving categories: $e');
      rethrow;
    }
  }

  static Future<void> saveFile(AppFile file) async {
    try {
      developer.log('Starting to save file: ${file.fullName}');
      
      final directory = await getApplicationDocumentsDirectory();
      final filesDir = Directory('${directory.path}/files');
      
      // Создаём директорию для файлов, если её нет
      if (!await filesDir.exists()) {
        await filesDir.create(recursive: true);
      }

      // Сохраняем данные файла
      if (file.data.isNotEmpty) {
        final dataFilePath = '${filesDir.path}/${file.id}${file.extension}';
        final dataFile = File(dataFilePath);
        await dataFile.create(recursive: true);
        await dataFile.writeAsBytes(file.data);
        developer.log('File data saved to: $dataFilePath');
      } else {
        developer.log('File data is empty, skipping data save');
      }

      // Загружаем текущий список файлов
      List<AppFile> files = [];
      final metadataFile = File('${directory.path}/files.json');
      
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        files = (decoded['files'] as List)
            .map((item) => AppFile.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Обновляем или добавляем файл
      final index = files.indexWhere((f) => f.id == file.id);
      if (index != -1) {
        files[index] = file;
        developer.log('Updated existing file record');
      } else {
        files.add(file);
        developer.log('Added new file record');
      }

      // Сохраняем обновленный список файлов
      await metadataFile.writeAsString(jsonEncode({
        'files': files.map((f) => f.toJson()).toList(),
      }));
      
      developer.log('File metadata saved successfully');
    } catch (e, stackTrace) {
      developer.log('Error saving file: $e\n$stackTrace');
      rethrow;
    }
  }

  static Future<bool> deleteFile(String fileId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filesDir = Directory('${directory.path}/files');
      final metadataFile = File('${directory.path}/files.json');

      if (!await metadataFile.exists()) {
        return false;
      }

      // Загружаем текущий список файлов
      List<AppFile> files = [];
      final content = await metadataFile.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      files = (decoded['files'] as List)
          .map((item) => AppFile.fromJson(item as Map<String, dynamic>))
          .toList();

      // Находим файл для удаления
      final fileIndex = files.indexWhere((f) => f.id == fileId);
      if (fileIndex == -1) {
        return false;
      }

      // Удаляем файл с диска
      final fileToDelete = files[fileIndex];
      final dataFilePath = '${filesDir.path}/$fileId${fileToDelete.extension}';
      final dataFile = File(dataFilePath);
      if (await dataFile.exists()) {
        await dataFile.delete();
      }

      // Удаляем из списка
      files.removeAt(fileIndex);

      // Сохраняем обновленный список
      await metadataFile.writeAsString(jsonEncode({
        'files': files.map((f) => f.toJson()).toList(),
      }));

      return true;
    } catch (e) {
      developer.log('Error deleting file: $e');
      return false;
    }
  }

  static Future<List<AppFile>> loadFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/files.json');

      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      
      return (decoded['files'] as List)
          .map((item) => AppFile.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error loading files: $e');
      return [];
    }
  }

  static String exportFilesToJson(List<AppFile> files) {
    return jsonEncode({
      'type': 'files',
      'files': files.map((f) => f.toJson()).toList(),
    });
  }

  static List<AppFile> importFilesFromJson(String jsonData) {
    try {
      final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
      if (decoded['type'] != 'files' || decoded['files'] is! List) {
        throw FormatException('Invalid file format');
      }

      return (decoded['files'] as List)
          .map((item) => AppFile.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error importing files from JSON: $e');
      rethrow;
    }
  }
}