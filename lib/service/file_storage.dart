import 'dart:convert';
import 'dart:io';
// Removed: import 'dart:typed_data'; // Unused import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart'; // Ensure this is in your pubspec.yaml
import 'package:taskify/models/file.dart';

class FileStorage {
  static const _filesKey = 'files';
  static const _fileCategoriesKey = 'file_categories';
  static const _filesDirectoryName = 'taskify_files';

  static Future<Directory> _getFilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filesDir = Directory('${appDir.path}/$_filesDirectoryName');
    
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    
    return filesDir;
  }

  static Future<List<AppFile>> loadFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getStringList(_filesKey);
      
      if (filesJson == null || filesJson.isEmpty) {
        return [];
      }
      
      final List<AppFile> files = [];
      for (final fileJsonString in filesJson) {
        try {
          final fileJson = jsonDecode(fileJsonString) as Map<String, dynamic>;
          final file = AppFile.fromJson(fileJson);
          files.add(file);
        } catch (e) {
          // Skip corrupted entries
          print('Error decoding file JSON: $e'); // Optional: log error
          continue;
        }
      }
      
      return files;
    } catch (e) {
      print('Error loading files: $e'); // Optional: log error
      return [];
    }
  }

  static Future<bool> saveFiles(List<AppFile> files) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = files.map((file) => jsonEncode(file.toJson())).toList();
      
      return await prefs.setStringList(_filesKey, filesJson);
    } catch (e) {
      print('Error saving files: $e'); // Optional: log error
      return false;
    }
  }

  static Future<bool> addFile(AppFile file) async {
    try {
      final files = await loadFiles();
      files.add(file);
      return await saveFiles(files);
    } catch (e) {
      print('Error adding file: $e'); // Optional: log error
      return false;
    }
  }

  static Future<bool> deleteFile(String fileId) async {
    try {
      final files = await loadFiles();
      files.removeWhere((file) => file.id == fileId);
      return await saveFiles(files);
    } catch (e) {
      print('Error deleting file: $e'); // Optional: log error
      return false;
    }
  }

  static Future<bool> updateFile(AppFile updatedFile) async {
    try {
      final files = await loadFiles();
      final index = files.indexWhere((file) => file.id == updatedFile.id);
      
      if (index != -1) {
        files[index] = updatedFile;
        return await saveFiles(files);
      }
      
      return false;
    } catch (e) {
      print('Error updating file: $e'); // Optional: log error
      return false;
    }
  }

  static Future<bool> saveFileToDevice(AppFile file, String? customPath) async {
    try {
      Directory targetDir;
      
      if (customPath != null && customPath.isNotEmpty) {
        targetDir = Directory(customPath);
      } else {
        targetDir = await _getFilesDirectory();
      }
      
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      final filePath = '${targetDir.path}/${file.fullName}';
      final deviceFile = File(filePath);
      
      await deviceFile.writeAsBytes(file.data);
      return true;
    } catch (e) {
      print('Error saving file to device: $e'); // Optional: log error
      return false;
    }
  }

  static Future<AppFile?> loadFileFromDevice(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final data = await file.readAsBytes();
      final stat = await file.stat();
      final fileName = file.path.split('/').last;
      final parts = fileName.split('.');
      
      if (parts.length < 2) return null; 
      
      final name = parts.sublist(0, parts.length - 1).join('.');
      final extension = parts.last;
      
      return AppFile(
        name: name,
        extension: extension,
        size: data.length,
        data: data,
        mimeType: getMimeType(extension),
        createdAt: stat.changed, 
      );
    } catch (e) {
      print('Error loading file from device: $e'); // Optional: log error
      return null;
    }
  }

  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'aac':
        return 'audio/aac';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/avi';
      case 'mkv':
        return 'video/x-matroska';
      case 'mov':
        return 'video/quicktime';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'flv':
        return 'video/x-flv';
      case 'webm':
        return 'video/webm';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';
      case 'apk':
        return 'application/vnd.android.package-archive';
      case 'exe':
        return 'application/x-msdownload';
      case 'dmg':
        return 'application/x-apple-diskimage';
      default:
        return 'application/octet-stream';
    }
  }

  static FileType getFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return FileType.image;
      case 'pdf':
        return FileType.pdf;
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      // Adding OpenDocument formats often found alongside MS Office
      case 'odt': // OpenDocument Text
      case 'ods': // OpenDocument Spreadsheet
      case 'odp': // OpenDocument Presentation
        return FileType.document;
      case 'txt':
      case 'csv':
      case 'html':
      case 'htm':
      case 'css':
      case 'js':
      case 'json':
      case 'xml':
      case 'md': // Markdown
      case 'rtf': // Rich Text Format
        return FileType.text;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'aac':
      case 'm4a': // MPEG-4 Audio
        return FileType.audio;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
        return FileType.video;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
      case 'bz2': // BZip2
        return FileType.archive;
      default:
        return FileType.other;
    }
  }

  static Future<List<String>> loadFileCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_fileCategoriesKey) ?? [];
    } catch (e) {
      print('Error loading file categories: $e'); // Optional: log error
      return [];
    }
  }

  static Future<bool> saveFileCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setStringList(_fileCategoriesKey, categories);
    } catch (e) {
      print('Error saving file categories: $e'); // Optional: log error
      return false;
    }
  }

  static Future<bool> clearFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_filesKey);
      await prefs.remove(_fileCategoriesKey);
      
      final filesDir = await _getFilesDirectory();
      if (await filesDir.exists()) {
        await filesDir.delete(recursive: true);
      }
      
      return true;
    } catch (e) {
      print('Error clearing files: $e'); // Optional: log error
      return false;
    }
  }

  static Future<int> getTotalFilesSize() async {
    try {
      final files = await loadFiles();
      // Ensure 'sum' is an int and 'file.size' is an int.
      return files.fold<int>(0, (sum, file) => sum + file.size);
    } catch (e) {
      print('Error getting total files size: $e'); // Optional: log error
      return 0;
    }
  }

  static Future<String> exportFilesToJson(List<String> fileIds) async {
    try {
      final allFiles = await loadFiles();
      final filesToExport = allFiles.where((file) => fileIds.contains(file.id)).toList();
      
      final exportData = {
        'type': 'files',
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'count': filesToExport.length,
        'files': filesToExport.map((file) => file.toJson()).toList(),
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      print('Error exporting files to JSON: $e'); // Optional: log error
      return '';
    }
  }

  static Future<List<AppFile>> importFilesFromJson(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      
      if (data['type'] != 'files' || data['files'] == null || data['files'] is! List) {
        throw Exception('Invalid data format for import');
      }
      
      final filesData = data['files'] as List;
      final importedFiles = <AppFile>[];
      
      for (final fileData in filesData) {
        if (fileData is Map<String, dynamic>) {
          try {
            final file = AppFile.fromJson(fileData);
            importedFiles.add(file);
          } catch (e) {
            print('Error importing individual file from JSON: $e'); // Optional: log error
            continue;
          }
        }
      }
      
      return importedFiles;
    } catch (e) {
      print('Error importing files from JSON: $e'); // Optional: log error
      return [];
    }
  }

  static Future<Map<String, dynamic>> getFilesStatistics() async {
    try {
      final files = await loadFiles();
      // Ensure 'sum' is an int and 'file.size' is an int.
      final totalSize = files.fold<int>(0, (sum, file) => sum + file.size);
      
      final typeStats = <FileType, int>{};
      final categoryStats = <String, int>{};
      
      for (final file in files) {
        typeStats[file.fileType] = (typeStats[file.fileType] ?? 0) + 1;
        // Ensure category is treated consistently, e.g., empty string for uncategorized
        final categoryKey = file.category.isEmpty ? '' : file.category;
        categoryStats[categoryKey] = (categoryStats[categoryKey] ?? 0) + 1;
      }
      
      // Convert FileType keys to String for JSON compatibility if needed,
      // but the FileManagerScreen expects Map<FileType, int>
      return {
        'totalFiles': files.length,
        'totalSize': totalSize,
        'typeStats': typeStats, // Keep as Map<FileType, int> for direct use
        'categoryStats': categoryStats,
        'categories': await loadFileCategories(), // Load fresh categories list
      };
    } catch (e) {
      print('Error getting files statistics: $e'); // Optional: log error
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'typeStats': <FileType, int>{},
        'categoryStats': <String, int>{},
        'categories': <String>[],
      };
    }
  }

  static Future<List<AppFile>> searchFiles({
    String? query,
    String? category,
    FileType? fileType,
    List<String>? tags,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final allFiles = await loadFiles();
      
      return allFiles.where((file) {
        if (query != null && query.isNotEmpty) {
          final queryLower = query.toLowerCase();
          final nameMatch = file.name.toLowerCase().contains(queryLower);
          // Assuming AppFile has a description field, if not, remove this.
          // final descMatch = file.description.toLowerCase().contains(queryLower);
          // if (!nameMatch && !descMatch) return false;
          if (!nameMatch) return false; // If no description field
        }
        
        if (category != null && file.category != category) {
          return false;
        }
        
        if (fileType != null && file.fileType != fileType) {
          return false;
        }
        
        if (tags != null && tags.isNotEmpty) {
          // Assuming AppFile has a tags list, if not, remove/adjust this.
          // final hasAnyTag = tags.any((tag) => file.tags.contains(tag));
          // if (!hasAnyTag) return false;
        }
        
        if (fromDate != null && file.createdAt.isBefore(fromDate)) {
          return false;
        }
        
        if (toDate != null && file.createdAt.isAfter(toDate)) {
          return false;
        }
        
        return true;
      }).toList();
    } catch (e) {
      print('Error searching files: $e'); // Optional: log error
      return [];
    }
  }
}