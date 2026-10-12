class ReviewModel {
  final String id;
  final String reviewerName;
  final String comment;
  final double rating;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.reviewerName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      reviewerName: json['reviewer_name'] ?? '',
      comment: json['comment'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_name': reviewerName,
      'comment': comment,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PaginatedReviewResponse {
  final List<ReviewModel> reviews;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool isLastPage;

  PaginatedReviewResponse({
    required this.reviews,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.isLastPage,
  });

  factory PaginatedReviewResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedReviewResponse(
      reviews: (json['content'] as List<dynamic>? ?? [])
          .map((review) => ReviewModel.fromJson(review))
          .toList(),

      page: json['pageable']?['pageNumber'] ?? 0,
      size: json['pageable']?['pageSize'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
      totalElements: json['totalElements'] ?? 0,
      isLastPage: json['last'] ?? true,
    );
  }
}
