import 'dart:io';
import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/file.dart';

class WifiTransferService {
  static const int PORT = 4444;
  final NetworkInfo _networkInfo = NetworkInfo();
  ServerSocket? _server;
  List<Socket> _connectedClients = [];
  
  // Стрим для получения информации о передаче
  final _transferController = StreamController<TransferProgress>.broadcast();
  Stream<TransferProgress> get transferStream => _transferController.stream;

  Future<String?> getLocalIpAddress() async {
    return await _networkInfo.getWifiIP();
  }

  // Запуск сервера для приема файлов
  Future<void> startServer() async {
    if (_server != null) return;

    _server = await ServerSocket.bind(InternetAddress.anyIPv4, PORT);
    _server!.listen((Socket socket) {
      _connectedClients.add(socket);
      _handleConnection(socket);
    });
  }

  // Обработка подключения
  void _handleConnection(Socket socket) {
    var buffer = <int>[];
    socket.listen(
      (List<int> data) {
        buffer.addAll(data);
        _transferController.add(
          TransferProgress(
            total: -1, // Пока не знаем полный размер
            received: buffer.length,
            isReceiving: true,
          ),
        );
      },
      onDone: () {
        // Обработка полученного файла
        _processReceivedData(buffer);
        _connectedClients.remove(socket);
        socket.close();
      },
      onError: (error) {
        _transferController.addError(error);
        _connectedClients.remove(socket);
        socket.close();
      },
    );
  }

  // Отправка файла
  Future<void> sendFile(String ip, AppFile file) async {
    try {
      final socket = await Socket.connect(ip, PORT);
      final fileData = file.toJson();
      final data = fileData.toString().codeUnits;
      
      int sent = 0;
      final total = data.length;
      
      // Отправка по частям с обновлением прогресса
      for (var i = 0; i < total; i += 1024) {
        final end = (i + 1024 < total) ? i + 1024 : total;
        final chunk = data.sublist(i, end);
        socket.add(chunk);
        sent += chunk.length;
        
        _transferController.add(
          TransferProgress(
            total: total,
            received: sent,
            isReceiving: false,
          ),
        );
      }
      
      await socket.close();
    } catch (e) {
      _transferController.addError(e);
    }
  }

  void dispose() {
    _server?.close();
    for (var client in _connectedClients) {
      client.close();
    }
    _transferController.close();
  }
}

class TransferProgress {
  final int total;
  final int received;
  final bool isReceiving;

  TransferProgress({
    required this.total,
    required this.received,
    required this.isReceiving,
  });

  double get progress => total > 0 ? received / total : 0;
}