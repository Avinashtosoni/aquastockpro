import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    String? id,
    required this.name,
    this.description,
    this.iconName,
    this.colorHex,
    this.sortOrder = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
      'sort_order': sortOrder,
      'is_active': isActive,  // Supabase expects boolean, not 1/0
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconName: map['icon_name'] as String?,
      colorHex: map['color_hex'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Category allCategory = Category(
    id: 'all',
    name: 'All',
    iconName: 'grid',
    sortOrder: -1,
  );
}
