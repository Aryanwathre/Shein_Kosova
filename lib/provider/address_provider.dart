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
  final ApiServiceManager _api = ApiServiceManager();

  AddressState _state = AddressState.initial;
  String? _errorMessage;

  AddressState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isLoading =>
      _state == AddressState.loading ||
          _state == AddressState.adding ||
          _state == AddressState.updating ||
          _state == AddressState.deleting;

  List<AddressModel> _addresses = [];
  List<AddressModel> get addresses => _addresses;


  // Selected Address
  String? _selectedAddressId;

  // Returns selected address OR default address
  AddressModel? get selectedAddress {
    if (_selectedAddressId == null) return defaultAddress;

    try {
      return _addresses.firstWhere((a) => a.id == _selectedAddressId);
    } catch (_) {
      return defaultAddress;
    }
  }

  bool get isEmpty => _addresses.isEmpty && _state == AddressState.loaded;

  void _setState(AddressState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = AddressState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> fetchAddresses() async {
    _setState(AddressState.loading);

    try {
      final res = await _api.addressApi.getAddress();

      if (res.success && res.data != null) {
        _addresses = res.data!
            .map<AddressModel>((e) => AddressModel.fromJson(e))
            .toList();

        /// Set selected address = default address
        _selectedAddressId = defaultAddress?.id;

        _clearError();
        _setState(AddressState.loaded);
      } else {
        _setError(res.error ?? "Failed to load addresses");
      }
    } catch (e) {
      _setError("Fetch error: $e");
    }
  }

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault == true);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      final selected = _addresses.firstWhere((e) => e.id == id);

      await _api.addressApi.updateAddress(
        id: selected.id,
        addressLine1: selected.addressLine1,
        addressLine2: selected.addressLine2,
        city: selected.city,
        state: selected.state,
        country: selected.country,
        postalCode: selected.postalCode,
        receiverName: selected.receiverName,
        contactNumber: selected.contactNumber,
        isDefault: true,
      );

      _addresses = _addresses.map((addr) {
        return addr.copyWith(isDefault: addr.id == id);
      }).toList();

      /// update selected too
      _selectedAddressId = id;

      notifyListeners();
    } catch (e) {
      _setError("Set default error: $e");
    }
  }

  void selectAddress(String id) {
    _selectedAddressId = id;
    notifyListeners();
  }

  Future<bool> addAddress(AddressModel newAddress) async {
    _setState(AddressState.adding);

    try {
      final res = await _api.addressApi.addAddress(
        addressLine1: newAddress.addressLine1,
        addressLine2: newAddress.addressLine2,
        city: newAddress.city,
        state: newAddress.state,
        country: newAddress.country,
        postalCode: newAddress.postalCode,
        receiverName: newAddress.receiverName,
        contactNumber: newAddress.contactNumber,
        isDefault: newAddress.isDefault,
      );

      if (res.success && res.data != null) {
        final added = AddressModel.fromJson(res.data!);
        _addresses.add(added);

        /// If this is default, auto-select it
        if (added.isDefault == true) {
          _selectedAddressId = added.id;
        }

        _clearError();
        _setState(AddressState.loaded);
        return true;
      } else {
        _setError(res.error ?? "Failed to add address");
      }
    } catch (e) {
      _setError("Add address error: $e");
    }

    return false;
  }

  Future<bool> updateAddress(AddressModel updated) async {
    _setState(AddressState.updating);

    try {
      final res = await _api.addressApi.updateAddress(
        id: updated.id,
        addressLine1: updated.addressLine1,
        addressLine2: updated.addressLine2,
        city: updated.city,
        state: updated.state,
        country: updated.country,
        postalCode: updated.postalCode,
        receiverName: updated.receiverName,
        contactNumber: updated.contactNumber,
        isDefault: updated.isDefault,
      );

      if (res.success) {
        final index = _addresses.indexWhere((a) => a.id == updated.id);
        if (index != -1) {
          _addresses[index] = updated;

          /// If updated was default
          if (updated.isDefault == true) {
            _selectedAddressId = updated.id;
          }

          _clearError();
          _setState(AddressState.loaded);
          return true;
        }
      } else {
        _setError(res.error ?? "Failed to update address");
      }
    } catch (e) {
      _setError("Update error: $e");
    }

    return false;
  }

  Future<bool> deleteAddress(String id) async {
    _setState(AddressState.deleting);

    try {
      final res = await _api.addressApi.deleteAddress(id: id);

      if (res.success) {
        _addresses.removeWhere((a) => a.id == id);

        /// If deleted selected/default address → fallback
        if (_selectedAddressId == id) {
          _selectedAddressId = defaultAddress?.id;
        }

        _clearError();
        _setState(AddressState.loaded);
        return true;
      } else {
        _setError(res.error ?? "Delete fail");
      }
    } catch (e) {
      _setError("Delete error: $e");
    }

    return false;
  }
}
