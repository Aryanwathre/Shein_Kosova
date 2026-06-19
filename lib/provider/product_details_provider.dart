import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/services/api_service.dart';

enum ProductListState { initial, loading, loaded, error }

// Parse & filter large category payload in background isolate to avoid jank
List<ProductModel> _parseAndFilterCategory(Map<String, dynamic> args) {
  final List<dynamic> raw = args['list'] as List<dynamic>;
  final int? excludeId = args['excludeId'] as int?;
  final List<ProductModel> parsed = raw.map<ProductModel>((json) {
    final Map<String, dynamic> m = json as Map<String, dynamic>;
    final int id = m['id'] is String ? int.tryParse(m['id']) ?? 0 : (m['id'] ?? 0);
    final double price = m['price'] is String
        ? double.tryParse(m['price']) ?? 0.0
        : (m['price'] as num?)?.toDouble() ?? 0.0;
    final double avg = m['averageRating'] is String
        ? double.tryParse(m['averageRating']) ?? 0.0
        : (m['averageRating'] as num?)?.toDouble() ?? 0.0;
    final category = m['category'] != null
        ? CategoryModel.fromJson(m['category'] as Map<String, dynamic>)
        : CategoryModel.object();

    return ProductModel(
      id: id,
      code: m['code'] ?? '',
      name: m['name'] ?? '',
      brand: null,
      description: '',
      price: price,
      averageRating: avg,
      enabled: m['enabled'] ?? false,
      category: category,
      mainImageUrl: (m['mainImageUrl'] as String?)?.trim() ?? '',
      detailImages: const [],
      colors: null,
      sizes: const [],
      variants: const [],
      tag: m['tag'] ?? '',
      reviews: const [],
    );
  }).toList();

  if (excludeId != null) return parsed.where((p) => p.id != excludeId).toList();
  return parsed;
}


class ProductProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  // --- State for Product Listing ---
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  
  // --- Category Products (Related Products) Pagination Logic ---
  List<ProductModel> _rawCategoryProducts = []; // The full list from API
  List<ProductModel> _visibleCategoryProducts = []; // The subset shown in UI
  final int _pageSize = 15;
  int _visibleCount = 0;
  bool _isLoadingMoreCategory = false;

  ProductListState _listState = ProductListState.initial;
  String? _listErrorMessage;
  String _selectedSort = "Relevance";
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get categoryProducts => _visibleCategoryProducts;
  ProductListState get listState => _listState;
  String? get listErrorMessage => _listErrorMessage;
  String get selectedSort => _selectedSort;
  
  bool get isLoadingMoreCategory => _isLoadingMoreCategory;
  bool get hasMoreCategoryProducts => _visibleCount < _rawCategoryProducts.length;

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

  Future<void> fetchAllProducts() async {
    _setListState(ProductListState.loading);
    try {
      final response = await _api.productsApi.getProducts();
      
      if (response.success && response.data != null) {
        final List<dynamic> productList = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);
            
        _allProducts = productList
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .toList();
        _filteredProducts = List.from(_allProducts);
        _setListState(ProductListState.loaded);
      } else {
        _setListError(response.error ?? 'No products found');
      }
    } catch (e) {
      _setListError('A network error occurred: ${e.toString()}');
    }
  }

  // --- Methods for Product Details Page ---

  void setProduct(ProductModel product) {
    _product = product;
    _selectedImageIndex = 0;
    _quantity = 1;
    _selectedColor = product.colors;
    _selectedSize = null;
    _isWishlisted = false;
    notifyListeners();
  }

  Future<void> getProductByID(int productId) async {
    _setListState(ProductListState.loading);
    notifyListeners();
    try {
      final responseBody = await _api.productsApi.getProductById(productId: productId.toString());
      if (responseBody.success && responseBody.data != null) {
        _product = ProductModel.fromJson(responseBody.data!);
        _selectedColor = _product?.colors;
        _selectedSize = null;
        _setListState(ProductListState.loaded);
      } else {
        _product = null;
        _setListError(responseBody.error ?? 'Product not found');
      }
    } catch (e) {
      _product = null;
      _setListError('Network error: ${e.toString()}');
      debugPrint('⚠️ Exception: $e');
    }
  }

  Future<bool> submitReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await _api.reviewsApi.addReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );

      if (response.success) {
        await getProductByID(int.parse(productId));
        notifyListeners();
        return true;
      } else {
        _setListError("Failed to add review: ${response.error}");
        return false;
      }
    } catch (e) {
      _setListError("Error submitting review: $e");
      return false;
    }
  }

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

  /// Fetches all products for the category and initializes the client-side lazy loading.
  Future<void> getProductByCode(int categoryID, int? currentProductId) async {
    _setListState(ProductListState.loading);
    _rawCategoryProducts = [];
    _visibleCategoryProducts = [];
    _visibleCount = 0;
    notifyListeners();

    try {
      final response = await _api.productsApi.getProductByCategory('$categoryID');

      if (response.success && response.data != null) {
        final List<dynamic> productList = response.data is List
            ? response.data
            : (response.data['data'] ?? []);

        // Parse & filter in background isolate to avoid blocking UI
        try {
          final args = {'list': productList, 'excludeId': currentProductId};
          _rawCategoryProducts = await compute(_parseAndFilterCategory, args);
        } catch (e) {
          // Fallback to main-thread parsing if compute fails
          final parsed = productList
              .map<ProductModel>((json) => ProductModel.fromJson(json))
              .toList()
              .where((p) => p.id != currentProductId)
              .toList();
          _rawCategoryProducts = parsed;
        }

        // Initial load of the first chunk
        _loadNextCategoryChunk();
        
        _setListState(ProductListState.loaded);
        debugPrint('✅ Loaded ${_rawCategoryProducts.length} total products for category $categoryID. Initial visible: $_visibleCount');
      } else {
        _setListError(response.error ?? 'No products found');
      }
    } catch (e) {
      _setListError('Network error: ${e.toString()}');
      debugPrint('⚠️ Exception: $e');
    }
  }

  /// Client-side lazy loading: Slice the next batch from memory.
  void _loadNextCategoryChunk() {
    final nextVisibleCount = (_visibleCount + _pageSize).clamp(0, _rawCategoryProducts.length);
    if (nextVisibleCount > _visibleCount) {
      _visibleCategoryProducts = _rawCategoryProducts.sublist(0, nextVisibleCount);
      _visibleCount = nextVisibleCount;
    }
  }

  /// Triggered by UI scroll listener to load the next chunk.
  Future<void> loadMoreCategoryProducts() async {
    if (_isLoadingMoreCategory || !hasMoreCategoryProducts) return;

    _isLoadingMoreCategory = true;
    notifyListeners();

    // Artificial delay to make the "loading" feel natural and prevent UI jank 
    // when calculating/rendering even if data is in memory.
    await Future.delayed(const Duration(milliseconds: 300));

    _loadNextCategoryChunk();
    
    _isLoadingMoreCategory = false;
    notifyListeners();
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

  Future<void> fetchVariantById(int variantId) async {
    _setListState(ProductListState.loading);
    notifyListeners();

    try {
      final response = await _api.productsApi.getProductById(productId: '$variantId');
      if (response.success && response.data != null) {
        _product = ProductModel.fromJson(response.data!);
      }
    } catch (e) {
      debugPrint("Error fetching variant: $e");
    } finally {
      _setListState(ProductListState.loaded);
      notifyListeners();
    }
  }

  void resetDetails() {
    _product = null;
    _selectedSize = null;
    _selectedImageIndex = 0;
    _rawCategoryProducts = [];
    _visibleCategoryProducts = [];
    _visibleCount = 0;
    _isLoading = false;
  }

  void selectColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  void selectSize(String size) {
    _selectedSize = size;
    notifyListeners();
  }

  void _setListState(ProductListState state) {
    _listState = state;
    notifyListeners();
  }

  void _setListError(String error) {
    _listErrorMessage = error;
    _setListState(ProductListState.error);
  }
}
