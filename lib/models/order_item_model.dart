class OrderItemModel {
  final String productId;
  final String productName;
  final String productMainImageUrl;
  final double price;
  final int quantity;
  final String size;
  final String color;
  final String orderItemId;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productMainImageUrl,
    required this.price,
    required this.quantity,
    required this.size,
    required this.color,
    required this.orderItemId,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json["productId"]?.toString() ?? "",
      productName: json["productName"] ?? "",
      productMainImageUrl: json["productMainImageUrl"] ?? "",
      price: (json["price"] ?? 0).toDouble(),
      quantity: json["quantity"] ?? 0,
      size: json["size"]?.toString() ?? "",
      color: json["color"]?.toString() ?? "",
      orderItemId: json["order_item_id"]?.toString() ?? "",
    );
  }
}
