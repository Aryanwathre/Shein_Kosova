import 'package:flutter/material.dart';
import 'package:shein_kosova/services/api_service.dart';
import '../models/category_model.dart';
import '../models/ProductModel.dart';

class CategoryProvider extends ChangeNotifier {
  // Category list
  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  // API manager
  final ApiServiceManager _api = ApiServiceManager();

  // Pagination state
  int _currentPage = 0;
  bool _hasMorePages = true;
  bool get hasMorePages => _hasMorePages;

  // To prevent multiple API calls
  bool isFetchingNextPage = false;

  // Product list by category
  List<ProductModel> _productsByCategory = [];
  List<ProductModel> get productsByCategory => _productsByCategory;

  Future<void> fetchCategories({bool append = false}) async {
    if (isFetchingNextPage) return;
    if (!_hasMorePages) return;

    isFetchingNextPage = true;

    try {
      final response = await _api.categoriesApi.getCategories(
        page: _currentPage,
        size: 20,
      );

      if (response.success && response.data != null) {
        final newItems = response.data!.content;

        // If API returns no items → stop pagination
        if (newItems.isEmpty) {
          _hasMorePages = false;
        } else {
          if (append) {
            _categories.addAll(newItems);
          } else {
            _categories = newItems;
          }

          _currentPage++; // Move to next page
        }
      } else {
        debugPrint("❌ Failed to load categories: ${response.error}");
      }
    } catch (e) {
      debugPrint("⚠️ Exception loading categories: $e");
    }

    isFetchingNextPage = false;
    notifyListeners();
  }

  Future<void> fetchAllCategories() async {
    int page = 0;
    bool hasMore = true;
    final List<CategoryModel> temp = [];

    while (hasMore) {
      final response = await _api.categoriesApi.getCategories(
        page: page,
        size: 20,
        sortBy: "name",
        sortDir: "asc",
      );

      if (response.success && response.data != null) {
        temp.addAll(response.data!.content);

        hasMore = !response.data!.last;
        page++;
      } else {
        hasMore = false;
      }
    }

    _categories = temp;
    notifyListeners();
  }


  Future<void> fetchProductsByCategory(int categoryId) async {
    try {
      final response = await _api.productsApi.getProductByCategory("$categoryId");

      if (response.success && response.data != null) {
        final List<dynamic> productList = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);

        _productsByCategory = productList
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .toList();

        notifyListeners();
      } else {
        debugPrint("⚠️ No products found for category $categoryId: ${response.error}");
      }
    } catch (e) {
      debugPrint("⚠️ Error loading products by category: $e");
    }
  }

  // Add category manually
  void addCategory(CategoryModel category) {
    _categories.add(category);
    notifyListeners();
  }
}
