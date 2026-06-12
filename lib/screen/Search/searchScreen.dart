import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/search_provider.dart';
import 'package:shein_kosova/screen/ProductDetails/productDetails.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';
import 'package:shein_kosova/widgets/SearchBar.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late SearchProvider searchProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    searchProvider = Provider.of<SearchProvider>(context, listen: false);
  }

  @override
  void dispose() {
    final provider = Provider.of<SearchProvider>(context, listen: false);
_searchController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.clearSearchResults();
    });

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: searchbarTextField(context, _searchController),
          ),
        ),
      ),

      body: Consumer<SearchProvider>(
        builder: (context, provider, child) {

      // 👉 1. If query is empty → show nothing
      if (provider.query == null || provider.query!.isEmpty) {
        return const SizedBox();
      }

      // 👉 2. Show loader
      if (provider.state == SearchState.loading) {
        return ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => const ListTile(
            leading: ShimmerWidget.rectangular(width: 50, height: 50),
            title: ShimmerWidget.rectangular(height: 16),
            subtitle: ShimmerWidget.rectangular(height: 12, width: 50),
          ),
        );
      }

      // 👉 3. Error from backend
      if (provider.state == SearchState.error) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Search failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'Something went wrong while searching',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => provider.search(query: provider.query),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      // 👉 4. No products found → show nothing
      if (provider.searchResults.isEmpty) {
        return const SizedBox();
      }

      // 👉 5. Show products list
      return ListView.builder(
        itemCount: provider.searchResults.length,
        itemBuilder: (context, index) {
          final product = provider.searchResults[index];
          return ListTile(
            leading: product.mainImageUrl.isEmpty
                ? Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 25),
                  )
                : CachedNetworkImage(
                    imageUrl: product.mainImageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerWidget.rectangular(width: 50, height: 50),
                  ),
            title: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: styledPrice(product.price),
            onTap: () {
              context.push('/products/${product.id}', extra: product);
            },
          );
        },
      );
    },
    ),

    );
  }
}
