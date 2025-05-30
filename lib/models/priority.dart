// lib/models/priority.dart
import 'package:flutter/material.dart';

enum Priority {
  low(Colors.green, 'Низкий'),
  medium(Colors.orange, 'Средний'),
  high(Colors.red, 'Высокий');

  final Color color;
  final String name;

  const Priority(this.color, this.name);

  // Добавляем статический метод для получения значения по индексу
  static Priority fromIndex(int index) {
    return Priority.values[index];
  }
}