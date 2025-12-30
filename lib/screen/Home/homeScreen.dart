import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/utils/BiteClipper.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

import '../../widgets/carouselSlider.dart';
import '../../models/category_model.dart';
import '../../widgets/login_prompt_sheet.dart';
import '../../models/ProductModel.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;

  Color _appBarColor = Colors.transparent;
  Color _iconColor = Colors.white;
  Color _tabLabelColor = Colors.white;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

      await homeProvider.initHome();
      wishlistProvider.loadWishlist();
      
      if (mounted && homeProvider.categories.isNotEmpty) {
        _tabController = TabController(
          length: homeProvider.categories.length + 1,
          vsync: this,
        );

        _tabController!.addListener(_handleTabChange);
        setState(() {});
      }
    });

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.offset > 150) {
      if (_appBarColor != Colors.white) {
        setState(() {
          _appBarColor = Colors.white;
          _iconColor = Colors.black;
          _tabLabelColor = Colors.black;
        });
      }
    } else {
      if (_appBarColor != Colors.transparent) {
        setState(() {
          _appBarColor = Colors.transparent;
          _iconColor = Colors.white;
          _tabLabelColor = Colors.white;
        });
      }
    }
  }

  void _handleTabChange() {
    if (_tabController == null || _tabController!.indexIsChanging) return;

    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final selectedIndex = _tabController!.index;

    if (selectedIndex == 0) {
      // Home tab (All)
      homeProvider.fetchProductsByCategory(0);
    } else {
      final currentCategory = homeProvider.categories[selectedIndex - 1];
      homeProvider.fetchProductsByCategory(int.parse(currentCategory.id));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.state == HomeState.loading || _tabController == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (homeProvider.state == HomeState.error) {
          return Scaffold(
            body: Center(child: Text(homeProvider.errorMessage ?? "An error occurred")),
          );
        }

        final categories = homeProvider.categories;

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  expandedHeight: MediaQuery.of(context).size.width * 0.6,
                  backgroundColor: _appBarColor,
                  elevation: 0,
                  toolbarHeight: 100,
                  stretch: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: buildCarouselSlider(homeProvider.banners, context),
                  ),
                  title: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(color: _iconColor),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.mail_outline_outlined, size: 24, color: _iconColor),
                            const SizedBox(width: 10),
                            Expanded(child: BiteSearchBar(iconColor: _iconColor)),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: Icon(Icons.favorite_border_outlined,
                                  size: 26, color: _iconColor),
                              onPressed: () async {
                                final authProvider = context.read<AuthProvider>();
                                if (authProvider.state != AuthState.authenticated) {
                                  await showLoginPrompt(context);
                                  if (authProvider.state != AuthState.authenticated) return;
                                }

                                if (mounted) {
                                  context.push('/wishlist');
                                }
                              },
                            ),
                          ],
                        ),
                        SafeArea(
                          top: false,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            labelColor: _tabLabelColor,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                            unselectedLabelColor: _tabLabelColor.withOpacity(0.8),
                            dividerColor: Colors.transparent,
                            indicatorColor: Colors.white,
                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(width: 2.0, color: _tabLabelColor),
                              insets: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 4.0),
                            ),
                            tabs: [
                              const Tab(text: "Home"),
                              ...categories.map<Widget>((CategoryModel category) => Tab(text: category.name)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                const _HomeLandingView(), // Dedicated view for "Home" tab with pill tags
                ...categories.map<Widget>((category) {
                  return _CategoryProductsView(categoryId: int.parse(category.id));
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeLandingView extends StatelessWidget {
  const _HomeLandingView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Categories Grid (Showing all categories now)
        SliverToBoxAdapter(
          child: Consumer<HomeProvider>(
            builder: (context, provider, _) => _CategoryGrid(categories: provider.categories),
          ),
        ),
        
        // Horizontal Pill Tags (For You, Deals, Trending, etc.)
        SliverToBoxAdapter(
          child: _TagSelector(),
        ),

        // Product Grid based on selected Tag
        Consumer<HomeProvider>(
          builder: (context, provider, _) {
            final selectedTag = provider.selectedTag;
            final products = provider.getProductsForTag(selectedTag);
            final isLoading = provider.isTagLoading(selectedTag);

            if (isLoading) {
              return SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.57,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ProductCardShimmer(),
                    childCount: 4,
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.57,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    return ProductCard(
                      onTap: () => context.push('/product/${product.id}', extra: product),
                      context: context,
                      product: product,
                    );
                  },
                  childCount: products.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TagSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, _) {
        // Build static tags + dynamic tags from API
        final allTags = ["All","For You", ...provider.tags.map((t) => t[0].toUpperCase() + t.substring(1))];
        
        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: allTags.length,
            itemBuilder: (context, index) {
              final tag = allTags[index];
              final isSelected = provider.selectedTag == tag;
              
              return GestureDetector(
                onTap: () => provider.setSelectedTag(tag),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))] : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tag == "New In") Icon(Icons.auto_awesome, size: 14, color: isSelected ? Colors.white : Colors.black),
                      if (tag == "Deals") Icon(Icons.local_offer, size: 14, color: isSelected ? Colors.white : Colors.black),
                      if (tag == "Bestsellers") Icon(Icons.emoji_events, size: 14, color: isSelected ? Colors.white : Colors.black),
                      if (tag == "New In" || tag == "Deals" || tag == "Bestsellers") const SizedBox(width: 6),
                      Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryProductsView extends StatefulWidget {
  final int categoryId;
  const _CategoryProductsView({required this.categoryId});

  @override
  State<_CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends State<_CategoryProductsView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final categoryId = widget.categoryId;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<HomeProvider>().fetchProductsByCategory(categoryId);
      },
      child: CustomScrollView(
        key: PageStorageKey<String>(categoryId.toString()),
        slivers: [
          SliverToBoxAdapter(
            child: Consumer<HomeProvider>(
              builder: (context, provider, _) => _CategoryGrid(categories: provider.categories),
            ),
          ),
          Consumer<HomeProvider>(
            builder: (context, provider, _) {
              final products = provider.getProductsForCategory(categoryId);
              final isLoading = provider.isCategoryLoading(categoryId);

              if (products.isEmpty) {
                if (isLoading) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.57,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ProductCardShimmer(),
                        childCount: 4,
                      ),
                    ),
                  );
                }
                return const SliverFillRemaining(
                  child: Center(child: Text("No products found")),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.57,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return ProductCard(
                        onTap: () => context.push('/product/${product.id}', extra: product),
                        context: context,
                        product: product,
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  const _CategoryGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(5),
        itemCount: categories.isEmpty ? 15 : categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.35,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        itemBuilder: (context, index) {
          if (categories.isEmpty) {
            return const CategoryItemShimmer();
          }
          String categoryId = categories[index].id.toString();
          String categoryName = categories[index].name;
          return GestureDetector(
            onTap: () {
              context.push('/search-result?categoryId=$categoryId&searchTitle=$categoryName');
            },
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[200],
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                Text(
                  categories[index].name,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
