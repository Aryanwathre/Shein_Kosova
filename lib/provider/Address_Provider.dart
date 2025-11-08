import 'package:flutter/material.dart';
import '../models/AddressModel.dart';
import '../services/api_service.dart';

enum AddressState {
  initial,
  loading,
  loaded,
  error,
  adding,
  updating,
  deleting,
}

class AddressProvider extends ChangeNotifier {
  final ApiServiceManager _apiManager = ApiServiceManager();

  List<AddressModel> _addresses = [];
  AddressState _state = AddressState.initial;
  String? _errorMessage;

  // Getters
  List<AddressModel> get addresses => _addresses;
  AddressState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AddressState.loading || _state == AddressState.adding || _state == AddressState.updating;
  bool get isEmpty => _addresses.isEmpty && _state == AddressState.loaded;

  AddressModel? getAddressById(String id) {
    try {
      return _addresses.firstWhere((address) => address.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Load addresses from the API
  Future<void> loadAddresses({bool showLoading = true}) async {
    if (showLoading) _setState(AddressState.loading);

    try {
      final apiResponse = await _apiManager.addressApi.getAddress();

      if (apiResponse.success && apiResponse.data != null) {
        final data = apiResponse.data!;

        // Since your API returns a plain List
        _addresses = data
            .map((json) => AddressModel.fromJson(json))
            .toList();

        _setState(AddressState.loaded);
        _clearError();
      } else {
        _setError(apiResponse.message ?? 'Failed to load addresses');
      }
    } catch (e) {
      _setError('Failed to parse response: $e');
    }
  }

  /// Add a new address using the fields that match the API.
  Future<bool> addAddress({
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String country,
    required String postalCode,
  }) async {
    _setState(AddressState.adding);
    try {
      final response = await _apiManager.addressApi.addAddress(
        addressLine1: addressLine1,
        addressLine2: addressLine2 ?? '',
        city: city,
        state: state,
        country: country,
        postalCode: postalCode,
      );

      if (response.success) {
        await loadAddresses(showLoading: false);
        return true;
      } else {
        _setError(response.error ?? 'Failed to add address');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  /// Update an existing address.
  Future<bool> updateAddress({
    required String id,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    bool? isDefault,
  }) async {
    _setState(AddressState.updating);
    try {
      final response = await _apiManager.addressApi.updateAddress(
        id: id,
        addressLine1: addressLine1,
        addressLine2: addressLine2 ?? '',
        city: city,
        state: state,
        country: country,
        postalCode: postalCode,
      );

      if (response.success) {
        await loadAddresses(showLoading: false);
        return true;
      } else {
        _setError(response.error ?? 'Failed to update address');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  Future<bool> removeAddress(String id) async {
    _setState(AddressState.deleting);
    try {
      final response = await _apiManager.addressApi.deleteAddress(id: id);
      if (response.success) {
        _addresses.removeWhere((a) => a.id == id);
        _setState(AddressState.loaded);
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete address');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  List<AddressModel> searchAddresses(String query) {
    if (query.isEmpty) return _addresses;
    final lowerQuery = query.toLowerCase();
    return _addresses.where((address) {
      return address.addressLine1.toLowerCase().contains(lowerQuery) ||
          address.addressLine2.toLowerCase().contains(lowerQuery) ||
          address.city.toLowerCase().contains(lowerQuery) ||
          address.state.toLowerCase().contains(lowerQuery) ||
          address.country.toLowerCase().contains(lowerQuery) ||
          address.postalCode.contains(lowerQuery);
    }).toList();
  }

  void _setState(AddressState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(AddressState.error);
    debugPrint("AddressProvider Error: $error");
  }

  void _clearError() {
    _errorMessage = null;
  }
}
