class BannerModel {
  final int id;
  final String webImageUrl;
  final String mobileImageUrl;
  final String redirectUrl;
  final int displayOrder;
  final bool isLight; // Added to handle adaptive header icons

  BannerModel({
    required this.id,
    required this.webImageUrl,
    required this.mobileImageUrl,
    required this.redirectUrl,
    required this.displayOrder,
    this.isLight = false,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      webImageUrl: json['webImageUrl'] ?? '',
      mobileImageUrl: json['mobileImageUrl'] ?? '',
      redirectUrl: json['redirectUrl'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      isLight: json['isLight'] ?? false,
    );
  }
}
