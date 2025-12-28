import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';

import '../../provider/category_provider.dart';
import '../../widgets/SearchBar.dart';
import '../../widgets/login_prompt_sheet.dart';

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

    _gridScrollController.addListener(() {
      final provider = Provider.of<CategoryProvider>(context, listen: false);

      if (_gridScrollController.position.pixels ==
          _gridScrollController.position.maxScrollExtent) {
        if (provider.hasMorePages && !provider.isFetchingNextPage) {
          provider.fetchCategories(append: true);
        }
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
                      if (authProvider.state != AuthState.authenticated) return;
                    }

                    if (mounted) {
                      context.push('/wishlist');
                    }
                  },
                  child: Icon(Icons.favorite_border_outlined,
                      size: 26, color: AppColors.black),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _categoryGrid(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (categoryProvider.categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GridView.builder(
      controller: _gridScrollController,
      padding: const EdgeInsets.all(10),
      itemCount: categoryProvider.categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final category = categoryProvider.categories[index];

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
                  color: Colors.blueGrey[200],
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
