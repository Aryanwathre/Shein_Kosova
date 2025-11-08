import 'package:flutter/material.dart';
import '../models/UserProfile.dart';
import '../services/api_service.dart';

enum ProfileState { initial, loading, loaded, error, updating }

class ProfileProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  UserProfile? _userProfile;
  ProfileState _state = ProfileState.initial;
  String? _errorMessage;

  // Getters
  UserProfile? get userProfile => _userProfile;
  ProfileState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ProfileState.loading;
  bool get isUpdating => _state == ProfileState.updating;
  bool get hasError => _state == ProfileState.error;

  /// Fetch the user's profile from the API
  Future<void> loadUserProfile() async {
    _setState(ProfileState.loading);

    try {
      final response = await _api.profileApi.getProfile();

      if (response.success && response.data != null) {
        _userProfile = UserProfile.fromJson(response.data!);
        _setState(ProfileState.loaded);
        _clearError();
      } else {
        _setError(response.error ?? 'Failed to load profile');
      }
    } catch (e) {
      _setError('A network error occurred: ${e.toString()}');
    }
  }

  /// Update the user's profile via the API
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    _setState(ProfileState.updating);

    try {
      final response = await _api.profileApi.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phone,
      );

      if (response.success && response.data != null) {
        _userProfile = UserProfile.fromJson(response.data!);
        _setState(ProfileState.loaded);
        return true;
      } else {
        _setError(response.error ?? 'Failed to update profile');
        return false;
      }
    } catch (e) {
      _setError('A network error occurred: ${e.toString()}');
      return false;
    }
  }

  // --- State Management Helpers ---

  void _setState(ProfileState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(ProfileState.error);
    debugPrint("ProfileProvider Error: $error");
  }

  void _clearError() {
    _errorMessage = null;
  }
}
