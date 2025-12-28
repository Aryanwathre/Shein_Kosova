import 'ProductModel.dart';

class SearchResponseModel {
  final List<ProductModel> content;
  final Pageable pageable;
  final int totalPages;
  final int totalElements;
  final bool last;
  final int size;
  final int number;
  final Sort sort;
  final int numberOfElements;
  final bool first;
  final bool empty;

  SearchResponseModel({
    required this.content,
    required this.pageable,
    required this.totalPages,
    required this.totalElements,
    required this.last,
    required this.size,
    required this.number,
    required this.sort,
    required this.numberOfElements,
    required this.first,
    required this.empty,
  });

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    return SearchResponseModel(
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => ProductModel.fromJson(item))
          .toList() ??
          [],
      pageable: Pageable.fromJson(json['pageable'] ?? {}),
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      last: json['last'] ?? false,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
      sort: Sort.fromJson(json['sort'] ?? {}),
      numberOfElements: json['numberOfElements'] ?? 0,
      first: json['first'] ?? false,
      empty: json['empty'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content.map((item) => item.toJson()).toList(),
    'pageable': pageable.toJson(),
    'totalPages': totalPages,
    'totalElements': totalElements,
    'last': last,
    'size': size,
    'number': number,
    'sort': sort.toJson(),
    'numberOfElements': numberOfElements,
    'first': first,
    'empty': empty,
  };
}

class Pageable {
  final int pageNumber;
  final int pageSize;
  final Sort sort;
  final int offset;
  final bool paged;
  final bool unpaged;

  Pageable({
    required this.pageNumber,
    required this.pageSize,
    required this.sort,
    required this.offset,
    required this.paged,
    required this.unpaged,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      pageNumber: json['pageNumber'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      sort: Sort.fromJson(json['sort'] ?? {}),
      offset: json['offset'] ?? 0,
      paged: json['paged'] ?? false,
      unpaged: json['unpaged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'pageSize': pageSize,
    'sort': sort.toJson(),
    'offset': offset,
    'paged': paged,
    'unpaged': unpaged,
  };
}

class Sort {
  final bool sorted;
  final bool empty;
  final bool unsorted;

  Sort({
    required this.sorted,
    required this.empty,
    required this.unsorted,
  });

  factory Sort.fromJson(Map<String, dynamic> json) {
    return Sort(
      sorted: json['sorted'] ?? false,
      empty: json['empty'] ?? false,
      unsorted: json['unsorted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'sorted': sorted,
    'empty': empty,
    'unsorted': unsorted,
  };
}
