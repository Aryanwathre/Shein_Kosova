import 'package:shein_kosova/models/ReviewModel.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/utils/size_utils.dart';

class ProductModel {
  final int id;
  final String code;
  final String name;
  final String? brand;
  final String description;
  final double price;
  final double salePrice;
  final double averageRating;
  final bool enabled;
  final CategoryModel category;
  final String mainImageUrl;
  final List<String> detailImages;
  final String? colors;

  /// Selectable colours ("Bardh", "Zi"...). From the API's `colors` list, or
  /// the single `color` split on commas for older products.
  final List<String> colorList;
  final List<ColorOption> colorOptions;
  final List<String>? sizes;
  final List<ProductVariant>? variants;
  final String tag;
  final List<ReviewModel>? reviews;

  ProductModel({
    required this.id,
    required this.code,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    this.salePrice = 0.0,
    required this.averageRating,
    required this.enabled,
    required this.category,
    required this.mainImageUrl,
    required this.detailImages,
    this.colors,
    this.colorList = const [],
    this.colorOptions = const [],
    this.sizes,
    this.variants,
    this.tag = '',
    this.reviews,
  });

  static List<String> _parseColorList(Map<String, dynamic> json) {
    final raw = json['colors'];
    final List<String> list = raw is List
        ? raw.map((e) => e.toString())
            .toList()
        : (json['color']?.toString() ?? '').split(',');
    final seen = <String>{};
    return list
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty && seen.add(c.toLowerCase()))
        .toList();
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Sanitize detail images: remove empty or whitespace-only strings
    final List<String> rawDetailImages = List<String>.from(json['detailImages'] ?? []);
    final List<String> sanitizedDetailImages = rawDetailImages
        .where((img) => img.trim().isNotEmpty)
        .toList();

    // Sanitize and sort sizes
    List<String> rawSizes = json['sizes'] != null ? List<String>.from(json['sizes']) : [];
    List<String> cleanedSizes = rawSizes
        .where((size) => size.trim().isNotEmpty)
        .map((size) => size.trim())
        .toList();
    List<String> sortedSizes = SizeUtils.sortSizes(cleanedSizes);

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
      salePrice: (json['sale_price'] is String)
          ? double.tryParse(json['sale_price']) ?? 0.0
          : (json['sale_price'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] is String)
          ? double.tryParse(json['averageRating']) ?? 0.0
          : (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      enabled: json['enabled'] ?? false,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : CategoryModel(id: '', name: 'Unknown'),
      mainImageUrl: (json['mainImageUrl'] as String?)?.trim() ?? '',
      detailImages: sanitizedDetailImages,
      colors: json['color'],
      colorList: _parseColorList(json),
      colorOptions: json['colorOptions'] is List
          ? (json['colorOptions'] as List)
              .whereType<Map>()
              .map((c) => ColorOption.fromJson(Map<String, dynamic>.from(c)))
              .where((c) => c.name.isNotEmpty)
              .toList()
          : [],
      sizes: sortedSizes,
      variants: json['variants'] != null
          ? (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v))
          .toList()
          : [],
      tag: json['tag'] ?? '',
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
          .map((v) => ReviewModel.fromJson(v))
          .toList()
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
      'sale_price': salePrice,
      'averageRating': averageRating,
      'enabled': enabled,
      'category': category.toJson(),
      'mainImageUrl': mainImageUrl,
      'detailImages': detailImages,
      'colors': colors,
      'colorOptions': colorOptions.map((c) => c.toJson()).toList(),
      'sizes': sizes ?? [],
      'variants': variants?.map((v) => v.toJson()).toList() ?? [],
      'tag' : tag,
    };
  }

  factory ProductModel.object() {
    return ProductModel(
      id: 0,
      code: '',
      name: '',
      brand: '',
      description: '',
      price: 0.0,
      averageRating: 0.0,
      enabled: false,
      category: CategoryModel.object(),
      mainImageUrl: '',
      detailImages: [],
      colors: '',
      sizes: [],
      variants: [],
      tag: '',
    );
  }
}

class ProductVariant {
  final int id;
  final String name;
  final double price;
  final double averageRating;
  final List<String>? sizes;
  final bool enabled;
  final CategoryModel category;
  final String mainImageUrl;
  final double salePrice;

  ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.averageRating,
    this.sizes,
    required this.enabled,
    required this.category,
    required this.mainImageUrl,
    required this.salePrice,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    List<String> rawSizes = json['sizes'] != null ? List<String>.from(json['sizes']) : [];
    List<String> cleanedSizes = rawSizes
        .where((size) => size.trim().isNotEmpty)
        .map((size) => size.trim())
        .toList();
    List<String> sortedSizes = SizeUtils.sortSizes(cleanedSizes);

    return ProductVariant(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : (json['id'] ?? 0),
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      sizes: sortedSizes,
      enabled: json['enabled'] ?? false,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : CategoryModel(id: '', name: 'Unknown'),
      mainImageUrl: (json['mainImageUrl'] as String?)?.trim() ?? '',
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'averageRating': averageRating,
      'sizes': sizes ?? [],
      'enabled': enabled,
      'category': category.toJson(),
      'mainImageUrl': mainImageUrl,
      'sale_price': salePrice,
    };
  }
}

// A colour variant with its swatch image (e.g. {name: "Black", image: "https://..."}).
class ColorOption {
  final String name;
  final String image;

  ColorOption({required this.name, required this.image});

  factory ColorOption.fromJson(Map<String, dynamic> json) => ColorOption(
        name: (json['name'] ?? '').toString().trim(),
        image: (json['image'] ?? '').toString().trim(),
      );

  Map<String, dynamic> toJson() => {'name': name, 'image': image};
}
