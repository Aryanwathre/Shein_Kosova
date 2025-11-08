// screens/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/search_provider.dart';
import '../../provider/wishListProvider.dart';
import '../../widgets/ProductCard.dart';
import '../ProductDetails/productDetails.dart';

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
            return const Center(child: CircularProgressIndicator());
          }
          return Consumer<WishlistProvider>(
            builder: (context, provider, _) {
              final wishlist = provider.wishlistItems;
              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: wishlist.length,
                itemBuilder: (context, index) {
                  final productName = wishlist[index].productName;
                  final product = Provider.of<SearchProvider>(context, listen: false)
                      .searchResults
                      .firstWhere((prod) => prod.name == productName);

                  return ProductCard(
                    context: context,
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(product: product),
                        ),
                      );
                    },
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
