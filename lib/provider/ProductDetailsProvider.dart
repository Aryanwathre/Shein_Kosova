import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/ProductModel.dart';
import '../services/api_service.dart';

enum ProductListState { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  // --- State for Product Listing ---
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _categoryProducts = [];
  ProductListState _listState = ProductListState.initial;
  String? _listErrorMessage;
  String _selectedSort = "Relevance";

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get categoryProducts => _categoryProducts;
  ProductListState get listState => _listState;
  String? get listErrorMessage => _listErrorMessage;
  String get selectedSort => _selectedSort;

  // --- State for Single Product Details ---
  ProductModel? _product;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  String? _selectedColor;
  String? _selectedSize;
  bool _isWishlisted = false;

  ProductModel? get product => _product;
  int get selectedImageIndex => _selectedImageIndex;
  int get quantity => _quantity;
  String? get selectedColor => _selectedColor;
  String? get selectedSize => _selectedSize;
  bool get isWishlisted => _isWishlisted;

  // --- API Methods for Product List ---

  /// Fetch all products for the listing/grid page
  Future<void> fetchAllProducts() async {
    _setListState(ProductListState.loading);
    try {
      final response = await _api.productsApi.getProducts();
      if (response is String && response.isNotEmpty) {
        final decoded = jsonDecode(response);
        final List<dynamic> productList =
            decoded is List ? decoded : (decoded['data'] ?? []);
        _allProducts = productList
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .toList();
        _filteredProducts = List.from(_allProducts);
        _setListState(ProductListState.loaded);
      } else {
        _setListError('No products found');
      }

    } catch (e) {
      _setListError('A network error occurred: ${e.toString()}');
    }
  }

  // --- Methods for Product Details Page ---

  /// Set the product for the details page and initialize its state
  void setProduct(ProductModel product) {
    _product = product;
    // Reset state whenever a new product is set
    _selectedImageIndex = 0;
    _quantity = 1;
    _selectedColor = product.colors!.isNotEmpty ? product.colors!.first : null;
    _selectedSize = product.sizes!.isNotEmpty ? product.sizes!.first : null;
    _isWishlisted = false; // Fetch real wishlist status from API if needed
    notifyListeners();
  }

  // --- UI and Filter/Sort Methods ---

  void sortProducts(String sortBy) {
    _selectedSort = sortBy;
    if (sortBy == "Price: Low to High") {
      _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == "Price: High to Low") {
      _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
    } else {
      _filteredProducts = List.from(_allProducts);
    }
    notifyListeners();
  }

  void filterByCategory(String categoryId) {
    if (categoryId == "All") {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts =
          _allProducts.where((p) => p.category.id == categoryId).toList();
    }
    notifyListeners();
  }

  Future<void> getProductByCode(int categoryID, int? currentProductId) async {
    _setListState(ProductListState.loading);

    _categoryProducts = [];
    notifyListeners();

    try {
      final responseBody = await _api.productsApi.getProductByCategory('$categoryID');

      if (responseBody is String && responseBody.isNotEmpty) {
        final decoded = jsonDecode(responseBody);

        final List<dynamic> productList =
        decoded is List ? decoded : (decoded['data'] ?? []);

        final products = productList
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .where((product) => product.id != currentProductId)
            .toList();

        _categoryProducts = products;
        _setListState(ProductListState.loaded);

        print('✅ Loaded ${products.length} products for category $categoryID (removed product: $currentProductId)');
      } else {
        _setListError('No products found');
        print('⚠️ Empty or invalid response for category $categoryID');
      }
    } catch (e) {
      _setListError('Network error: ${e.toString()}');
      print('⚠️ Exception: $e');
    }
  }

  void changeImage(int index) {
    _selectedImageIndex = index;
    notifyListeners();
  }

  void increaseQuantity() {
    _quantity++;
    notifyListeners();
  }

  void decreaseQuantity() {
    if (_quantity > 1) {
      _quantity--;
    }
    notifyListeners();
  }

  void selectColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  void selectSize(String size) {
    _selectedSize = size;
    notifyListeners();
  }

  // --- State Management Helpers ---

  void _setListState(ProductListState state) {
    _listState = state;
    notifyListeners();
  }

  void _setListError(String error) {
    _listErrorMessage = error;
    _setListState(ProductListState.error);
  }
}
