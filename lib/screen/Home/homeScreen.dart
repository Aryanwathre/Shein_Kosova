import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/category_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';

import '../../provider/banner_provider.dart';
import '../../utils/BiteClipper.dart';

import '../../widgets/carouselSlider.dart';
import '../../models/category_model.dart';
import '../../widgets/login_prompt_sheet.dart';

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
      final homeProvider = Provider.of<CategoryProvider>(context, listen: false);
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      final bannerProvider = Provider.of<BannerProvider>(context, listen: false);

      await homeProvider.fetchAllCategories();
      wishlistProvider.loadWishlist();
      await bannerProvider.fetchBanners();
      
      if (mounted && homeProvider.categories.isNotEmpty) {
        _tabController = TabController(
          length: homeProvider.categories.length,
          vsync: this,
        );

        _tabController!.addListener(_handleTabChange);

        // Initial fetch for first category
        homeProvider.fetchProductsByCategory(
          int.parse(homeProvider.categories.first.id),
        );

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

    final homeProvider = Provider.of<CategoryProvider>(context, listen: false);
    final selectedIndex = _tabController!.index;

    final currentCategory = homeProvider.categories[selectedIndex];
    homeProvider.fetchProductsByCategory(int.parse(currentCategory.id));
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
    // Performance optimization: Use Selector to only rebuild when categories change
    return Selector<CategoryProvider, List<CategoryModel>>(
      selector: (_, provider) => provider.categories,
      builder: (context, categories, child) {
        if (_tabController == null || categories.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  expandedHeight: 260,
                  backgroundColor: _appBarColor,
                  elevation: 0,
                  toolbarHeight: 100,
                  stretch: true,
                  flexibleSpace: FlexibleSpaceBar(
                    // stretchModes: const [StretchMode.zoomBackground],
                    background: Selector<BannerProvider, List>(
                      selector: (_, provider) => provider.banners,
                      builder: (context, banners, _) {
                        return buildCarouselSlider(banners.cast(), context);
                      },
                    ),
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
                            tabs: categories
                                .map<Widget>((CategoryModel category) => Tab(text: category.name))
                                .toList(),
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
              children: categories.map<Widget>((category) {
                return _CategoryProductsView(category: category);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryProductsView extends StatefulWidget {
  final CategoryModel category;
  const _CategoryProductsView({required this.category});

  @override
  State<_CategoryProductsView> createState() => _CategoryProductsViewState();
}

class _CategoryProductsViewState extends State<_CategoryProductsView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keeps the tab state alive for better performance

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final homeProvider = Provider.of<CategoryProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () async {
        await homeProvider.fetchProductsByCategory(int.parse(widget.category.id));
      },
      child: CustomScrollView(
        key: PageStorageKey<String>(widget.category.id),
        slivers: [
          SliverToBoxAdapter(
            child: _CategoryGrid(categories: homeProvider.categories),
          ),
          Selector<CategoryProvider, List>(
            selector: (_, provider) => provider.productsByCategory,
            builder: (context, products, _) {
              if (products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.5,
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
        padding: const EdgeInsets.all(10),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.35,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
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
