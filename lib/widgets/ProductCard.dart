import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ProductModel.dart';
import '../provider/wishListProvider.dart';

Widget ProductCard({
  required VoidCallback onTap,
  required BuildContext context,
  required ProductModel product,
}) {
  final wishlistProvider = Provider.of<WishlistProvider>(context);
  final isInWishlist = wishlistProvider.isProductInWishlist(product.id);

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Image.network(
                product.mainImageUrl,
                fit: BoxFit.contain,
                height: MediaQuery.of(context).size.width * 0.566,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "NEW",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Positioned(
              //   right: 5,
              //   bottom: 5,
              //   child: Container(
              //     height: 40,
              //     width: 40,
              //     decoration: BoxDecoration(
              //       color: Colors.white.withOpacity(0.5),
              //       shape: BoxShape.circle,
              //     ),
              //     child: IconButton(
              //       icon: Icon(
              //         isInWishlist
              //             ? Icons.favorite
              //             : Icons.favorite_border,
              //         color: isInWishlist ? Colors.red : Colors.grey,
              //       ),
              //       onPressed: () {
              //         wishlistProvider.removeFromWishlist(product.id);
              //
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           SnackBar(
              //             content: Text(
              //               isInWishlist
              //                   ? "Removed from Wishlist"
              //                   : "Added to Wishlist",
              //             ),
              //             duration: const Duration(seconds: 1),
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  product.category.name,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  "€ ${product.price}",
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
