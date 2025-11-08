import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/cart_provider.dart';
import '../../models/CartItemModel.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch cart data from the API as soon as the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Your Cart"),
          // actions: [
          //   // The clear cart button, which only shows if the cart is not empty
          //   Consumer<CartProvider>(
          //     builder: (context, cart, child) {
          //       if (cart.items.isEmpty || cart.state == CartState.loading) {
          //         return const SizedBox.shrink(); // Hide button if cart is empty or loading
          //       }
          //       return IconButton(
          //         icon: const Icon(Icons.delete_forever),
          //         tooltip: "Clear Cart",
          //         // Disable button while an update is in progress
          //         onPressed: cart.isUpdating
          //             ? null
          //             : () async {
          //           // Show a confirmation dialog before clearing
          //           final confirm = await showDialog<bool>(
          //             context: context,
          //             builder: (ctx) => AlertDialog(
          //               title: const Text('Clear Cart'),
          //               content: const Text(
          //                   'Are you sure you want to remove all items from your cart?'),
          //               actions: [
          //                 TextButton(
          //                   onPressed: () => Navigator.of(ctx).pop(false),
          //                   child: const Text('Cancel'),
          //                 ),
          //                 TextButton(
          //                   onPressed: () => Navigator.of(ctx).pop(true),
          //                   child: const Text('Clear',
          //                       style: TextStyle(color: Colors.red)),
          //                 ),
          //               ],
          //             ),
          //           );
          //
          //           if (confirm == true) {
          //             await Provider.of<CartProvider>(context, listen: false)
          //                 .clearCart();
          //           }
          //         },
          //       );
          //     },
          //   ),
          // ],
        ),
        // The body of the screen reacts to the provider's state
        body: Consumer<CartProvider>(
          builder: (context, cart, child) {
            switch (cart.state) {
              case CartState.loading:
                return const Center(child: CircularProgressIndicator());
              case CartState.error:
                return Center(
                    child: Text(cart.errorMessage ?? "An error occurred."));
              case CartState.loaded:
              case CartState.updating: // Show the list even while updating
                if (cart.items.isEmpty) {
                  return const Center(
                    child: Text(
                      "Your cart is empty",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  );
                }
                // Display the list of cart items
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90), // Space for bottom bar
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(context, item, cart);
                  },
                );
              default:
                return const Center(child: Text("Welcome to your cart!"));
            }
          },
        ),
        // The bottom checkout bar, which only shows if the cart is not empty
        bottomNavigationBar: Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.items.isEmpty || cart.state == CartState.loading) {
              return const SizedBox.shrink();
            }
            return _buildBottomCheckoutBar(cart);
          },
        ),
      ),
    );
  }

  /// Builds a single cart item card with improved layout and controls.
  Widget _buildCartItem(
      BuildContext context, CartItem item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🖼 Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 40),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // 📄 Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "€${item.price.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                // ➕➖ Quantity + 🗑 Remove

              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: cartProvider.isUpdating
                      ? null
                      : () => cartProvider.decreaseQuantity(item.id),
                ),

                Text(
                  item.quantity.toString(),
                  style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon:
                  const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: cartProvider.isUpdating
                      ? null
                      : () => cartProvider.increaseQuantity(item.id),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  tooltip: "Remove from cart",
                  onPressed: cartProvider.isUpdating
                      ? null
                      : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Remove Item"),
                        content: const Text(
                            "Are you sure you want to remove this product from your cart?"),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text(
                              "Remove",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await cartProvider.removeFromCart(int.parse(item.id));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Item removed from cart')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  /// Builds the bottom checkout bar with total amount and checkout button.
  Widget _buildBottomCheckoutBar(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total Amount
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total (${cartProvider.itemCount} items):",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                "€${cartProvider.totalAmount.toStringAsFixed(2)}",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Checkout Button
          ElevatedButton(
            onPressed: cartProvider.isUpdating
                ? null
                : () {
              // TODO: Implement checkout navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Proceeding to checkout...")),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Checkout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
