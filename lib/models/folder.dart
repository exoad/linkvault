import 'package:flutter/material.dart';

class FolderModel {
  const FolderModel({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.createdAt,
    required this.colorValue,
    required this.iconName,
    required this.isLocked,
    this.bookmarkCount = 0,
    this.hasPin = false,
  });

  final String id;
  final String name;
  final bool isSystem;
  final DateTime createdAt;
  final int colorValue;
  final String iconName;
  final bool isLocked;
  final bool hasPin;
  final int bookmarkCount;

  static const unfiledName = 'Unfiled';
  static const defaultIconName = 'folder';
  static const defaultColorValue = 0xFF6750A4;

  Color get color => Color(colorValue);

  bool get requiresUnlock => isLocked && hasPin;
}
