import 'Category.dart';

class ProductModel {
  final int id;
  final String code;
  final String name;
  final String? brand;
  final String description;
  final double price;
  final double averageRating;
  final bool enabled;
  final Category category;
  final String mainImageUrl;
  final List<String> detailImages;
  final List<String>? colors;
  final List<String>? sizes;

  ProductModel({
    required this.id,
    required this.code,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    required this.averageRating,
    required this.enabled,
    required this.category,
    required this.mainImageUrl,
    required this.detailImages,
    this.colors,
    this.sizes,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : (json['id'] ?? 0),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'], // nullable
      description: json['description'] ?? '',
      price: (json['price'] is String)
          ? double.tryParse(json['price']) ?? 0.0
          : (json['price'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] is String)
          ? double.tryParse(json['averageRating']) ?? 0.0
          : (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      enabled: json['enabled'] ?? false,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : Category(id: 0, name: 'Unknown'),
      mainImageUrl: json['mainImageUrl'] ?? '',
      detailImages: List<String>.from(json['detailImages'] ?? []),
      colors: json['colors'] != null
          ? List<String>.from(json['colors'])
          : [],
      sizes: json['sizes'] != null
          ? List<String>.from(json['sizes'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'brand': brand,
      'description': description,
      'price': price,
      'averageRating': averageRating,
      'enabled': enabled,
      'category': category.toJson(),
      'mainImageUrl': mainImageUrl,
      'detailImages': detailImages,
      'colors': colors ?? [],
      'sizes': sizes ?? [],
    };
  }
}
