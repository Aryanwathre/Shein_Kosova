/// A brand/store registered in the admin panel.
class StoreModel {
  final String id;
  final String name;
  final String? description;
  final String? logo;

  StoreModel({required this.id, required this.name, this.description, this.logo});

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      logo: json['logo']?.toString(),
    );
  }
}

/// Filter options for a brand page, built from that brand's products.
class StoreFilters {
  final List<String> sizes;
  final List<String> colors;
  final double? minPrice;
  final double? maxPrice;

  const StoreFilters({
    this.sizes = const [],
    this.colors = const [],
    this.minPrice,
    this.maxPrice,
  });

  factory StoreFilters.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic v) =>
        v is List ? v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() : [];
    double? num(dynamic v) => v == null ? null : double.tryParse(v.toString());
    return StoreFilters(
      sizes: list(json['sizes']),
      colors: list(json['colors']),
      minPrice: num(json['minPrice']),
      maxPrice: num(json['maxPrice']),
    );
  }
}
