class BannerModel {
  final int id;
  final String imageUrl;
  final String redirectUrl;
  final int displayOrder;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.redirectUrl,
    required this.displayOrder,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      redirectUrl: json['redirectUrl'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
    );
  }
}
