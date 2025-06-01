import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class FileQrDisplayScreen extends StatefulWidget {
  final String jsonData;

  const FileQrDisplayScreen({super.key, required this.jsonData});

  @override
  State<FileQrDisplayScreen> createState() => _FileQrDisplayScreenState();
}

class _FileQrDisplayScreenState extends State<FileQrDisplayScreen> {
  final GlobalKey _qrKey = GlobalKey();
  Map<String, dynamic>? _exportData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseExportData();
  }

  void _parseExportData() {
    try {
      final decodedData = jsonDecode(widget.jsonData);
      if (decodedData is Map<String, dynamic>) {
        _exportData = decodedData;
        if (_exportData!['type'] != 'files' || _exportData!['files'] == null) {
          _errorMessage = 'Invalid QR code data format.';
          _exportData = null;
        }
      } else {
        _errorMessage = 'QR code data is not in the expected format.';
        _exportData = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to decode QR data: ${e.toString()}';
      _exportData = null;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<File?> _captureQrCodeToFile() async {
    try {
      if (_qrKey.currentContext == null) {
        throw Exception("QR key context is null. Widget not ready.");
      }
      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Failed to get byte data from QR image.");
      }
      final bytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/files_qr_export.png');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing QR code: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _shareQrCode() async {
    final file = await _captureQrCodeToFile();
    if (file != null && mounted) {
      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'QR code for file transfer (${_exportData?['count'] ?? 0} files). Scan with Taskify app.',
        );
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing QR code: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveQrCodeToGallery() async {
    // Note: Saving directly to gallery requires a platform-specific plugin 
    // like 'image_gallery_saver' or handling platform channels.
    // This is a placeholder to demonstrate the capture part.
    final file = await _captureQrCodeToFile();
    if (file != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR code image saved to temporary path: ${file.path}. Gallery saving requires additional setup.'),
          duration: const Duration(seconds: 5),
        ),
      );
      // To implement actual gallery saving, you would use a plugin here:
      // e.g., await ImageGallerySaver.saveFile(file.path);
    }
  }

  void _showDataDetails() {
    if (_exportData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Type', _exportData!['type']?.toString() ?? 'Unknown'),
              _buildInfoRow('Version', _exportData!['version']?.toString() ?? 'Unknown'),
              _buildInfoRow('File Count', '${_exportData!['count'] ?? 0}'),
              _buildInfoRow('Created At', _formatTimestamp(_exportData!['timestamp']?.toString())),
              _buildInfoRow('Data Size', '${widget.jsonData.length} characters'),
              const SizedBox(height: 16),
              const Text(
                'Files (preview):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildFilesList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Widget> _buildFilesList() {
    if (_exportData?['files'] == null || _exportData!['files'] is! List) return [const Text("No file data available.")];

    final files = _exportData!['files'] as List;
    if (files.isEmpty) return [const Text("0 files in export data.")];

    List<Widget> fileWidgets = files.take(5).map((fileData) {
      if (fileData is! Map<String, dynamic>) return const SizedBox.shrink();
      final name = fileData['name']?.toString() ?? 'Unknown';
      final extension = fileData['extension']?.toString() ?? '';
      final size = fileData['size'] is int ? fileData['size'] as int : 0;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '• $name${extension.isNotEmpty ? '.$extension' : ''} (${_formatFileSize(size)})',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
      
    if (files.length > 5) {
      fileWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '... and ${files.length - 5} more file(s)',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }
    return fileWidgets;
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(timestamp);
      // Consider using intl package for more robust localization
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
             '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid format';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 0) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Export Files')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_exportData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Export Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error Generating QR Code',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Invalid data format for export.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDataDetails,
            tooltip: 'Information',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareQrCode,
            tooltip: 'Share QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _saveQrCodeToGallery, // Changed to reflect placeholder nature
            tooltip: 'Save QR (Placeholder)',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_sharp,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File Export',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Files: ${_exportData!['count'] ?? 0}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan this QR code on another device with the Taskify app to import the files.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(12), // Reduced padding for QR
                decoration: BoxDecoration(
                  color: Colors.white, // QR codes are best on white
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.jsonData,
                  version: QrVersions.auto, // Let the library decide the version
                  backgroundColor: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.7, // Responsive size
                  gapless: false, // Ensure there are no gaps
                  errorCorrectionLevel: QrErrorCorrectLevel.M, // Medium error correction
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to Use',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Open the Taskify app on another device.'),
                    const SizedBox(height: 4),
                    const Text('2. Navigate to the "File Manager".'),
                    const SizedBox(height: 4),
                    const Text('3. Tap the "Scan QR" or "Import" button.'),
                    const SizedBox(height: 4),
                    const Text('4. Point the camera at this QR code.'),
                    const SizedBox(height: 4),
                    const Text('5. Confirm the file import.'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _shareQrCode,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share QR'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _showDataDetails,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
