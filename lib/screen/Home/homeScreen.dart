import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/utils/BiteClipper.dart';
import 'package:shein_kosova/utils/responsive_helper.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import 'package:shein_kosova/widgets/carouselSlider.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';


class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;

  Color _appBarColor = Colors.transparent;
  Color _iconColor = Colors.white;
  Color _tabLabelColor = Colors.white;
  bool _isScrolled = false;
  bool _isBannerLight = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final wishlistProvider =
          Provider.of<WishlistProvider>(context, listen: false);

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
      if (!_isScrolled) {
        setState(() {
          _isScrolled = true;
          _appBarColor = Colors.white;
          _iconColor = Colors.black;
          _tabLabelColor = Colors.black;
        });
      }
    } else {
      if (_isScrolled) {
        setState(() {
          _isScrolled = false;
          _appBarColor = Colors.transparent;
          _updateHeaderColors(_isBannerLight);
        });
      }
    }
  }

  void _updateHeaderColors(bool isLight) {
    _isBannerLight = isLight;
    if (_isScrolled) return;

    setState(() {
      if (isLight) {
        _iconColor = Colors.black;
        _tabLabelColor = Colors.black;
      } else {
        _iconColor = Colors.white;
        _tabLabelColor = Colors.white;
      }
    });
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
            body: HomeShimmer(),
          );
        }

        if (homeProvider.state == HomeState.error) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    homeProvider.errorMessage ?? 'Failed to load content',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => homeProvider.initHome(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final categories = homeProvider.categories;
        final banners = homeProvider.banners;
        final bool hasBanners = banners.isNotEmpty;

        // Determine effective colors based on whether banners are present
        final Color effectiveAppBarColor = hasBanners ? _appBarColor : Colors.white;
        final Color effectiveIconColor = hasBanners ? _iconColor : Colors.black;
        final Color effectiveTabLabelColor = hasBanners ? _tabLabelColor : Colors.black;

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  expandedHeight: hasBanners ? MediaQuery.of(context).size.width * 0.6 : 100,
                  backgroundColor: effectiveAppBarColor,
                  elevation: 0,
                  toolbarHeight: 100,
                  stretch: hasBanners,
                  flexibleSpace: hasBanners ? FlexibleSpaceBar(
                    background: buildCarouselSlider(
                      banners,
                      context,
                      onThemeChanged: (isLight) => _updateHeaderColors(isLight),
                    ),
                  ) : null,
                  title: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(color: effectiveIconColor),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: BiteSearchBar(iconColor: effectiveIconColor),
                            ),
                            const SizedBox(width: 10),
                            Consumer<WishlistProvider>(
                              builder: (context, wishlistProvider, _) {
                                final count = wishlistProvider.wishlistItems.length;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.favorite_border_outlined,
                                        size: 26,
                                        color: effectiveIconColor,
                                      ),
                                      onPressed: () async {
                                        final authProvider =
                                            context.read<AuthProvider>();
                                        if (authProvider.state !=
                                            AuthState.authenticated) {
                                          await showLoginPrompt(context);
                                          if (!mounted) return;
                                          if (authProvider.state !=
                                              AuthState.authenticated) {
                                            return;
                                          }
                                        }
                                        if (mounted) {
                                          context.push('/wishlist');
                                        }

                                      },
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        right: 5,
                                        top: 5,
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
                                            count.toString(),
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
                                );
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
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            labelColor: effectiveTabLabelColor,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelColor: effectiveTabLabelColor.withValues(
                             alpha:  0.8,
                            ),
                            dividerColor: Colors.transparent,
                            indicatorColor: effectiveTabLabelColor,
                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: effectiveTabLabelColor,
                              ),
                              insets: const EdgeInsets.fromLTRB(
                                8.0,
                                0.0,
                                8.0,
                                4.0,
                              ),
                            ),
                            tabs: [
                              const Tab(text: "All"),
                              ...categories.map<Widget>(
                                (CategoryModel category) =>
                                    Tab(text: category.name),
                              ),
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
                  return _CategoryProductsView(
                    categoryId: int.parse(category.id),
                  );
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
    return RefreshIndicator(
      onRefresh: () async {
        final homeProvider = context.read<HomeProvider>();
        await homeProvider.initHome();
      },
      child: CustomScrollView(
        slivers: [
          // Categories Grid (Showing all categories now)
          SliverToBoxAdapter(
            child: Consumer<HomeProvider>(
              builder: (context, provider, _) =>
                  _CategoryGrid(categories: provider.categories),
            ),
          ),
      
          // Horizontal Pill Tags (All, For You, Deals, Trending, etc.)
          SliverToBoxAdapter(child: _TagSelector()),
      
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = products[index];
                    return ProductCard(
                      onTap: () =>
                          context.push('/products/${product.id}', extra: product),
                      context: context,
                      product: product,
                    );
                  }, childCount: products.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TagSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeProvider, AuthProvider>(
      builder: (context, homeProvider, authProvider, _) {
        final isAuthenticated = authProvider.state == AuthState.authenticated;

        // Build tag list: "All" is always first
        final List<String> availableTags = ["All"];

        // "For You" is only shown if authenticated
        if (isAuthenticated) {
          availableTags.add("For You");
        }

        // Add tags from API (Deals, Trending, etc.)
        for (var tag in homeProvider.tags) {
          // Skip empty or whitespace-only tags
          if (tag.trim().isEmpty) continue;

          final formattedTag = tag[0].toUpperCase() + tag.substring(1);
          if (!availableTags.contains(formattedTag)) {
            availableTags.add(formattedTag);
          }
        }

        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: availableTags.length,
            itemBuilder: (context, index) {
              final tag = availableTags[index];
              final isSelected = homeProvider.selectedTag == tag;

              return GestureDetector(
                onTap: () => homeProvider.setSelectedTag(tag),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tag == "New In")
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      if (tag == "Deals")
                        Icon(
                          Icons.local_offer,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      if (tag == "Bestsellers")
                        Icon(
                          Icons.emoji_events,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      if (tag == "New In" ||
                          tag == "Deals" ||
                          tag == "Bestsellers")
                        const SizedBox(width: 6),
                      Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
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

class _CategoryProductsViewState extends State<_CategoryProductsView>
    with AutomaticKeepAliveClientMixin {
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
              builder: (context, provider, _) =>
                  _CategoryGrid(categories: provider.categories),
            ),
          ),
          Consumer<HomeProvider>(
            builder: (context, provider, _) {
              final products = provider.getProductsForCategory(categoryId);
              final isLoading = provider.isCategoryLoading(categoryId);

              if (products.isEmpty) {
                if (isLoading) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = products[index];
                    return ProductCard(
                      onTap: () =>
                          context.push('/products/${product.id}', extra: product),
                      context: context,
                      product: product,
                    );
                  }, childCount: products.length),
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
    // Adjust grid columns based on device type
    int crossAxisCount = ResponsiveHelper.isDesktop(context) ? 6 : 3;
    double height = ResponsiveHelper.isDesktop(context)
        ? MediaQuery.of(context).size.height * 0.35
        : MediaQuery.of(context).size.height * 0.4;

    return SizedBox(
      height: height,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(5),
        itemCount: categories.isEmpty ? 15 : categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
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
          String categoryImage = categories[index].categoryImage ?? '';
          return GestureDetector(
            onTap: () {
              context.push(
                '/search-result?categoryId=$categoryId&searchTitle=$categoryName',
              );
            },
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    image: categoryImage.isNotEmpty
                        ? DecorationImage(image: NetworkImage(categoryImage))
                        : null,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    color: Colors.grey[200], // Fallback background color
                  ),
                  child: categoryImage.isEmpty
                      ? Icon(Icons.image_not_supported, color: Colors.grey[400])
                      : null,
                ),
                const SizedBox(height: 5),
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
