import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';
import 'login_prompt_sheet.dart';

class ProductCard extends StatelessWidget {
  final VoidCallback onTap;
  final ProductModel product;
  final BuildContext context;
  final VoidCallback? addToCart;

  const ProductCard({
    super.key,
    required this.onTap,
    required this.product,
    required this.context,
    this.addToCart,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 0.72, // Slightly taller image area
                    child: CachedNetworkImage(
                      imageUrl: product.mainImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerWidget.rectangular(height: double.infinity),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Wishlist Icon
                Positioned(
                  top: 6,
                  right: 6,
                  child: Consumer<WishlistProvider>(
                    builder: (context, wishlistProvider, _) {
                      final isWishlisted = wishlistProvider.isProductInWishlist(product.id);
                      return GestureDetector(
                        onTap: () async {
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.state != AuthState.authenticated) {
                            await showLoginPrompt(context);
                            if (authProvider.state != AuthState.authenticated) return;
                          }
                          if (isWishlisted) {
                            wishlistProvider.removeProductFromWishlist(product.id);
                          } else {
                            wishlistProvider.addToWishlist(product.id);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? Colors.red : Colors.black54,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Add to Cart Icon
                if (addToCart != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.state != AuthState.authenticated) {
                          await showLoginPrompt(context);
                          if (authProvider.state != AuthState.authenticated) return;
                        }
                        addToCart!();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                          ],
                        ),
                        child: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.black87),
                      ),
                    ),
                  ),
              ],
            ),
            // Text Details
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 2),
                  styledPrice(product.price, fontSize: 14),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 10, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        product.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
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

class ProductListCard extends StatelessWidget {
  final VoidCallback onTap;
  final ProductModel product;
  final BuildContext context;
  final VoidCallback? addToCart;

  const ProductListCard({
    super.key,
    required this.onTap,
    required this.product,
    required this.context,
    this.addToCart,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: CachedNetworkImage(
                imageUrl: product.mainImageUrl,
                height: 100,
                width: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerWidget.rectangular(height: 100, width: 80),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  width: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    styledPrice(product.price),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              product.averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Consumer<WishlistProvider>(
                              builder: (context, wishlistProvider, _) {
                                final isWishlisted = wishlistProvider.isProductInWishlist(product.id);
                                return IconButton(
                                  icon: Icon(
                                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                                    color: isWishlisted ? Colors.red : Colors.black54,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final authProvider = context.read<AuthProvider>();
                                    if (authProvider.state != AuthState.authenticated) {
                                      await showLoginPrompt(context);
                                      if (authProvider.state != AuthState.authenticated) return;
                                    }
                                    if (isWishlisted) {
                                      wishlistProvider.removeProductFromWishlist(product.id);
                                    } else {
                                      wishlistProvider.addToWishlist(product.id);
                                    }
                                  },
                                );
                              },
                            ),
                            if (addToCart != null)
                              IconButton(
                                icon: const Icon(Icons.add_shopping_cart, size: 20),
                                onPressed: () async {
                                  final authProvider = context.read<AuthProvider>();
                                  if (authProvider.state != AuthState.authenticated) {
                                    await showLoginPrompt(context);
                                    if (authProvider.state != AuthState.authenticated) return;
                                  }
                                  addToCart!();
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
