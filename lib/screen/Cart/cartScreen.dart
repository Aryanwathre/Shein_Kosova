import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/CartItemModel.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
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
        ),
        body: Selector<CartProvider, CartState>(
          selector: (_, provider) => provider.state,
          builder: (context, state, child) {
            if (state == CartState.loading) {
              return ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ShimmerWidget.rectangular(height: 100),
                ),
              );
            }
            if (state == CartState.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load cart',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Selector<CartProvider, String?>(
                      selector: (_, provider) => provider.errorMessage,
                      builder: (context, error, _) => Text(
                        error ?? "An error occurred while loading your cart",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<CartProvider>().loadCart(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            return const _CartItemsList();
          },
        ),
        bottomNavigationBar: Selector<CartProvider, bool>(
          selector: (_, provider) => provider.items.isEmpty || provider.state == CartState.loading,
          builder: (context, hide, child) {
            if (hide) return const SizedBox.shrink();
            return const _BottomCheckoutBar();
          },
        ),
      ),
    );
  }
}

class _CartItemsList extends StatelessWidget {
  const _CartItemsList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<CartProvider>().loadCart(showLoading: false),
      child: Selector<CartProvider, List<CartItem>>(
        selector: (_, provider) => provider.items,
        builder: (context, items, child) {
          if (items.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 500,
                child: Center(
                  child: Text(
                    "Your cart is empty",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _CartItemTile(item: items[index]);
            },
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  Future<void> _showDeleteConfirmation(BuildContext context, String cartItemId) async {
    final provider = context.read<CartProvider>();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Item"),
        content: Text("Are you sure you want to remove '${item.name}' from your cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              provider.removeFromCart(cartItemId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CartProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.image.isEmpty
                  ? Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.image,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerWidget.rectangular(height: 80, width: 80),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(context, item.id.toString()),
                        child: const Icon(Icons.delete_outline, size: 22),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Size: ${item.size}"),
                  if (item.color != null && item.color!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text("Color: ${item.color}"),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      styledPrice(item.price),
                      const Spacer(),
                      InputQty.int(
                        maxVal: 40,
                        minVal: 0,
                        initVal: item.quantity,
                        steps: 1,
                        qtyFormProps: const QtyFormProps(enableTyping: false),
                        decoration: QtyDecorationProps(
                          minusBtn: Icon(Icons.remove, color: AppColors.primary),
                          plusBtn: Icon(Icons.add, color: AppColors.primary),
                        ),
                        onQtyChanged: (value) {
                          if (value == null) return;
                          if (value <= 0) {
                            _showDeleteConfirmation(context, item.id.toString());
                          } else {
                            provider.updateQuantity(item.id.toString(), value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCheckoutBar extends StatelessWidget {
  const _BottomCheckoutBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 150,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Selector<CartProvider, int>(
                  selector: (_, provider) => provider.itemCount,
                  builder: (context, count, _) => Text(
                    "Total ($count items):",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Selector<CartProvider, double>(
                  selector: (_, provider) => provider.totalAmount,
                  builder: (context, total, _) => styledPrice(total, color: Colors.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: Selector<CartProvider, bool>(
              selector: (_, provider) => provider.isUpdating,
              builder: (context, isUpdating, child) {
                return ElevatedButton(
                  onPressed: isUpdating ? null : () => context.push('/checkout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
