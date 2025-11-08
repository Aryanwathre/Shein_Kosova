import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/provider/wishListProvider.dart';
import 'package:shein_kosova/screen/ProductDetails/productDetails.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import '../../utils/BiteClipper.dart';
import '../../widgets/SearchBar.dart';
import '../../widgets/carouselSlider.dart';
import '../../models/Category.dart';
import '../Product/ProductGridScreen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with SingleTickerProviderStateMixin {
  final List<Widget> imageSliders = [
    Container(color: Colors.red,),
    Container(color: Colors.blue),
    Container(color: Colors.green),
  ];

  final List<VoidCallback> onTap = [
        () => print('Image 1 tapped'),
        () => print('Image 2 tapped'),
        () => print('Image 3 tapped'),
  ];

  final ScrollController _gridScrollController = ScrollController();
  TabController? _tabController; // ✅ Make it nullable
  final ScrollController _scrollController = ScrollController();

  Color _appBarColor = Colors.transparent;
  Color _iconColor = Colors.white;
  Color _tabLabelColor = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

      await homeProvider.fetchCategories();
      wishlistProvider.loadWishlist();

      if (mounted && homeProvider.categories.isNotEmpty) {
        _tabController = TabController(
          length: homeProvider.categories.length,
          vsync: this,
        );
        _tabController!.addListener(_handleTabChange);

        // Load products for first tab
        homeProvider.FetchProductsByCategory(homeProvider.categories.first.id);
        setState(() {}); // ✅ Trigger rebuild after initialization
      }

      if(_gridScrollController.position.pixels ==
          _gridScrollController.position.maxScrollExtent){
        if (homeProvider.hasMorePages) {
          await homeProvider.fetchCategories(
              page: homeProvider.currentPage + 1, append: true);
          setState(() {});
        }
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
    final selectedCategory = homeProvider.categories[_tabController!.index];
    homeProvider.FetchProductsByCategory(selectedCategory.id);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _gridScrollController.dispose();
    _tabController?.dispose(); // ✅ Safe dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    // ✅ If categories not yet loaded, show loader
    if (_tabController == null || homeProvider.categories.isEmpty) {
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
              expandedHeight: 250.0,
              backgroundColor: _appBarColor,
              elevation: 0,
              toolbarHeight: 100,
              flexibleSpace: FlexibleSpaceBar(
                background: buildCarouselSlider(imageSliders, context, onTap),
              ),
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(color: _iconColor),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: BiteSearchBar(iconColor: _iconColor)),
                        const SizedBox(width: 10),
                        Icon(Icons.favorite_border_outlined,
                            size: 26, color: _iconColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      labelColor: _tabLabelColor,
                      unselectedLabelColor: _tabLabelColor,
                      dividerColor: Colors.transparent,
                      indicatorColor: Colors.white,
                      indicator: UnderlineTabIndicator(
                        borderSide:
                        BorderSide(width: 2.0, color: _tabLabelColor),
                      ),
                      tabs: homeProvider.categories
                          .map((Category category) => Tab(text: category.name))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body:TabBarView(
        controller: _tabController,
        children: homeProvider.categories.map((category) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _categoryGrid(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.57,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = homeProvider.productsByCategory[index];
                      return ProductCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsScreen(product: product),
                          ),
                        ),
                        context: context,
                        product: product,
                      );
                    },
                    childCount: homeProvider.productsByCategory.length,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ),
    );
  }

  Widget _categoryGrid(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: GridView.builder(
        controller: _gridScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        itemCount: homeProvider.categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
              ),
              Text(
                homeProvider.categories[index].name,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _forYouTab(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      itemCount: homeProvider.productsByCategory.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.57,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final product = homeProvider.productsByCategory[index];
        return ProductCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          ),
          context: context,
          product: product,
        );
      },
    );
  }
}
