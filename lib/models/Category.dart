class Category {
  final int id;
  final String name;
  final String? categoryImage;

  Category({
    required this.id,
    required this.name,
    this.categoryImage,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categoryImage: json['categoryImage'],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "categoryImage": categoryImage,
  };
}

class PageableCategory {
  final int pageNumber;
  final int pageSize;

  PageableCategory({
    required this.pageNumber,
    required this.pageSize,
  });

  Map<String, dynamic> toJson() => {
    "pageNumber": pageNumber,
    "pageSize": pageSize,
  };

  factory PageableCategory.fromJson(Map<String, dynamic> json) {
    return PageableCategory(
        pageNumber: json['pageNumber'] ?? 0,
        pageSize: json['pageSize'] ?? 0
    );
  }
}


/// Wrapper model for paginated response
class CategoryResponse {
  final List<Category> content;
  final PageableCategory? pageable;
  final int totalPages;
  final int totalElements;
  final bool last;
  final bool first;
  final int size;
  final int number;

  CategoryResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.pageable,
    required this.last,
    required this.first,
    required this.size,
    required this.number,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      content: (json['content'] as List<dynamic>)
          .map((item) => Category.fromJson(item))
          .toList(),
      pageable: json['pageable'] != null
          ? PageableCategory.fromJson(json['pageable'])
          : null,
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      last: json['last'] ?? false,
      first: json['first'] ?? false,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
    );
  }
}
