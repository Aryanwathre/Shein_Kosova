import 'package:flutter/material.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/services/api_service.dart';

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
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }


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

  /// Set the product for the details page and initialize its state
  void setProduct(ProductModel product) {
    _product = product;

    _selectedImageIndex = 0;
    _quantity = 1;
    _selectedColor = product.colors;
    _selectedSize = null; // Don't pre-select size
    _isWishlisted = false; // Fetch real wishlist status from API if needed
    notifyListeners();
  }

  Future<void> getProductByID(int productId) async {
    _setListState(ProductListState.loading);
    notifyListeners();
    try{
      final responseBody = await _api.productsApi.getProductById(productId: productId.toString());
      if(responseBody.success && responseBody.data != null){
        final products = ProductModel.fromJson(responseBody.data!);
        _product = products;
        _selectedColor = _product?.colors;
        _selectedSize = null; // Don't pre-select size
        _setListState(ProductListState.loaded);
      } else {
        _product = null;
        _setListError(responseBody.error ?? 'Product not found');
      }
    }catch (e) {
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
      final response = await _api.productsApi.getProductByCategory('$categoryID');

      if (response.success && response.data != null) {
        final List<dynamic> productList = response.data is List 
            ? response.data 
            : (response.data['data'] ?? []);

        final products = productList
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .where((product) => product.id != currentProductId)
            .toList();

        _categoryProducts = products;
        _setListState(ProductListState.loaded);

        debugPrint('✅ Loaded ${products.length} products for category $categoryID (removed product: $currentProductId)');
      } else {
        _setListError(response.error ?? 'No products found');
        debugPrint('⚠️ Error response for category $categoryID: ${response.error}');
      }
    } catch (e) {
      _setListError('Network error: ${e.toString()}');
      debugPrint('⚠️ Exception: $e');
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
    _categoryProducts = [];
    _isLoading = false;
    // Note: notifyListeners() is omitted here because this is called during dispose()
    // and calling it would throw "setState() or markNeedsBuild() called when widget tree was locked".
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
