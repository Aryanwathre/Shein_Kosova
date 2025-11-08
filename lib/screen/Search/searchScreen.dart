import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';

// Make sure these paths are correct for your project structure
import '../../provider/search_provider.dart';
import '../ProductDetails/productDetails.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    // It's good practice to clear the search and dispose the controller
    // when leaving the screen to free up resources.
    Provider.of<SearchProvider>(context, listen: false).clearSearch();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  _buildSearchBar(),
      body: Column(
        children: [

          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  /// Builds the search bar with a clear button.
  PreferredSize _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 80, 8, 8),
        child: Consumer<SearchProvider>(
          builder: (context, searchProvider, child) {
            return TextField(
              controller: _searchController,
              autofocus: true, // Automatically focus the search bar
              onChanged: (query) => searchProvider.search(query),
              decoration: InputDecoration(
                hintText: "Search for products...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    searchProvider.clearSearch();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the search results section based on the provider's state.
  Widget _buildSearchResults() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        switch (provider.state) {
          case SearchState.initial:
            return const Center(
              child: Text("Start typing to search for products."),
            );
          case SearchState.loading:
            return const Center(child: CircularProgressIndicator());
          case SearchState.error:
            return Center(
              child: Text(provider.errorMessage ?? 'An error occurred.'),
            );
          case SearchState.loaded:
            if (provider.searchResults.isEmpty) {
              return const Center(child: Text("No products found."));
            }
            // Display the grid of search results
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // crossAxisSpacing: 8,
                // mainAxisSpacing: 8,
                childAspectRatio: 0.6,
              ),
              itemCount: provider.searchResults.length,
              itemBuilder: (context, index) {
                final ProductModel product = provider.searchResults[index];
                return ProductCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                    context: context,
                    product: product
                );
              },
            );
        }
      },
    );
  }

}
