import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';
import 'package:shein_kosova/utils/responsive_helper.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product image fills all space above the info strip.
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                product.mainImageUrl.isEmpty
                    ? Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      )
                    : CachedNetworkImage(
                        imageUrl: product.mainImageUrl,
                        imageBuilder: (context, imageProvider) => Image(
                          image: ResizeImage(imageProvider, width: 600),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        placeholder: (context, url) => const ShimmerWidget.rectangular(height: double.infinity),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
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
                            color: Colors.white.withValues(alpha: 0.8),
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
              ],
            ),
          ),
          // Info strip: natural height, so the price is always visible.
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 11, tabletSize: 12),
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                _categoryLine(),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _priceRow(context)),
                    if (addToCart != null) _addToCartButton(context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryLine() {
    final categoryName = product.category.name;
    if (categoryName.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Flexible(
          child: Text(
            'in $categoryName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ),
        Icon(Icons.chevron_right, size: 12, color: Colors.grey[600]),
      ],
    );
  }

  /// Flat black price, unlike the shared [discountedPriceRow] helper which
  /// renders the primary-coloured split-decimal style used elsewhere.
  Widget _priceRow(BuildContext context) {
    final hasDiscount = product.salePrice > 0 && product.salePrice < product.price;
    final shownPrice = hasDiscount ? product.salePrice : product.price;
    final fontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 13, tabletSize: 14);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '${shownPrice.toStringAsFixed(2)}€',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${product.price.toStringAsFixed(2)}€',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize - 4,
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _addToCartButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.state != AuthState.authenticated) {
          await showLoginPrompt(context);
          if (authProvider.state != AuthState.authenticated) return;
        }
        addToCart!();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add_shopping_cart, size: 14, color: Colors.black),
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                child: SizedBox(
                  width: 100,
                  height: 120,
                  child: product.mainImageUrl.isEmpty
                      ? Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        )
                      : CachedNetworkImage(
                          imageUrl: product.mainImageUrl,
                          imageBuilder: (context, imageProvider) => Image(
                            image: ResizeImage(imageProvider, width: 300),
                            fit: BoxFit.cover,
                          ),
                          placeholder: (context, url) => const ShimmerWidget.rectangular(height: 120, width: 100),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          discountedPriceRow(product.price, product.salePrice),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                product.averageRating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Consumer<WishlistProvider>(
                                builder: (context, wishlistProvider, _) {
                                  final isWishlisted = wishlistProvider.isProductInWishlist(product.id);
                                  return IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                                      color: isWishlisted ? Colors.red : Colors.black54,
                                      size: 22,
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
                              if (addToCart != null) ...[
                                const SizedBox(width: 12),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.add_shopping_cart, size: 22),
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
      ),
    );
  }
}
