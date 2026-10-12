import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/utils/BiteClipper.dart';
import 'package:shein_kosova/utils/responsive_helper.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import 'package:shein_kosova/widgets/carouselSlider.dart';
import 'package:shein_kosova/widgets/brand_grid.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';


class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await homeProvider.initHome();

      if (authProvider.isAuthenticated) {
        final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
        wishlistProvider.loadWishlist();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        if (homeProvider.state == HomeState.loading ||
            homeProvider.state == HomeState.initial) {
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

        final banners = homeProvider.banners;
        final bool hasBanners = banners.isNotEmpty;

        const Color effectiveAppBarColor = Colors.black;
        const Color effectiveIconColor = Colors.white;

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  backgroundColor: effectiveAppBarColor,
                  elevation: 0,
                  toolbarHeight: 64,
                  title: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: const TextStyle(color: effectiveIconColor),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  'assets/logo.png',
                                  height: 34,
                                  width: 104,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
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
                      ],
                    ),
                  ),
                ),
                if (hasBanners)
                  SliverToBoxAdapter(
                    child: buildCarouselSlider(banners, context),
                  ),
              ];
            },
            body: const _HomeLandingView(),
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
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_isNearBottom(notification)) {
          final provider = context.read<HomeProvider>();
          // Only the "All" tag is paged; the others come from fixed-size
          // tag endpoints. loadMoreForCategory no-ops when exhausted.
          if (provider.selectedTag == "All") {
            provider.loadMoreForCategory(0);
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          final homeProvider = context.read<HomeProvider>();
          await homeProvider.initHome(forceRefresh: true);
        },
        child: CustomScrollView(
          slivers: [
          // Top Brands grid under the banner (replaces the category grid).
          SliverToBoxAdapter(
            child: Consumer<HomeProvider>(
              builder: (context, provider, _) =>
                  BrandGrid(stores: provider.stores),
            ),
          ),
      
          // Dedicated "Deals of the Day" + "Trending" horizontal sections.
          SliverToBoxAdapter(
            child: Consumer<HomeProvider>(
              builder: (context, provider, _) => _HorizontalProductSection(
                title: 'Deals of the Day',
                products: provider.dealsProducts,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer<HomeProvider>(
              builder: (context, provider, _) => _HorizontalProductSection(
                title: 'Trending Now',
                products: provider.trendingProducts,
              ),
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.getGridColumns(context),
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ProductCardShimmer(),
                      childCount: ResponsiveHelper.getGridColumns(context) * 2,
                    ),
                  ),
                );
              }
      
              return SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveHelper.getGridColumns(context),
                    childAspectRatio: 0.58,
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

          // Footer loader for the next page.
          SliverToBoxAdapter(
            child: Consumer<HomeProvider>(
              builder: (context, provider, _) {
                if (provider.selectedTag != "All") {
                  return const SizedBox.shrink();
                }
                return _FeedFooter(
                  loadingMore: provider.isCategoryLoadingMore(0),
                  hasMore: provider.categoryHasMore(0),
                  isEmpty: provider.getProductsForTag("All").isEmpty,
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

/// A titled, horizontally-scrolling row of products (e.g. "Deals of the Day",
/// "Trending Now"). Renders nothing until its products have loaded.
class _HorizontalProductSection extends StatelessWidget {
  final String title;
  final List<ProductModel> products;

  const _HorizontalProductSection({required this.title, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 150,
                child: ProductCard(
                  onTap: () =>
                      context.push('/products/${product.id}', extra: product),
                  context: context,
                  product: product,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// True once the viewport is within 300px of the end of the list.
bool _isNearBottom(ScrollNotification notification) {
  return notification.metrics.pixels >=
      notification.metrics.maxScrollExtent - 300;
}

/// Bottom-of-feed status: spinner while a page loads, end marker once done.
class _FeedFooter extends StatelessWidget {
  final bool loadingMore;
  final bool hasMore;
  final bool isEmpty;

  const _FeedFooter({
    required this.loadingMore,
    required this.hasMore,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!hasMore && !isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "You've reached the end",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
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
