import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:taskify/service/file_storage.dart';
import 'package:taskify/models/file.dart';

class WifiSyncService {
  HttpServer? _server;
  String? _localIpAddress;
  static const int _port = 8080;

  Future<String?> startServer(List<String> fileIdsToShare) async {
    try {
      final info = NetworkInfo();
      _localIpAddress = await info.getWifiIP();

      if (_localIpAddress == null) {
        developer.log('Could not get local IP address.');
        return null;
      }

      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      developer.log('Server started on $_localIpAddress:$_port');

      _server?.listen((HttpRequest request) async {
        try {
          if (request.uri.path == '/manifest') {
            final allFiles = await FileStorage.loadFiles();
            final filesToExport = allFiles.where((f) => fileIdsToShare.contains(f.id)).toList();
            final manifestJson = FileStorage.exportFilesToJson(filesToExport);
            
            request.response.headers.contentType = ContentType.json;
            request.response.headers.add('Access-Control-Allow-Origin', '*');
            request.response.write(manifestJson);
          } else if (request.uri.path.startsWith('/file/')) {
            final fileId = request.uri.pathSegments.last;
            final allFiles = await FileStorage.loadFiles();
            final fileToServe = allFiles.firstWhere(
              (f) => f.id == fileId,
              orElse: () => AppFile(
                id: '',
                name: '',
                extension: '',
                size: 0,
                mimeType: '',
                data: Uint8List(0),
              ),
            );

            if (fileToServe.id.isNotEmpty) {
              request.response.headers.contentType = ContentType.parse(fileToServe.mimeType);
              request.response.headers.contentLength = fileToServe.data.length;
              request.response.headers.add('Access-Control-Allow-Origin', '*');
              request.response.headers.add(
                'Content-Disposition',
                'attachment; filename="${fileToServe.fullName}"'
              );
              request.response.add(fileToServe.data);
            } else {
              request.response.statusCode = HttpStatus.notFound;
              request.response.write('File not found');
            }
          } else {
            request.response.statusCode = HttpStatus.notFound;
            request.response.write('Not Found');
          }
          await request.response.close();
        } catch (e) {
          developer.log('Error handling request: $e');
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            request.response.write('Internal server error');
            await request.response.close();
          } catch (closeError) {
            developer.log('Error closing response: $closeError');
          }
        }
      });

      return '$_localIpAddress:$_port';
    } catch (e) {
      developer.log('Error starting server: $e');
      await stopServer();
      return null;
    }
  }

  Future<void> stopServer() async {
    try {
      await _server?.close(force: true);
      _server = null;
      developer.log('Server stopped.');
    } catch (e) {
      developer.log('Error stopping server: $e');
    }
  }

  Future<bool> connectAndDownload(String remoteIpPort) async {
    HttpClient? client;
    try {
      final parts = remoteIpPort.split(':');
      if (parts.length != 2) {
        developer.log('Invalid remote IP:Port format.');
        return false;
      }
      final ip = parts[0];
      final port = int.tryParse(parts[1]) ?? _port;

      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..idleTimeout = const Duration(seconds: 30);

      developer.log('Fetching manifest from http://$ip:$port/manifest');
      final manifestUri = Uri.parse('http://$ip:$port/manifest');
      final manifestRequest = await client.getUrl(manifestUri);
      final manifestResponse = await manifestRequest.close();

      if (manifestResponse.statusCode != HttpStatus.ok) {
        developer.log('Failed to get manifest: ${manifestResponse.statusCode}');
        return false;
      }

      final manifestJson = await manifestResponse.transform(utf8.decoder).join();
      developer.log('Received manifest: $manifestJson');
      
      final decodedManifest = jsonDecode(manifestJson);
      if (decodedManifest is! Map<String, dynamic> ||
          decodedManifest['type'] != 'files' ||
          decodedManifest['files'] is! List) {
        developer.log('Invalid manifest format.');
        return false;
      }

      final List<dynamic> filesToDownload = decodedManifest['files'];
      developer.log('Found ${filesToDownload.length} files to download');
      
      int downloadedCount = 0;

      for (final fileDataJson in filesToDownload) {
        try {
          final String fileId = fileDataJson['id'];
          final String fileName = fileDataJson['name'];
          final String fileExtension = fileDataJson['extension'];
          final String mimeType = fileDataJson['mimeType'];
          final int size = fileDataJson['size'];
          final String description = fileDataJson['description'] ?? '';
          final String category = fileDataJson['category'] ?? '';
          final List<String> tags = 
              (fileDataJson['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final DateTime createdAt = DateTime.tryParse(fileDataJson['createdAt'] ?? '') ?? DateTime.now();
          final DateTime updatedAt = DateTime.tryParse(fileDataJson['updatedAt'] ?? '') ?? DateTime.now();

          developer.log('Downloading file: $fileName');
          final fileUri = Uri.parse('http://$ip:$port/file/$fileId');
          final fileRequest = await client.getUrl(fileUri);
          final fileResponse = await fileRequest.close();

          if (fileResponse.statusCode == HttpStatus.ok) {
            final builder = BytesBuilder(copy: false);
            await for (var data in fileResponse) {
              builder.add(data);
            }
            final fileBytes = builder.takeBytes();
            developer.log('Downloaded ${fileBytes.length} bytes for $fileName');

            final newAppFile = AppFile(
              id: fileId,
              name: fileName,
              extension: fileExtension,
              size: size,
              data: fileBytes,
              mimeType: mimeType,
              description: description,
              category: category,
              tags: tags,
              createdAt: createdAt,
              updatedAt: updatedAt,
            );

            developer.log('Saving file: ${newAppFile.fullName}');
            try {
              await FileStorage.saveFile(newAppFile);
              downloadedCount++;
              developer.log('Successfully saved: ${newAppFile.fullName}');
            } catch (e) {
              developer.log('Failed to save ${newAppFile.fullName}: $e');
            }
          } else {
            developer.log('Failed to download $fileName: ${fileResponse.statusCode}');
          }
        } catch (e, stackTrace) {
          developer.log('Error processing file: $e\n$stackTrace');
        }
      }

      developer.log('Download complete. Successfully downloaded $downloadedCount files');
      return downloadedCount > 0;
    } catch (e, stackTrace) {
      developer.log('Error in connectAndDownload: $e\n$stackTrace');
      return false;
    } finally {
      client?.close();
    }
  }
}