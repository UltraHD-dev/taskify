import 'package:flutter/material.dart';
import 'package:taskify/models/file.dart';

class FileTile extends StatelessWidget {
  final AppFile file;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // Added onLongPress
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FileTile({
    super.key,
    required this.file,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    this.onLongPress, // Added to constructor
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress, // Use the new onLongPress
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Selection indicator
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                ),
              
              // File Type Icon
              _buildFileTypeIcon(file.fileType, context),
              const SizedBox(width: 16),

              // File Name and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fullName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(file.size),
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7) // Changed to double
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (file.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.7) // Changed to double
                              : colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          file.category,
                          style: textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons (only if not in selection mode)
              if (!isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: colorScheme.onSurfaceVariant,
                  onPressed: onEdit,
                  tooltip: 'Редактировать',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colorScheme.error,
                  onPressed: onDelete,
                  tooltip: 'Удалить',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon(FileType type, BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case FileType.image:
        iconData = Icons.image;
        iconColor = Colors.green;
        break;
      case FileType.pdf:
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case FileType.document:
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case FileType.text:
        iconData = Icons.text_snippet;
        iconColor = Colors.grey;
        break;
      case FileType.audio:
        iconData = Icons.audio_file;
        iconColor = Colors.purple;
        break;
      case FileType.video:
        iconData = Icons.video_file;
        iconColor = Colors.orange;
        break;
      case FileType.archive:
        iconData = Icons.archive;
        iconColor = Colors.brown;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15), // Changed to double
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: iconColor, size: 30),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
