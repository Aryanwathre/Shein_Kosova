import 'package:flutter/material.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'dart:async';

import '../models/CartItemModel.dart';
import '../models/ProductModel.dart';
import '../models/SearchModel.dart';
import '../services/api_service.dart';

enum SearchState {
  initial,
  loading,
  loaded,
  error,
}

class SearchProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  // --- Search State ---
  List<ProductModel> _searchResults = [];
  List<CategoryModel> _searchCategoryResults = [];
  SearchState _state = SearchState.initial;
  String? _errorMessage;
  Timer? _debounce;
  String? _selectedSize;
  int _quantity = 1;


  // --- Filters and Pagination ---
  String? _query = '';
  String? _categoryId;

  double _minPossiblePrice = 0;
  double _maxPossiblePrice = 1000;

  late RangeValues _priceRange =  RangeValues(_minPossiblePrice, _maxPossiblePrice);

  double? _minPrice;
  double? _maxPrice;
  double _minRating = 0.0;

  int _page = 0;
  int? _currentPage;
  int _size = 20;

  // ⭐ MODIFIED — SORT KEYS
  String _sortKey = "relevance";          // relevance | low_to_high | high_to_low | rating
  String? _sortBy;                        // backend field
  String? _sortDir;                       // asc | desc

  // --- Cart ---
  final List<CartItem> _cart = [];

  // --- Getters ---
  List<ProductModel> get searchResults => _searchResults;
  List<CategoryModel> get searchCategoryResults => _searchCategoryResults;
  SearchState get state => _state;
  String? get errorMessage => _errorMessage;
  int? get currentPage => _currentPage;

  RangeValues get priceRange => _priceRange;
  double get minPossiblePrice => _minPossiblePrice;
  double get maxPossiblePrice => _maxPossiblePrice;

  String? get query => _query;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  double? get minRating => _minRating;
  String get sortKey => _sortKey;
  String? get sortBy => _sortBy;
  String? get sortDir => _sortDir;

  String? get selectedSize => _selectedSize;
  int get quantity => _quantity;
  List<CartItem> get cart => _cart;

  ProductModel? selectedProductDetails;
  bool isLoadingProductDetails = false;

  // ⭐ ADDED: Map frontend sort → backend sort
  void _mapSortKey() {
    switch (_sortKey) {
      case "low_to_high":
        _sortBy = "price";
        _sortDir = "asc";
        break;
      case "high_to_low":
        _sortBy = "price";
        _sortDir = "desc";
        break;
      default: // relevance
        _sortBy = null;
        _sortDir = null;
    }
  }


  // ⭐ ADDED
  void setSortKey(String key) {
    _sortKey = key;
    _mapSortKey();
    applyFilters();
    notifyListeners();
  }

  // ============================
  // CATEGORY FIX — DO NOT REMOVE CATEGORY
  // ============================
  void setCategoryId(String? categoryId) {
    _categoryId = categoryId;
    applyFilters();
    notifyListeners();
  }

  // ============================
  // PRODUCT DETAILS
  // ============================
  Future<void> fetchProductDetails(String productId) async {
    try {
      isLoadingProductDetails = true;
      notifyListeners();

      final response = await _api.productsApi.getProductById(productId: productId);

      if (response.success && response.data != null) {
        selectedProductDetails = ProductModel.fromJson(response.data!);
      }
    } catch (e) {
      debugPrint("❌ Error fetching product details: $e");
    } finally {
      isLoadingProductDetails = false;
      notifyListeners();
    }
  }

  // ============================
  // MAIN SEARCH
  // ============================
  void search({
    String? query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int? page,
    int? size,
    String? sortBy,
    String? sortDir,
    String? sizeRange,
  }) {
    _query = query ?? _query;
    _minPrice = minPrice ?? _minPrice;
    _maxPrice = maxPrice ?? _maxPrice;
    _minRating = minRating ?? _minRating;
    _page = page ?? _page;
    _size = size ?? _size;
    _categoryId = categoryId ?? _categoryId;
    _selectedSize = sizeRange ?? _selectedSize;

    _mapSortKey();

    _triggerDebouncedSearch();
  }

  // ============================
  // CATEGORY SEARCH ONLY
  // ============================
  void searchCategory({String? query}) {
    _query = query;
    _triggerDebouncedCategorySearch();
  }

  // ============================
  // TRIGGER SEARCH (DEBOUNCED)
  // ============================
  void _triggerDebouncedSearch() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _fetchSearchResults);
  }

  void _triggerDebouncedCategorySearch() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _fetchCategorySearchResults);
  }

  // ============================
  // API CALL REAL SEARCH
  // ============================
  Future<void> _fetchSearchResults() async {
    _setState(SearchState.loading);

    try {
      final response = await _api.searchApi.searchProducts(
        query: _query,
        categoryId: _categoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        page: _page,
        size: _size,
        sortBy: _sortBy,
        sortDir: _sortDir,
        sizeRange: _selectedSize,

      );

      if (response.success && response.data != null) {
        final searchResponse = SearchResponseModel.fromJson(response.data!);
        _searchResults = searchResponse.content;
        _currentPage = searchResponse.pageable.pageNumber;
        _errorMessage = null;
        _setState(SearchState.loaded);
      } else {
        _searchResults = [];
        _setError(response.error ?? 'Failed to fetch search results.');
      }
    } catch (e) {
      _searchResults = [];
      _setError('Failed to process search results: $e');
    }
  }

  // ============================
  // CATEGORY SEARCH
  // ============================
  Future<void> _fetchCategorySearchResults() async {
    _setState(SearchState.loading);

    try {
      final response = await _api.searchApi.getCategorySearch(
          query: _query!
      );

      if (response.success && response.data != null) {
        try {
          _searchCategoryResults = (response.data as List)
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList();

          _setState(SearchState.loaded);
        } catch (e) {
          _setError("Invalid category JSON structure");
        }
      } else {
        _searchCategoryResults = [];
        _setError(response.error ?? "No categories found.");
      }
    } catch (e) {
      _searchCategoryResults = [];
      _setError('Failed to fetch search results: $e');
    }
  }

  // ============================
  // FETCH SIZES FROM API
  // ============================
  Future<List<String>> fetchSizes() async {
    try {
      final response = await _api.sizesApi.getAvailableSizes();

      if (response.success && response.data != null) {
        final List<dynamic> raw = response.data!;

        return raw.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint("❌ fetchSizes() Error: $e");
    }

    return [];
  }


  void clearFilters({bool keepCategoryId = false, bool keepQuery = false}) {
    if (!keepQuery) _query = '';
    if (!keepCategoryId) _categoryId = null;
    
    _minPrice = null;
    _maxPrice = null;
    _minRating = 0.0;
    _selectedSize = null;

    _sortKey = "relevance";
    _mapSortKey();

    _page = 0;

    search();
    notifyListeners();
  }


  // ============================
  // FILTER SETTERS
  // ============================
  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void setMinPrice(double? value) {
    _minPrice = value;
    notifyListeners();
  }

  void setMaxPrice(double? value) {
    _maxPrice = value;
    notifyListeners();
  }

  void setMinRating(double value) {
    _minRating = value;
    notifyListeners();
  }


  void setPriceRange(double start, double end) {
    _priceRange = RangeValues(start, end);
    _minPrice = start;
    _maxPrice = end;

    applyFilters();
    notifyListeners();
  }

  void selectSize(String size) {
    _selectedSize = size;

    search(sizeRange: size);

    notifyListeners();
  }



  void updatePossiblePriceRange(double min, double max) {
    _minPossiblePrice = min;
    _maxPossiblePrice = max;

    if (_priceRange.start < min || _priceRange.end > max) {
      _priceRange = RangeValues(min, max);
    }

    notifyListeners();
  }

  // ⭐ REMOVED OLD SORT FUNCTIONS — replaced by setSortKey()

  void setPage(int page) {
    _page = page;
    notifyListeners();
  }



  void setSize(int size) {
    _size = size;
    notifyListeners();
  }

  // ============================
  // APPLY FILTERS
  // ============================
  void applyFilters() {
    _page = 0;
    search(categoryId: _categoryId,);
  }

  // ============================
  // RESET FILTERS
  // ============================
  void resetFilters() {
    _minPrice = null;
    _maxPrice = null;
    _minRating = 0.0;
    _sortKey = "relevance";
    _mapSortKey();
    _page = 0;
    search();
  }

  // ============================
  // INFINITE SCROLL SUPPORT
  // ============================
  Future<void> loadMore() async {
    _page++;

    try {
      final response = await _api.searchApi.searchProducts(
        query: _query,
        categoryId: _categoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        page: _page,
        size: _size,
        sortBy: _sortBy,
        sortDir: _sortDir,
      );

      if (response.success && response.data != null) {
        final searchResponse = SearchResponseModel.fromJson(response.data!);
        _searchResults.addAll(searchResponse.content);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ============================
  // SIZE + QUANTITY
  // ============================
  void setSelectedSize(String size) {
    _selectedSize = size;
    notifyListeners();
  }

  void increaseQuantity() {
    _quantity++;
    notifyListeners();
  }

  void decreaseQuantity() {
    if (_quantity > 1) {
      _quantity--;
      notifyListeners();
    }
  }

  void resetQuantity() {
    _quantity = 1;
    notifyListeners();
  }

  // ============================
  // CLEAR SEARCH
  // ============================
  void clearSearch() {
    _query = '';
    _searchResults = [];
    _errorMessage = null;
    _state = SearchState.initial;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void clearSearchResults() {
    _searchCategoryResults = [];
    _searchResults = [];
    _state = SearchState.initial;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }



  // ============================
  // HELPERS
  // ============================
  void _setState(SearchState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(SearchState.error);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
