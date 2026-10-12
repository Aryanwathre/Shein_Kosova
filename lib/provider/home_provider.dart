import 'package:flutter/material.dart';
import 'package:shein_kosova/models/BannerModel.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/models/store_model.dart';
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

  /// Brands for the home "Top Brands" grid (first 12; "See All" shows the rest).
  List<StoreModel> _stores = [];
  List<StoreModel> get stores => _stores;

  List<String> _tags = [];
  List<String> get tags => _tags;

  String _selectedTag = "All";
  String get selectedTag => _selectedTag;

  // Products indexed by categoryId
  final Map<int, List<ProductModel>> _categoryProductsMap = {};
  final Map<int, bool> _categoryLoadingMap = {};

  /// Infinite-scroll state, per category id (0 = the "All" tab).
  static const int _pageSize = 20;
  final Map<int, int> _categoryPageMap = {};
  final Map<int, bool> _categoryHasMoreMap = {};
  final Map<int, bool> _categoryLoadingMoreMap = {};

  /// True while a *subsequent* page is in flight, as opposed to the first
  /// load — the two need different UI (footer spinner vs full shimmer).
  bool isCategoryLoadingMore(int categoryId) =>
      _categoryLoadingMoreMap[categoryId] ?? false;

  bool categoryHasMore(int categoryId) =>
      _categoryHasMoreMap[categoryId] ?? false;

  // Products indexed by tag name (including "All", "For You" and "Deals" from HomeApi)
  final Map<String, List<ProductModel>> _taggedProductsMap = {};
  final Map<String, bool> _tagLoadingMap = {};

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Added products getter to support Web UI and maintain backward compatibility if needed
  List<ProductModel> get products => _categoryProductsMap[0] ?? [];

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

  // Convenience getters for the dedicated home sections.
  List<ProductModel> get dealsProducts => _taggedProductsMap["Deals"] ?? [];
  List<ProductModel> get trendingProducts => _taggedProductsMap["Trending"] ?? [];

  Future<void> initHome({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      _state = HomeState.loading;
      notifyListeners();
    } else {
      // Clear specific caches on force refresh to ensure new data is pulled
      _categoryProductsMap.clear();
      _taggedProductsMap.clear();
    }

    try {
      // 1. Prioritize and await core data for immediate display
      await Future.wait([
        _fetchBanners(),
        _fetchStores(),
        fetchProductsByCategory(0, forceRefresh: forceRefresh), // Load "All" products immediately
      ]);
      
      _state = HomeState.loaded;
      notifyListeners();

      // 2. Load background data without awaiting
      _fetchTags();
      _fetchForYou(forceRefresh: forceRefresh);
      _fetchDeals(forceRefresh: forceRefresh);
      fetchProductsByTag("Trending", forceRefresh: forceRefresh); // for the Trending section

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
      await fetchProductsByTag(tag);
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

  Future<void> _fetchStores() async {
    try {
      final response = await _api.storesApi.getStores(page: 0, size: 12);
      if (response.success && response.data != null) {
        _stores = response.data!;
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching stores: $e");
    }
  }

  // No longer called by initHome: the home category tabs were replaced by the
  // brands grid (each brand has its own categories). Kept for other callers.
  // ignore: unused_element
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
        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching tags: $e");
    }
  }

  Future<void> _fetchForYou({bool forceRefresh = false}) async {
    if (!await _api.isUserLoggedIn()) return;

    if (!forceRefresh && _taggedProductsMap.containsKey("For You") && !(_tagLoadingMap["For You"] ?? false)) return;
    
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

  Future<void> _fetchDeals({bool forceRefresh = false}) async {
    if (!forceRefresh && _taggedProductsMap.containsKey("Deals") && !(_tagLoadingMap["Deals"] ?? false)) return;

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

  Future<void> fetchProductsByTag(String tag, {bool forceRefresh = false}) async {
    // Keep internal key as the original tag name to match with _TagSelector UI
    final key = tag;
    if (!forceRefresh && _taggedProductsMap.containsKey(key) && !(_tagLoadingMap[key] ?? false)) {
      return;
    }

    _tagLoadingMap[key] = true;
    notifyListeners();

    try {
      // API requires lowercase tag name (e.g., "trending")
      final response = await _api.homeApi.getProductsByTag(tag.toLowerCase());
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

  /// Loads the first page for a category.
  ///
  /// Uses products/search rather than products / products/category, because
  /// those return a bare array with no paging metadata — there is no way to
  /// know whether more exists. search returns `last`, which drives loadMore.
  Future<void> fetchProductsByCategory(int categoryId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _categoryProductsMap.containsKey(categoryId) && !(_categoryLoadingMap[categoryId] ?? false)) {
      return;
    }

    _categoryLoadingMap[categoryId] = true;
    notifyListeners();

    try {
      final response = await _api.searchApi.searchProducts(
        categoryId: categoryId == 0 ? null : "$categoryId",
        page: 0,
        size: _pageSize,
      );

      if (response.success && response.data != null) {
        final List<dynamic> content = response.data!['content'] ?? [];

        _categoryProductsMap[categoryId] = content
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .toList();
        _categoryPageMap[categoryId] = 0;
        // Stop on an empty page too, so a malformed `last` can't loop forever.
        _categoryHasMoreMap[categoryId] =
            !(response.data!['last'] ?? true) && content.isNotEmpty;
      } else {
        _categoryProductsMap[categoryId] = [];
        _categoryHasMoreMap[categoryId] = false;
      }
    } catch (e) {
      debugPrint("⚠️ Error loading products for category $categoryId: $e");
      _categoryProductsMap[categoryId] = [];
      _categoryHasMoreMap[categoryId] = false;
    } finally {
      _categoryLoadingMap[categoryId] = false;
      notifyListeners();
    }
  }

  /// Appends the next page. No-op when already busy or exhausted, so the
  /// scroll listener can call it freely.
  Future<void> loadMoreForCategory(int categoryId) async {
    if (_categoryLoadingMoreMap[categoryId] == true) return;
    if (!(_categoryHasMoreMap[categoryId] ?? false)) return;
    if (_categoryLoadingMap[categoryId] == true) return;

    _categoryLoadingMoreMap[categoryId] = true;
    notifyListeners();

    final nextPage = (_categoryPageMap[categoryId] ?? 0) + 1;

    try {
      final response = await _api.searchApi.searchProducts(
        categoryId: categoryId == 0 ? null : "$categoryId",
        page: nextPage,
        size: _pageSize,
      );

      if (response.success && response.data != null) {
        final List<dynamic> content = response.data!['content'] ?? [];
        final fetched = content
            .map<ProductModel>((json) => ProductModel.fromJson(json))
            .toList();

        _categoryProductsMap[categoryId] = [
          ...?_categoryProductsMap[categoryId],
          ...fetched,
        ];
        _categoryPageMap[categoryId] = nextPage;
        _categoryHasMoreMap[categoryId] =
            !(response.data!['last'] ?? true) && fetched.isNotEmpty;
      } else {
        _categoryHasMoreMap[categoryId] = false;
      }
    } catch (e) {
      debugPrint("⚠️ Error loading more for category $categoryId: $e");
      _categoryHasMoreMap[categoryId] = false;
    } finally {
      _categoryLoadingMoreMap[categoryId] = false;
      notifyListeners();
    }
  }
}
