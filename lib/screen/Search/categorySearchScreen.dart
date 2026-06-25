import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/responsive_helper.dart';
import 'package:shein_kosova/widgets/SearchBar.dart';
import 'package:shein_kosova/widgets/category_grid.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';


class CategorySearchScreen extends StatefulWidget {
  const CategorySearchScreen({super.key});

  @override
  State<CategorySearchScreen> createState() => _CategorySearchScreenState();
}

class _CategorySearchScreenState extends State<CategorySearchScreen> {
  HomeProvider? _homeProvider;

  @override
  void initState() {
    super.initState();
    _homeProvider = Provider.of<HomeProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = _homeProvider;
      if (provider != null && provider.categories.isEmpty) {
        provider.initHome();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSize _appBar(BuildContext context){
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
              children: [
                const Icon(Icons.mail_outline_outlined, size: 24, color: AppColors.black),
                const SizedBox(width: 10),
                Expanded(child: buildSquareSearchBar(context)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.state != AuthState.authenticated) {
                      await showLoginPrompt(context);
                      if (!mounted) return;
                      if (authProvider.state != AuthState.authenticated) return;
                    }

                    if (mounted) {
                      context.push('/wishlist');
                    }
                  },
                  child: const Icon(Icons.favorite_border_outlined,
                      size: 26, color: AppColors.black),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Consumer<HomeProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories;

        if (categories.isEmpty && provider.state == HomeState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categories.isEmpty && provider.state != HomeState.loading) {
          return const Center(child: Text("No categories found."));
        }

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverGrid(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 6 : 4, // 4 items per row on mobile
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
        (context, index) => CategoryCard(
        category: categories[index],
        forcedImageSize: isDesktop ? 80 : 60, // Optimized size
        ),
        childCount: categories.length,
        ),
        ),),
            // You can add more sections here like "Trending Searches" or "Featured"
          ],
        );
      },
    );
  }
}
