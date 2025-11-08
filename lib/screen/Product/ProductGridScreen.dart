import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import '../../provider/ProductDetailsProvider.dart';
import '../ProductDetails/productDetails.dart';


class ProductGridScreen extends StatefulWidget {
  int selectedCategoryId;
  bool? scrollingPhyscis = false;
  ProductGridScreen({super.key, required this.selectedCategoryId, this.scrollingPhyscis});

  @override
  State<ProductGridScreen> createState() => _ProductGridScreenState();
}

class _ProductGridScreenState extends State<ProductGridScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch products from the API when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if(widget.selectedCategoryId == 0){
        productProvider.fetchAllProducts();
      } else {
        productProvider.getProductByCode(widget.selectedCategoryId, 0,);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          // Handle the different states of the product list
          switch (provider.listState) {
            case ProductListState.loading:
              return const Center(child: CircularProgressIndicator());
            case ProductListState.error:
              return Center(
                  child: Text(provider.listErrorMessage ?? "Failed to load products"));
            case ProductListState.loaded:
              if (provider.products.isEmpty) {
                return const Center(child: Text("No products found."));
              }
              // If loaded, display the product grid
              return GridView.builder(
                physics: widget.scrollingPhyscis == true ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: provider.products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.58, // Adjust as needed for your ProductCard design
                ),
                itemBuilder: (context, index) {
                  final product = provider.products[index];
                  return ProductCard(
                      onTap: () {
                        // Navigate to details screen, passing the productId
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(product: product,),
                          ),
                        );
                      },
                      product: product, context: context);
                },
              );
            default:
              return const Center(child: Text("Welcome to the store!"));
          }
        },
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    // Use a Consumer here as well to get the latest state for the buttons
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Sort By Button
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("Relevance"),
                          onTap: () {
                            provider.sortProducts("Relevance");
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Price: Low to High"),
                          onTap: () {
                            provider.sortProducts("Price: Low to High");
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Price: High to Low"),
                          onTap: () {
                            provider.sortProducts("Price: High to Low");
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.sort, color: Colors.black87),
                label: const Text("Sort By", style: TextStyle(color: Colors.black87)),
              ),

              // Filter Button
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("All"),
                          onTap: () {
                            provider.filterByCategory("All");
                            Navigator.pop(context);
                          },
                        ),
                        // Assuming you have category IDs to filter by
                        ListTile(
                          title: const Text("Men"),
                          onTap: () {
                            provider.filterByCategory("mens-category-id");
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Women"),
                          onTap: () {
                            provider.filterByCategory("womens-category-id");
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Accessories"),
                          onTap: () {
                            provider.filterByCategory("accessories-category-id");
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.filter_alt, color: Colors.black87),
                label: const Text("Filter", style: TextStyle(color: Colors.black87)),
              ),
            ],
          ),
        );
      },
    );
  }
}
