import 'dart:convert';

class CartItem {
  final String id;        // This will store the unique 'cartItemId' as a String
  final int productId;
  final String name;      // This will store 'productName'
  final String image;     // This will store 'mainImageUrl'
  final double price;
  int quantity;
  final double subtotal;  // Added subtotal as it's provided by the API

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  /// The fromJson factory is the most critical part.
  /// It now maps the keys from your API response directly to the model's fields.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      // Use the actual keys from your API response
      id: json['cartItemId']?.toString() ?? '', // Convert int to String for the ID
      productId: json['productId'] ?? 0,
      name: json['productName'] ?? 'Unnamed Product', // Key is 'productName'
      image: json['mainImageUrl'] ?? '',           // Key is 'mainImageUrl'
      price: (json['price'] as num? ?? 0.0).toDouble(),
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      subtotal: (json['subtotal'] as num? ?? 0.0).toDouble(),
    );
  }

  /// The toJson method can be updated for consistency, though it's less critical for display.
  Map<String, dynamic> toJson() {
    return {
      'cartItemId': id,
      'productId': productId,
      'productName': name,
      'mainImageUrl': image,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  @override
  String toString() {
    return 'CartItem(id: $id, name: $name, quantity: $quantity, price: $price)';
  }
}
