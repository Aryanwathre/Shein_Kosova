
class CartItem {
  final String id;
  final int productId; 
  final String name;
  final String image;
  final double price;
  final String size;
  final String? color;
  int quantity;
  final double subtotal;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.size,
    this.color,
    required this.quantity,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['cartItemId']?.toString() ?? '',
      productId: json['productId'] is int 
          ? json['productId'] 
          : int.tryParse(json['productId']?.toString() ?? '0') ?? 0,
      name: json['productName'] ?? 'Unnamed Product',
      image: json['mainImageUrl'] ?? '',
      price: (json['price'] as num? ?? 0.0).toDouble(),
      size: json['size'] ?? '',
      color: json['color'],
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      subtotal: (json['subtotal'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartItemId': id,
      'productId': productId,
      'productName': name,
      'mainImageUrl': image,
      'price': price,
      'size' : size,
      'color': color,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  @override
  String toString() {
    return 'CartItem(id: $id, name: $name, quantity: $quantity, price: $price, size: $size, color: $color)';
  }
}
