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
      wishlistItemId: json['wishlistItemId'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      mainImageUrl: json['mainImageUrl'] as String,
    );
  }
}
