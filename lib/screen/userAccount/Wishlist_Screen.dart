import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/product_details_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wishlist")),
      body: FutureBuilder(
        future: Provider.of<WishlistProvider>(context, listen: false).loadWishlist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.56,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ShimmerWidget.rectangular(height: 250),
            );
          }
          return Consumer<WishlistProvider>(
            builder: (context, provider, _) {
              final wishlist = provider.wishlistItems;
              if (wishlist.isEmpty) {
                return const Center(child: Text("Your wishlist is empty"));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.56,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: wishlist.length,
                itemBuilder: (context, index) {
                  final item = wishlist[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        final productProvider = context.read<ProductProvider>();
                        productProvider.isLoading = true;
                        context.push('/products/${item.productId}');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: AspectRatio(
                                  aspectRatio: 0.75,
                                  child: CachedNetworkImage(
                                    imageUrl: item.mainImageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const ShimmerWidget.rectangular(height: double.infinity),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 5,
                                top: 5,
                                child: Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                                    onPressed: () {
                                      provider.removeProductFromWishlist(item.productId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Removed from Wishlist"),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
