import 'package:flutter/material.dart';
import 'dart:async';

import '../models/ProductModel.dart'; // Ensure the path is correct
import '../services/api_service.dart'; // Ensure the path is correct

enum SearchState {
  initial,
  loading,
  loaded,
  error,
}

class SearchProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  List<ProductModel> _searchResults = [];
  SearchState _state = SearchState.initial;
  String? _errorMessage;
  Timer? _debounce;

  // Getters for the UI
  List<ProductModel> get searchResults => _searchResults;
  SearchState get state => _state;
  String? get errorMessage => _errorMessage;

  void search(String query) {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    _setState(SearchState.loading);

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // This response.data will be a List<Map<String, dynamic>> because the parser in SearchApi already handled it.
        final response = await _api.searchApi.searchProducts(query: query);

        if (response.success && response.data != null) {
          // --- FIX IS HERE ---
          // The response.data is already the list we need. No need to look for 'content'.
          final List<Map<String, dynamic>> productListData = response.data!;

          _searchResults = productListData.map((item) => ProductModel.fromJson(item)).toList();

          _errorMessage = null;
          _setState(SearchState.loaded);
        } else {
          _searchResults = [];
          _setError(response.error ?? 'Failed to fetch search results.');
        }
      } catch (e) {
        _searchResults = [];
        _setError('Failed to process search results: ${e.toString()}');
      }
    });
  }

  void clearSearch() {
    _searchResults = [];
    _errorMessage = null;
    _setState(SearchState.initial);
    if (_debounce?.isActive ?? false) _debounce?.cancel();
  }

  // --- State Management Helpers ---
  void _setState(SearchState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(SearchState.error);
    debugPrint("SearchProvider Error: $error");
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
