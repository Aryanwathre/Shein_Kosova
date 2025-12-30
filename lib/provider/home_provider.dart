import 'package:flutter/material.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/models/BannerModel.dart';
import 'package:shein_kosova/services/api_service.dart';

enum HomeState { initial, loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  HomeState _state = HomeState.initial;
  HomeState get state => _state;

  List<BannerModel> _banners = [];
  List<BannerModel> get banners => _banners;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  List<String> _tags = [];
  List<String> get tags => _tags;

  String _selectedTag = "All";
  String get selectedTag => _selectedTag;

  // Products indexed by categoryId
  final Map<int, List<ProductModel>> _categoryProductsMap = {};
  final Map<int, bool> _categoryLoadingMap = {};

  // Products indexed by tag name (including "All", "For You" and "Deals" from HomeApi)
  final Map<String, List<ProductModel>> _taggedProductsMap = {};
  final Map<String, bool> _tagLoadingMap = {};

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ProductModel> getProductsForCategory(int categoryId) => _categoryProductsMap[categoryId] ?? [];
  bool isCategoryLoading(int categoryId) => _categoryLoadingMap[categoryId] ?? false;

  List<ProductModel> getProductsForTag(String tag) {
    if (tag == "All") return _categoryProductsMap[0] ?? [];
    return _taggedProductsMap[tag] ?? [];
  }
  
  bool isTagLoading(String tag) {
    if (tag == "All") return _categoryLoadingMap[0] ?? false;
    return _tagLoadingMap[tag] ?? false;
  }

  Future<void> initHome() async {
    _state = HomeState.loading;
    notifyListeners();

    try {
      await Future.wait([
        _fetchBanners(),
        _fetchAllCategories(),
        _fetchTags(),
      ]);
      
      // Default tag selection is now "All"
      await setSelectedTag("All");
      
      _state = HomeState.loaded;
    } catch (e) {
      _errorMessage = 'An error occurred during initialization: $e';
      _state = HomeState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> setSelectedTag(String tag) async {
    _selectedTag = tag;
    notifyListeners();
    
    if (tag == "All") {
      await fetchProductsByCategory(0);
    } else if (tag == "For You") {
      await _fetchForYou();
    } else if (tag == "Deals") {
      await _fetchDeals();
    } else {
      // It's a dynamic tag from products/tags (e.g., "trending")
      await fetchProductsByTag(tag.toLowerCase());
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await _api.homeApi.getAllBanners();
      if (response.success && response.data != null) {
        _banners = (response.data as List)
            .map((item) => BannerModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching banners: $e");
    }
  }

  Future<void> _fetchAllCategories() async {
    int page = 0;
    bool hasMore = true;
    final List<CategoryModel> temp = [];

    try {
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
    } catch (e) {
      debugPrint("⚠️ Error fetching categories: $e");
    }
  }

  Future<void> _fetchTags() async {
    try {
      final response = await _api.homeApi.getProductsTags();
      if (response.success && response.data != null) {
        _tags = response.data!;
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching tags: $e");
    }
  }

  Future<void> _fetchForYou() async {
    if (_taggedProductsMap.containsKey("For You") && !(_tagLoadingMap["For You"] ?? false)) return;
    
    _tagLoadingMap["For You"] = true;
    notifyListeners();
    try {
      final response = await _api.homeApi.getForYouProducts();
      if (response.success && response.data != null) {
        final List<dynamic> content = response.data['content'] ?? [];
        _taggedProductsMap["For You"] = content.map((json) => ProductModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching for-you products: $e");
    } finally {
      _tagLoadingMap["For You"] = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDeals() async {
    if (_taggedProductsMap.containsKey("Deals") && !(_tagLoadingMap["Deals"] ?? false)) return;

    _tagLoadingMap["Deals"] = true;
    notifyListeners();
    try {
      final response = await _api.homeApi.getDeals();
      if (response.success && response.data != null) {
        final List<dynamic> content = response.data['content'] ?? [];
        _taggedProductsMap["Deals"] = content.map((json) => ProductModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching deals: $e");
    } finally {
      _tagLoadingMap["Deals"] = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductsByTag(String tag) async {
    final key = tag.toLowerCase();
    if (_taggedProductsMap.containsKey(key) && !(_tagLoadingMap[key] ?? false)) {
      return;
    }

    _tagLoadingMap[key] = true;
    notifyListeners();

    try {
      final response = await _api.homeApi.getProductsByTag(key);
      if (response.success && response.data != null) {
        final List<dynamic> content = response.data['content'] ?? [];
        _taggedProductsMap[key] = content.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        _taggedProductsMap[key] = [];
      }
    } catch (e) {
      debugPrint("⚠️ Error loading products for tag $tag: $e");
      _taggedProductsMap[key] = [];
    } finally {
      _tagLoadingMap[key] = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductsByCategory(int categoryId) async {
    if (_categoryProductsMap.containsKey(categoryId) && !(_categoryLoadingMap[categoryId] ?? false)) {
      return;
    }

    _categoryLoadingMap[categoryId] = true;
    notifyListeners();

    try {
      ApiResponse response;
      if (categoryId == 0) {
        response = await _api.productsApi.getProducts();
      } else {
        response = await _api.productsApi.getProductByCategory("$categoryId");
      }

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
      debugPrint("⚠️ Error loading products for category $categoryId: $e");
      _categoryProductsMap[categoryId] = [];
    } finally {
      _categoryLoadingMap[categoryId] = false;
      notifyListeners();
    }
  }
}
