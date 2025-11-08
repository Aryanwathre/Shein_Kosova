import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shein_kosova/services/api_service.dart';

import '../models/Category.dart';
import '../models/ProductModel.dart';

class HomeProvider extends ChangeNotifier {
  List<Category> _categories = [];
  ApiServiceManager _api = ApiServiceManager();
  int _currentPage = 0;
  bool _hasMorePages = true;
  List<ProductModel> _productsByCategory = [];
  List<ProductModel> get productsByCategory => _productsByCategory;



  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;
  List<Category> get categories => _categories;

  /// Load categories from local JSON (assets/data/categories.json)
  Future<void> fetchCategories({int page = 0, int pageSize = 20, bool append = false}) async {
    try {
      // ✅ Call your API with pagination params
      final response = await _api.categoriesApi.getCategories(page: page, size: pageSize);

      if (response.success && response.data != null) {
        final newCategories = response.data!.content;

        if (append) {
          // ✅ Append for next pages
          _categories.addAll(newCategories);
        } else {
          // ✅ Replace for first page
          _categories = newCategories;
        }

        _hasMorePages = !response.data!.last; // from API JSON
        _currentPage = response.data!.pageable!.pageNumber;

        notifyListeners();
        debugPrint('✅ Loaded ${newCategories.length} categories (Page: $_currentPage)');
      } else {
        debugPrint('❌ Failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading categories: $e');
    }
  }

  Future<void> FetchProductsByCategory(int categoryId) async {
    try {
      final response = await _api.productsApi.getProductByCategory("$categoryId");
      if (response is String && response.isNotEmpty) {
        final decoded = jsonDecode(response);
        final List<dynamic> productList =
        decoded is List ? decoded : (decoded['data'] ?? []);
        _productsByCategory = productList
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        debugPrint('No products found for category');
      }
    } catch (e) {
      debugPrint('Error loading products by category: $e');
    }
}

  /// Add a new category (useful for admin or local testing)
  void addCategory(Category category) {
    _categories.add(category);
    notifyListeners();
  }
}