import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/widgets/SearchBar.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';


class CargorySearchScreen extends StatefulWidget {
  const CargorySearchScreen({super.key});

  @override
  State<CargorySearchScreen> createState() => _CargorySearchScreenState();
}

class _CargorySearchScreenState extends State<CargorySearchScreen> {

  final ScrollController _gridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      // Re-use data from HomeProvider if available, otherwise initialize it
      if (homeProvider.categories.isEmpty) {
        homeProvider.initHome();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body:_categoryGrid(context),
    );
  }

  PreferredSize _appBar(BuildContext context){
    return PreferredSize(
      preferredSize: const Size.fromHeight(200),
      child: SafeArea(
        top: true,
        child:  Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
              children: [
                Icon(Icons.mail_outline_outlined, size: 24, color: AppColors.black),
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

  Widget _categoryGrid(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final categories = homeProvider.categories;

    if (categories.isEmpty && homeProvider.state == HomeState.loading) {
      return GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.35,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) => const ShimmerWidget.rectangular(height: 80),
      );
    }

    if (categories.isEmpty && homeProvider.state != HomeState.loading) {
      return const Center(child: Text("No categories found."));
    }

    return GridView.builder(
      controller: _gridScrollController,
      padding: const EdgeInsets.all(10),
      itemCount: categories.length,
      gridDelegate:  const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        return GestureDetector(
          onTap: () {
            context.push('/search-result?categoryId=${category.id}&searchTitle=${category.name}');
          },
          child: Column(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(image: NetworkImage(category.categoryImage ?? '')),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                category.name,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

}
