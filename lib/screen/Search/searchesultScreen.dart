import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/provider/search_provider.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import 'package:shein_kosova/widgets/SearchBar.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

class SearchResultScreen extends StatefulWidget {
  final String? categoryId;
  final String? searchQuery;
  final String searchTitle;
  const SearchResultScreen({super.key, this.categoryId, this.searchQuery, required this.searchTitle});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _viewAsGrid = true;
  late SearchProvider searchProvider = Provider.of<SearchProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSearchResult();

      if (_scrollController.hasClients) {
        _scrollController.addListener(() {
          if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200) {
            searchProvider.search(page: (searchProvider.currentPage ?? 0) + 1);
          }
        });
      }
    });
  }

  void _initializeSearchResult() {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.search(query: widget.searchQuery, categoryId: widget.categoryId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchProvider.clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.08,
        automaticallyImplyLeading: false,
        actions: const [SizedBox.shrink()], // This hides the automatic endDrawer icon
        title: Row(
          children: [
            InkWell(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(child: buildProductSearchBar(context, widget.searchTitle)),
            const SizedBox(width: 8),
            InkWell(
              child: Icon(_viewAsGrid ? Icons.art_track_outlined : Icons.grid_view_outlined, size: 24),
              onTap: () => setState(() => _viewAsGrid = !_viewAsGrid),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                if (authProvider.state != AuthState.authenticated) {
                  await showLoginPrompt(context);
                  if (!mounted) return;
                  if (authProvider.state != AuthState.authenticated) return;
                }
                if (mounted) context.push('/wishlist');
              },
              child: const Icon(Icons.favorite_border_outlined, size: 24),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(45),
          child: _filterBar(),
        ),
      ),
      endDrawer: _filterDrawer(), // This opens from right to left
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            if (cartProvider.itemCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    cartProvider.itemCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onPressed: () async {
          final authProvider = context.read<AuthProvider>();
          if (authProvider.state != AuthState.authenticated) {
            await showLoginPrompt(context);
            if (!mounted) return;
            if (authProvider.state != AuthState.authenticated) return;
          }
          if (mounted) context.go('/shop?index=2');
        },
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _filterBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _topSortBar(),
          // _filterChipsBar(), // Removed for now, keeping for future use
        ],
      ),
    );
  }

  Widget _topSortBar() {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              _sortItem(
                label: 'Recommend',
                isSelected: provider.sortKey == 'relevance',
                hasDropdown: true,
                onTap: () => provider.setSortKey('relevance'),
              ),
              _sortItem(
                label: 'Most Popular',
                isSelected: provider.sortKey == 'rating',
                onTap: () => provider.setSortKey('rating'),
              ),
              _sortItem(
                label: 'Price',
                isSelected: provider.sortKey == 'low_to_high' || provider.sortKey == 'high_to_low',
                icon: Icons.swap_vert,
                onTap: () {
                  if (provider.sortKey == 'low_to_high') {
                    provider.setSortKey('high_to_low');
                  } else {
                    provider.setSortKey('low_to_high');
                  }
                },
              ),
              const VerticalDivider(width: 1, indent: 12, endIndent: 12),
              Flexible(
                child: InkWell(
                  onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Filter', style: TextStyle(fontSize: 13, color: Colors.black87)),
                        SizedBox(width: 4),
                        Icon(Icons.filter_list, size: 16, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sortItem({required String label, required bool isSelected, bool hasDropdown = false, IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.black54,
                ),
              ),
              if (hasDropdown) const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
              if (icon != null) Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Widget filterChipsBar() {
    return Container(
      height: 50,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildChip("Trends", isTrends: true),
          _buildChip("Category", hasDropdown: true, onTap: () => _scaffoldKey.currentState?.openEndDrawer()),
          _buildChip("Size", hasDropdown: true, onTap: () => _scaffoldKey.currentState?.openEndDrawer()),
          _buildChip("Pattern Type", hasDropdown: true, onTap: () => _scaffoldKey.currentState?.openEndDrawer()),
          _buildChip("Color", hasDropdown: true, onTap: () => _scaffoldKey.currentState?.openEndDrawer()),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {bool isTrends = false, bool hasDropdown = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isTrends ? const Color(0xFFF3E5F5) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isTrends ? Colors.deepPurple : Colors.black87,
                fontStyle: isTrends ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          centerTitle: true,
          title: const Text("Filter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: ListView(
          children: [
            _priceRangeSection(),
            _sizeSection(),
            _colorSection(),
            _ratingSection(),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => searchProvider.clearFilters(
                    keepCategoryId: widget.categoryId != null,
                    keepQuery: widget.searchQuery != null && widget.searchQuery!.isNotEmpty,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Clear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    searchProvider.search();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceRangeSection() {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        return ExpansionTile(
          initiallyExpanded: false,
          title: const Text("Price Range", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  RangeSlider(
                    values: provider.priceRange,
                    min: provider.minPossiblePrice,
                    max: provider.maxPossiblePrice,
                    activeColor: Colors.black,
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (values) => provider.setPriceRange(values.start, values.end),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("€${provider.priceRange.start.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text("€${provider.priceRange.end.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sizeSection() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return ExpansionTile(
          initiallyExpanded: false,
          title: const Text("Size", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          children: [
            FutureBuilder<List<String>>(
              future: provider.fetchSizes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                final sizes = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: sizes.map((size) {
                      final isSelected = provider.selectedSize == size;
                      return GestureDetector(
                        onTap: () => provider.setSelectedSize(size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                          ),
                          child: Text(size, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _colorSection() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return ExpansionTile(
          initiallyExpanded: false,
          title: const Text("Color", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          children: [
            FutureBuilder<List<String>>(
              future: provider.fetchColors(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                final colors = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colors.map((color) {
                      final isSelected = provider.selectedColor == color;
                      return GestureDetector(
                        onTap: () => provider.setSelectedColor(color),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                          ),
                          child: Text(color, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _ratingSection() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return ExpansionTile(
          initiallyExpanded: false,
          title: const Text("Rating", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(5, (i) {
                  double star = i + 1.0;
                  return GestureDetector(
                    onTap: () => provider.setMinRating(star),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.star,
                        size: 30,
                        color: (provider.minRating ?? 0) >= star ? Colors.amber : Colors.grey.shade300,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        switch (provider.state) {
          case SearchState.initial:
            return const Center(child: Text("Search for your favorite items"));
          case SearchState.loading:
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _viewAsGrid ? 2 : 1,
                childAspectRatio: _viewAsGrid ? 0.58 : 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ShimmerWidget.rectangular(height: 250),
            );
          case SearchState.error:
            return Center(child: Text(provider.errorMessage ?? 'An error occurred'));
          case SearchState.loaded:
            if (provider.searchResults.isEmpty) {
              return const Center(child: Text("No products found for this search."));
            }
            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _viewAsGrid ? 2 : 1,
                childAspectRatio: _viewAsGrid ? 0.58 : 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: provider.searchResults.length,
              itemBuilder: (context, index) {
                final product = provider.searchResults[index];
                if (_viewAsGrid) {
                  return ProductCard(
                    onTap: () => context.push('/products/${product.id}', extra: product),
                    context: context,
                    product: product,
                    addToCart: () => _showQuickAdd(context, product),
                  );
                } else {
                  return ProductListCard(
                    onTap: () => context.push('/products/${product.id}', extra: product),
                    context: context,
                    product: product,
                    addToCart: () => _showQuickAdd(context, product),
                  );
                }
              },
            );
        }
      },
    );
  }

  Future _showQuickAdd(BuildContext context, ProductModel product) {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.fetchProductDetails(product.id.toString());
    final TextEditingController colorController = TextEditingController();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer<SearchProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingProductDetails || provider.selectedProductDetails == null) {
              return Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    ShimmerWidget.rectangular(height: 150),
                    SizedBox(height: 15),
                    ShimmerWidget.rectangular(height: 20, width: 200),
                    SizedBox(height: 10),
                    ShimmerWidget.rectangular(height: 45),
                  ],
                ),
              );
            }

            final detail = provider.selectedProductDetails!;
            if (colorController.text.isEmpty && detail.colors != null) {
              colorController.text = detail.colors!;
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: detail.mainImageUrl, 
                            height: 120, 
                            width: 90, 
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerWidget.rectangular(height: 120, width: 90),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("€${detail.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                              const SizedBox(height: 4),
                              Text(detail.name, style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (detail.sizes != null && detail.sizes!.isNotEmpty) ...[
                      const Text("Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: detail.sizes!.map((size) {
                          final isSelected = provider.selectedSize == size;
                          return GestureDetector(
                            onTap: () => provider.selectSize(size),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.white,
                                border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(size, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Text("Color", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: colorController,
                      decoration: InputDecoration(
                        hintText: "Enter color",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              IconButton(onPressed: provider.decreaseQuantity, icon: const Icon(Icons.remove, size: 20)),
                              Text("${provider.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(onPressed: provider.increaseQuantity, icon: const Icon(Icons.add, size: 20)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.state != AuthState.authenticated) {
                            await showLoginPrompt(context);
                            if (!mounted) return;
                            if (authProvider.state != AuthState.authenticated) return;
                          }

                          if (provider.selectedSize == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a size")));
                            }
                            return;
                          }

                          final success = await context.read<CartProvider>().addToCart(
                            productId: detail.id, 
                            quantity: provider.quantity, 
                            sizes: provider.selectedSize!,
                            color: colorController.text,
                          );
                          
                          if (!mounted) return;

                          if (success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ${detail.name} to cart"), backgroundColor: Colors.green));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text("ADD TO BAG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      colorController.dispose();
      provider.resetQuantity();
    });
  }
}

class ProductListCard extends StatelessWidget {
  final ProductModel product;
  final BuildContext context;
  final VoidCallback onTap;
  final VoidCallback addToCart;

  const ProductListCard({
    super.key,
    required this.product,
    required this.context,
    required this.onTap,
    required this.addToCart,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: product.mainImageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerWidget.rectangular(height: 100, width: 100),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "€${product.price.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: addToCart,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                      ),
                    ),
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
