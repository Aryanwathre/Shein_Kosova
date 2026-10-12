import 'package:flutter/material.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/services/api_service.dart';

class CategoryProvider extends ChangeNotifier {
  // Category list
  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  // Products indexed by categoryId to prevent tab bleeding
  final Map<int, List<ProductModel>> _categoryProductsMap = {};
  final Map<int, bool> _loadingMap = {};

  // API manager
  final ApiServiceManager _api = ApiServiceManager();

  // Pagination state
  int _currentPage = 0;
  bool _hasMorePages = true;
  bool get hasMorePages => _hasMorePages;

  bool isFetchingNextPage = false;

  // Get products for a specific category
  List<ProductModel> getProductsForCategory(int categoryId) => _categoryProductsMap[categoryId] ?? [];
  bool isCategoryLoading(int categoryId) => _loadingMap[categoryId] ?? false;

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

        if (newItems.isEmpty) {
          _hasMorePages = false;
        } else {
          if (append) {
            _categories.addAll(newItems);
          } else {
            _categories = newItems;
          }
          _currentPage++;
        }
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
    // If we already have data and it's not loading, don't re-fetch unless forced
    if (_categoryProductsMap.containsKey(categoryId) && !(_loadingMap[categoryId] ?? false)) {
      return;
    }

    _loadingMap[categoryId] = true;
    notifyListeners();

    try {
      final response = await _api.productsApi.getProductByCategory("$categoryId");

      if (response.success && response.data != null) {
        final List<dynamic> productList = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);

        _categoryProductsMap[categoryId] = productList
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .toList();
      } else {
        _categoryProductsMap[categoryId] = [];
      }
    } catch (e) {
      debugPrint("⚠️ Error loading products by category: $e");
      _categoryProductsMap[categoryId] = [];
    } finally {
      _loadingMap[categoryId] = false;
      notifyListeners();
    }
  }

  void addCategory(CategoryModel category) {
    _categories.add(category);
    notifyListeners();
  }
}
