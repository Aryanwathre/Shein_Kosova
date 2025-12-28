// screens/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../provider/wishlist_provider.dart';

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


                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GestureDetector(
                      onTap: (){
                        context.push('/product/${wishlist[index].productId}');
                      },
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Image.network(
                                wishlist[index].mainImageUrl,
                                fit: BoxFit.contain,
                                height: MediaQuery.of(context).size.width * 0.56,
                              ),
                              Positioned(
                                right: 5,
                                top: 5,
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Consumer<WishlistProvider>(
                                    builder: (context, wishlistProvider, _) {
                                      final item = wishlist[index];

                                      return IconButton(
                                        icon: const Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          wishlistProvider.removeProductFromWishlist(item.productId);

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Removed from Wishlist"),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),

                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wishlist[index].productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
