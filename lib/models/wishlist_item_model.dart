class WishlistItemModel {
  final int wishlistItemId;
  final int productId;
  final String productName;
  final String mainImageUrl;

  WishlistItemModel({
    required this.wishlistItemId,
    required this.productId,
    required this.productName,
    required this.mainImageUrl,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      wishlistItemId: int.tryParse(json['wishlistItemId'].toString()) ?? 0,
      productId: int.tryParse(json['productId'].toString()) ?? 0,
      productName: json['productName'] ?? '',
      mainImageUrl: json['mainImageUrl'] ?? '',
    );
  }
}
