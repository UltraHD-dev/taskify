import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController cameraController;
  String? errorMessage;
  bool permissionGranted = false;
  bool isTorchEnabled = false;
  bool isBackCamera = true;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _checkCameraPermission();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      permissionGranted = status.isGranted;
      if (!permissionGranted) {
        errorMessage = 'Требуется разрешение на камеру для сканирования QR-кода.';
      } else {
        errorMessage = null;
      }
    });
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Доступ к камере отклонен.')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Доступ к камере постоянно отклонен. Откройте настройки приложения.')),
        );
      }
      await openAppSettings();
    }
  }

  void _toggleTorch() {
    setState(() {
      isTorchEnabled = !isTorchEnabled;
      cameraController.toggleTorch();
    });
  }

  void _switchCamera() {
    setState(() {
      isBackCamera = !isBackCamera;
      cameraController = MobileScannerController(
        facing: isBackCamera ? CameraFacing.back : CameraFacing.front,
        torchEnabled: isTorchEnabled,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканировать QR-код'),
        actions: [
          IconButton(
            icon: Icon(
              isTorchEnabled ? Icons.flash_on : Icons.flash_off,
              color: isTorchEnabled ? Colors.yellow : Colors.grey,
            ),
            iconSize: 32.0,
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: Icon(
              isBackCamera ? Icons.camera_rear : Icons.camera_front,
            ),
            iconSize: 32.0,
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: permissionGranted
          ? (errorMessage != null
              ? Center(child: Text(errorMessage!))
              : MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final value = barcode.rawValue;
                      if (value != null && mounted) {
                        Navigator.pop(context, value);
                        return;
                      }
                    }
                  },
                ))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(errorMessage ?? 'Проверка разрешения на камеру...'),
                  if (errorMessage != null)
                    ElevatedButton(
                      onPressed: _checkCameraPermission,
                      child: const Text('Повторить попытку получения разрешения'),
                    ),
                ],
              ),
            ),
    );
  }
}