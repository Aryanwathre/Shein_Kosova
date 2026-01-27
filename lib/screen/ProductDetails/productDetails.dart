import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';
import '../../models/ProductModel.dart';
import '../../provider/product_details_provider.dart';
import '../../provider/cart_provider.dart';
import '../../widgets/FullScreenImageViewer.dart';
import '../../widgets/RatingReviewsWidget.dart';
import '../../widgets/SearchBar.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel? product;
  final String? productId;

  const ProductDetailsScreen({super.key, this.product, this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  late ProductProvider _productProvider;
  final TextEditingController _colorController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

      productProvider.isLoading = true;

      try {
        if (widget.product != null) {
          if (widget.product!.detailImages.isEmpty) {
            await productProvider.getProductByID(widget.product!.id);
          } else {
            productProvider.setProduct(widget.product!);
          }
          
          if (productProvider.product?.colors != null) {
            _colorController.text = productProvider.product!.colors!;
          }

          await wishlistProvider.loadWishlist();

          await productProvider.getProductByCode(
            int.parse(widget.product!.category.id),
            widget.product!.id,
          );
        } else if (widget.productId != null) {
          await productProvider.getProductByID(int.parse(widget.productId!));
          if (productProvider.product != null) {
             if (productProvider.product?.colors != null) {
               _colorController.text = productProvider.product!.colors!;
             }
             await productProvider.getProductByCode(
               int.parse(productProvider.product!.category.id),
               productProvider.product!.id,
             );
          }
          await wishlistProvider.loadWishlist();
        }
      } finally {
        if (mounted) {
          productProvider.isLoading = false;
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productProvider = Provider.of<ProductProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _productProvider.resetDetails();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final product = provider.product;

        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text("Product not found"),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, product),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _imageCarousel(context, product.detailImages),
                _priceSection(context, product),
                _productTitleSection(context, product),
                _colorSection(context, product),
                _variantOptions(context, product, provider),
                _sizeOptions(context, product.sizes ?? []),
                _quantitySelector(context),
                _descriptionSection(context, product.description),
                const Divider(color: Color(0xFFEEEEEE), thickness: 5),
                _collapsibleRatingsReviews(context, product),
                const Divider(color: Color(0xFFEEEEEE), thickness: 5),
                _youMayAlsoLikeSection(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomNavigationBar: _bottomActionBar(context, product),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ProductModel product) {
    final cartProvider = context.watch<CartProvider>();
    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () => context.pop(),
            ),
            Expanded(child: buildSearchBar(context)),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined), onPressed: () {
                    context.go('/shop?index=2');
                    },
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        cartProvider.itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  final box = ctx.findRenderObject() as RenderBox;

                  final String productUrl =
                      'https://s-kosova.com/products/${product.id}';

                  Share.share(
                    'Check out this product on Shein Kosova: ${product.name}\n\n$productUrl',
                    sharePositionOrigin:
                    box.localToGlobal(Offset.zero) & box.size,
                  );
                },
              ),
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
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    child: CachedNetworkImage(
                      imageUrl: images[index],
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

  Widget _colorSection(BuildContext context, ProductModel product) {
    final bool isMulticolor = product.colors?.toLowerCase() == 'multicolor';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Color",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (isMulticolor)
            TextField(
              controller: _colorController,
              decoration: InputDecoration(
                hintText: "Enter color",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            )
          else
            Text(
              product.colors ?? "N/A",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
        ],
      ),
    );
  }

  Widget _variantOptions(BuildContext context, ProductModel product, ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.variants != null && product.variants!.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: product.variants!.length,
                itemBuilder: (context, index) {
                  final variant = product.variants![index];
                  final isSelected = provider.product?.id == variant.id;

                  return GestureDetector(
                    onTap: () {
                      provider.fetchVariantById(variant.id);
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Container(
                        width: 80,
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: variant.mainImageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _sizeOptions(BuildContext context, List<String> sizes) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              visible: sizes.isNotEmpty,
              child: const Text(
                "Select Size",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes.map((size) => ChoiceChip(
                label: Text(size),
                selected: provider.selectedSize == size,
                onSelected: (_) => provider.selectSize(size),
              )).toList(),
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
              if (_quantity > 1) {
                setState(() => _quantity--);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: _quantity > 1 ? Colors.white : Colors.grey[300],
              ),
              child: Icon(
                Icons.remove,
                color: _quantity > 1 ? Colors.black : Colors.grey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _quantity.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _quantity++);
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

  Widget _collapsibleRatingsReviews(BuildContext context, ProductModel product) {
    return RatingsReviewsWidget(
      averageRating: product.averageRating,
      reviews: product.reviews,
      voidCallback: () => _openAddReviewSheet(context, product.id.toString()),
    );
  }

  void _openAddReviewSheet(BuildContext context, String productID) {
    double selectedRating = 0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Add Review",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setSheetState(() => selectedRating = index + 1.0);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: "Write your review...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final authProvider = context.read<AuthProvider>();
                      if (authProvider.state != AuthState.authenticated) {
                        await showLoginPrompt(context);
                        if (authProvider.state != AuthState.authenticated) return;
                      }

                      if (selectedRating == 0 || commentController.text.trim().isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please add rating & comment")),
                          );
                        }
                        return;
                      }
                      
                      if (context.mounted) {
                        await context.read<ProductProvider>().submitReview(
                          productId: productID,
                          rating: selectedRating,
                          comment: commentController.text,
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text("Submit Review"),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _bottomActionBar(BuildContext context, ProductModel product) {
    final cartProvider = context.watch<CartProvider>();
    final isInCart = cartProvider.isProductInCart(product.id);

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
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
            Expanded(
              flex: 1,
              child: Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, _) {
                  final isWishlisted = wishlistProvider.isProductInWishlist(product.id);

                  return IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border_outlined,
                      color: isWishlisted ? Colors.red : Colors.black87,
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
            ),
            Expanded(
              flex: 5,
              child: ElevatedButton(
                onPressed: () async {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.state != AuthState.authenticated) {
                    await showLoginPrompt(context);
                    if (authProvider.state != AuthState.authenticated) return;
                  }

                  final provider = context.read<ProductProvider>();

                  if (isInCart) {
                    context.go('/shop?index=2');
                  } else {
                    if (provider.selectedSize == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a size!')),
                        );
                      }
                      return;
                    }

                    final bool isMulticolor = product.colors?.toLowerCase() == 'multicolor';
                    final colorInput = isMulticolor ? _colorController.text.trim() : product.colors ?? '';

                    if (isMulticolor && (colorInput.isEmpty || colorInput.toLowerCase() == 'multicolor')) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please specify a color for this product!')),
                        );
                      }
                      return;
                    }

                    final success = await cartProvider.addToCart(
                      productId: product.id,
                      quantity: _quantity,
                      sizes: provider.selectedSize!,
                      color: colorInput,
                    );

                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to Cart!')),
                      );
                    }
                  }
                },
                child: Text(isInCart ? "Go to Bag" : "Add to Cart"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceSection(BuildContext context, ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: styledPrice(product.price),
    );
  }

  Widget _productTitleSection(BuildContext context, ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 2,
        overflow: TextOverflow.fade,
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
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
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6),
                              child: Text(
                                "${entry.key}:",
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6),
                              child: Text(
                                entry.value,
                                style: const TextStyle(color: Colors.black54),
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

        if (productList.isEmpty) {
          return const SizedBox.shrink();
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
                      context.push('/products/${product.id}', extra: product);
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
