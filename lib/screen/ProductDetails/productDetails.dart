import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/wishListProvider.dart';
import 'package:shein_kosova/screen/OrderConfirmation/checkout_page.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import 'package:shein_kosova/widgets/bottomNavigationBar.dart';
import '../../models/ProductModel.dart';
import '../../provider/ProductDetailsProvider.dart';
import '../../provider/cart_provider.dart';
import '../../widgets/FullScreenImageViewer.dart';
import '../../widgets/RatingReviewsWidget.dart';
import '../../widgets/SearchBar.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int Quantity = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

      productProvider.setProduct(widget.product);
      wishlistProvider.loadWishlist();
      productProvider.getProductByCode(widget.product.category.id, widget.product.id);
    });
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: Provider.of<ProductProvider>(context),
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageCarousel(context, widget.product.detailImages),
              _priceSection(context),
              _productTitleSection(context),
              _sizeOptions(context, widget.product.sizes ?? []),
              _quantitySelector(context),
              _descriptionSection(context, widget.product.description ?? ''),
              Divider(color: Colors.grey[300], thickness: 5),
              _collapsibleRatingsReviews(),
              Divider(color: Colors.grey[300], thickness: 5),
              _youMayAlsoLikeSection(context),

              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: _bottomActionBar(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              buildSearchBar(context),

              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LandingPage(selectedIndex: 3),
                    ),
                  );
                },
                child: Icon(Icons.shopping_cart_outlined,
                ),
              ),


              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  // Share your product link here
                  // Example using share_plus package:
                  // Share.share('Check out this product: ${widget.product.url}');
                },
              ),
            ],
          ),
        ),
    );
  }

  Widget _imageCarousel(BuildContext context, List<String> images) {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    if (images.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
        ),
      );
    }

    final pageController = PageController(
      initialPage: provider.selectedImageIndex,
    );

    return Consumer<ProductProvider>(
      builder: (context, consumerProvider, _) => Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.59,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  onPageChanged: (index) => provider.changeImage(index),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageGallery(
                            images: images,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.05),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        // width: double.infinity,
                        // height: double.infinity,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${consumerProvider.selectedImageIndex + 1} / ${images.length}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Text(
                  provider.product?.brand ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 0),
                        blurRadius: 6,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  provider.changeImage(index);
                  pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: consumerProvider.selectedImageIndex == index
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      images[index],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorOptions(BuildContext context, List<String> colors) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    return Consumer<ProductProvider>(
      builder: (context, consumerProvider, _) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Color",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors
                  .map(
                    (color) => ChoiceChip(
                      label: Text(color),
                      selected: consumerProvider.selectedColor == color,
                      onSelected: (_) => provider.selectColor(color),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeOptions(BuildContext context, List<String> sizes) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    return Consumer<ProductProvider>(
      builder: (context, consumerProvider, _) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Size",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes
                  .map(
                    (size) => ChoiceChip(
                      label: Text(size),
                      selected: consumerProvider.selectedSize == size,
                      onSelected: (_) => provider.selectSize(size),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantitySelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Text(
            "Quantity:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              if (Quantity > 1) {
                setState(() {
                  Quantity--;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Quantity > 1 ? Colors.white : Colors.grey[300],
              ),
              child:
                 Icon(
                     Icons.remove,
                   color: (Quantity > 1) ? Colors.black : Colors.grey,
                 ),


            ),
          ),
          Padding(
         padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              Quantity.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                Quantity++;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _collapsibleRatingsReviews() {
    return RatingsReviewsWidget(
      averageRating: widget.product.averageRating ?? 0.0,
      reviews: [
        {'user': 'Aryan', 'rating': 5.0, 'comment': 'Excellent product!'},
        {'user': 'Priya', 'rating': 4.0, 'comment': 'Good quality but a bit pricey.'},
        {'user': 'Rahul', 'rating': 3.5, 'comment': 'Decent but could be improved.'},
      ],
    );
  }

  Widget _bottomActionBar(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isProductInCart(widget.product.id);
    print('isInCart: ${Provider.of<WishlistProvider>(context).isProductInWishlist(widget.product.id)}');

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ❤️ Wishlist Button (Reactive)
            Expanded(
              flex: 1,
              child: Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, _) {
                  final isWishlisted =
                  wishlistProvider.isProductInWishlist(widget.product.id);

                  return IconButton(
                    icon: Icon(
                      isWishlisted
                          ? Icons.favorite
                          : Icons.favorite_border_outlined,
                      color: isWishlisted ? Colors.red : Colors.black87,
                    ),
                    onPressed: () {
                      isWishlisted
                          ? wishlistProvider.removeProductFromWishlist(widget.product.id)
                          : wishlistProvider.addToWishlist(widget.product.id);
                    },
                  );
                },
              ),
            ),

            // 🛍️ Buy Now
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: const BorderSide(color: Colors.black87),
                ),
                onPressed: () {
                  // Future: Navigate to CheckoutPage
                },
                child: const Text(
                  "Buy Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // 🛒 Add to Cart / Go to Bag
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (isInCart) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LandingPage(selectedIndex: 2),
                      ),
                    );
                  } else {
                    final success = await cartProvider.addToCart(
                      productId: widget.product.id,
                      quantity: 1,
                    );

                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to Cart!')),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            cartProvider.errorMessage ?? 'Failed to add to cart',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  isInCart ? "Go to Bag" : "Add to Cart",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceSection(BuildContext context) {
    final price = widget.product.price.toStringAsFixed(2);
    final parts = price.split('.'); // Split into integer and decimal parts
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$integerPart.",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            TextSpan(
              text: "$decimalPart€",
              style: const TextStyle(
                fontSize: 14, // half of 24
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productTitleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        widget.product.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _descriptionSection(BuildContext context, String description) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GestureDetector(
        onTap: () => showDescriptionBottomSheet(context, description),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            Stack(
              children: [
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                Positioned(
                  right: 10,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white,
                        ],
                      ),

                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),


          ],
        ),
      ),
    );
  }

  void showDescriptionBottomSheet(BuildContext context, String description) {
    final Map<String, String> descriptionMap = {};

    for (var line in description.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(':');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join(':').trim();
        descriptionMap[key] = value;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Product Description",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Table content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: Colors.grey[300]!),
                      ),
                      children: descriptionMap.entries.map((entry) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 6),
                              child: Text(
                                "${entry.key}:",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 6),
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _youMayAlsoLikeSection(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final productList = productProvider.categoryProducts;

        if (productProvider.listState == ProductListState.loading) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (productProvider.listState == ProductListState.error) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              productProvider.listErrorMessage ?? "Something went wrong.",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (productList.isEmpty) {
          return const SizedBox.shrink(); // or show: Text("No similar products found")
        }

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "You May Also Like",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.5,
                ),
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  final product = productList[index];
                  return ProductCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                    context: context,
                    product: product,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

}
