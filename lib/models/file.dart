import 'dart:convert';
import 'dart:typed_data';
import 'package:taskify/service/file_storage.dart';

enum FileType {
  image,
  pdf,
  document,
  text,
  audio,
  video,
  archive,
  other,
}

class AppFile {
  final String id;
  final String name;
  final String extension;
  final int size;
  final Uint8List data;
  final String mimeType;
  final String description;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppFile({
    String? id,
    required this.name,
    required this.extension,
    required this.size,
    required this.data,
    required this.mimeType,
    this.description = '',
    this.category = '',
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _generateId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String get fullName => '$name.$extension';

  FileType get fileType => FileStorage.getFileType(extension);

  bool get isImage => fileType == FileType.image;
  bool get isPdf => fileType == FileType.pdf;
  bool get isDocument => fileType == FileType.document;
  bool get isText => fileType == FileType.text;

  AppFile copyWith({
    String? id,
    String? name,
    String? extension,
    int? size,
    Uint8List? data,
    String? mimeType,
    String? description,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppFile(
      id: id ?? this.id,
      name: name ?? this.name,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      data: data ?? this.data,
      mimeType: mimeType ?? this.mimeType,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extension': extension,
      'size': size,
      'data': base64Encode(data),
      'mimeType': mimeType,
      'description': description,
      'category': category,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppFile.fromJson(Map<String, dynamic> json) {
    return AppFile(
      id: json['id'] as String,
      name: json['name'] as String,
      extension: json['extension'] as String,
      size: json['size'] as int,
      data: base64Decode(json['data'] as String),
      mimeType: json['mimeType'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          extension == other.extension &&
          size == other.size &&
          data == other.data &&
          mimeType == other.mimeType &&
          description == other.description &&
          category == other.category &&
          tags == other.tags &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      extension.hashCode ^
      size.hashCode ^
      data.hashCode ^
      mimeType.hashCode ^
      description.hashCode ^
      category.hashCode ^
      tags.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}