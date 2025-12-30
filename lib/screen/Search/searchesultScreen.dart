import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/ProductModel.dart';

import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/provider/search_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
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
            searchProvider.search(page: searchProvider.currentPage! + 1);
          }
        });
      }
    });
  }


  void _initializeSearchResult(){
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
        toolbarHeight: MediaQuery.of(context).size.height * 0.09,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(child: buildProductSearchBar(context, widget.searchTitle)),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: InkWell(
                child: Icon(_viewAsGrid ? Icons.art_track_outlined : Icons.grid_view_outlined, size: 22),
                onTap: () => setState(() => _viewAsGrid = !_viewAsGrid),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: InkWell(
                onTap: () async {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.state != AuthState.authenticated) {
                    await showLoginPrompt(context);
                    if (authProvider.state != AuthState.authenticated) return;
                  }

                  if (mounted) {
                    context.push('/wishlist');
                  }
                },
                child: const Icon(Icons.favorite_border_outlined, size: 22),
              ),
            ),
          ],
        ),
      ),
      endDrawer: _filterDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart_outlined, color: Colors.black,),
            if (cartProvider.itemCount > 0)
              Positioned(
                right: -15,
                top: -15,
                child: Container(
                  padding: const EdgeInsets.all(2),
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
          onPressed: () async {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.state != AuthState.authenticated) {
              await showLoginPrompt(context);
              if (authProvider.state != AuthState.authenticated) return;
            }

            if (mounted) {
              context.go('/shop?index=2');
            }
          }
      ),
      body: Column(
        children: [
          Divider(color: Colors.grey[300], height: 5),
          _filterBar(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sortDropdown(searchProvider),
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: const Row(
              children: [
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.filter_alt_outlined, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortDropdown(SearchProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: provider.sortKey,
        items: const [
          DropdownMenuItem(value: "relevance", child: Text("Relevance")),
          DropdownMenuItem(value: "low_to_high", child: Text("Price: Low to High")),
          DropdownMenuItem(value: "high_to_low", child: Text("Price: High to Low")),
          DropdownMenuItem(value: "rating", child: Text("Rating")),
        ],
        onChanged: (value) => provider.setSortKey(value!),
        icon: const Icon(Icons.arrow_drop_down),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  Widget _filterDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Scaffold(
        appBar: AppBar(
          elevation: 2,
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          leading: InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close),
          ),
          centerTitle: true,
          title: const Text("Filter", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          children: [
            _priceRangeSection(),
            _sizeSection(),
            _ratingSection(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => searchProvider.clearFilters(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.black),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Clear', style: TextStyle(color: AppColors.textDark)),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    searchProvider.search();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(4)),
                    child: Text('Done', style: TextStyle(color: AppColors.textWhite)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceRangeSection() {
    return Consumer<SearchProvider>(
        builder: (context, provider, _){
          return ExpansionTile(
            title: const Text("Price Range", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RangeSlider(
                      values: provider.priceRange,
                      min: provider.minPossiblePrice,
                      max: provider.maxPossiblePrice,
                      divisions: 50,
                      labels: RangeLabels(
                        "£${provider.priceRange.start.toStringAsFixed(0)}",
                        "£${provider.priceRange.end.toStringAsFixed(0)}",
                      ),
                      onChanged: (values) => provider.setPriceRange(values.start, values.end),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("£${provider.priceRange.start.toStringAsFixed(0)}"),
                        Text("£${provider.priceRange.end.toStringAsFixed(0)}"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }
    );
  }


  Widget _sizeSection() {
    return Consumer<SearchProvider>(
        builder: (context, provider, child) {
          return ExpansionTile(
            title: const Text("Size", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            children: [
              FutureBuilder<List<String>>(
                future: provider.fetchSizes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 10);
                  final sizes = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sizes.map((size) {
                        final isSelected = provider.selectedSize == size;
                        return GestureDetector(
                          onTap: () => provider.setSelectedSize(size),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade400),
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                            child: Text(size, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
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
          title: const Text("Rating", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: List.generate(5, (i) {
                  double star = i + 1.0;
                  return GestureDetector(
                    onTap: () => provider.setMinRating(star),
                    child: Icon(
                      Icons.star,
                      size: 32,
                      color: (provider.minRating ?? 0) >= star ? Colors.amber : Colors.grey.shade400,
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
            return const Center(child: Text("Start typing to search for products."));
          case SearchState.loading:
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _viewAsGrid ? 2 : 1,
                childAspectRatio: _viewAsGrid ? 0.57 : 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return const ShimmerWidget.rectangular(height: 250);
              },
            );
          case SearchState.error:
            return Center(child: Text(provider.errorMessage ?? 'An error occurred.'));
          case SearchState.loaded:
            if (provider.searchResults.isEmpty) return const Center(child: Text("No products found."));
            
            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _viewAsGrid ? 2 : 1,
                childAspectRatio: _viewAsGrid ? 0.57 : 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: provider.searchResults.length,
              itemBuilder: (context, index) {
                final product = provider.searchResults[index];
                if (_viewAsGrid) {
                  return ProductCard(
                    onTap: () => context.push('/product/${product.id}', extra: product),
                    context: context,
                    product: product,
                    addToCart: () => _showQuickAdd(context, product),
                  );
                } else {
                  return ProductListCard(
                    onTap: () => context.push('/product/${product.id}', extra: product),
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
                  children: [
                    const ShimmerWidget.rectangular(height: 150),
                    const SizedBox(height: 10),
                    const ShimmerWidget.rectangular(height: 20, width: 200),
                    const SizedBox(height: 10),
                    const ShimmerWidget.rectangular(height: 40),
                  ],
                ),
              );
            }

            final detail = provider.selectedProductDetails!;
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20,),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.detailImages.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(detail.detailImages[index], fit: BoxFit.fitHeight, width: 120, height: 150),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(detail.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        Text("€${detail.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text("Quantity:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              IconButton(onPressed: provider.decreaseQuantity, icon: const Icon(Icons.remove)),
                              Text("${provider.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(onPressed: provider.increaseQuantity, icon: const Icon(Icons.add)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (detail.sizes != null && detail.sizes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Select Size", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: detail.sizes!.map((size) => ChoiceChip(
                                label: Text(size),
                                selected: provider.selectedSize == size,
                                selectedColor: Colors.black,
                                labelStyle: TextStyle(color: provider.selectedSize == size ? Colors.white : Colors.black),
                                onSelected: (_) => provider.selectSize(size),
                              )).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.state != AuthState.authenticated) {
                          await showLoginPrompt(context);
                          if (authProvider.state != AuthState.authenticated) return;
                        }

                        if (provider.selectedSize == null) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a size.")));
                          return;
                        }

                        if (context.mounted) {
                          context.read<CartProvider>().addToCart(productId: detail.id, quantity: provider.quantity, sizes: provider.selectedSize!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ${detail.name} to cart"), backgroundColor: Colors.green));
                        }
                      },
                      child: const Text("Add to Cart"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
