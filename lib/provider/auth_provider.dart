import 'package:flutter/material.dart';
import 'package:shein_kosova/services/api_service.dart';
import 'package:shein_kosova/services/notification_service.dart';
import 'package:shein_kosova/widgets/bottomNavigationBar.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiServiceManager _apiManager = ApiServiceManager();

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  // Getters
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get hasError => _state == AuthState.error;

  Future<void> initializeAuth(BuildContext context) async {
    try {
      // Ensure we have a valid token (refreshes if possible)
      final hasValidToken = await ensureValidToken();

      if (hasValidToken) {
        _currentUser = await _apiManager.getCurrentUser();
        _setState(AuthState.authenticated);
        // Refresh FCM token on initialization if logged in
        NotificationService().refreshAndSaveToken();
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setState(AuthState.unauthenticated);
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setState(AuthState.loading);

      final response = await _apiManager.loginApi.loginUser(
        email: email,
        password: password,
      );

      if (response.success) {
        _currentUser = response.data;
        _setState(AuthState.authenticated);
        _clearError();
        
        // Save FCM token after successful login
        NotificationService().refreshAndSaveToken();
        
        return true;
      } else {
        _setError(response.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  // Register
  Future<bool> register({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      _setState(AuthState.loading);

      final response = await _apiManager.registerApi.registerUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (response.success) {
        _currentUser = response.data;
        _setState(AuthState.authenticated);
        _clearError();

        // Save FCM token after successful registration
        NotificationService().refreshAndSaveToken();

        if (context.mounted) {
           Navigator.pop(context, true);
        }
        return true;
      } else {
        _setError(response.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    }
  }

  Future<bool> ensureValidToken() async {
    final tokenData = await TokenManager.getTokenData();
    if (tokenData == null) return false;
    
    if (tokenData.isExpired) {
      return await TokenManager.forceRefreshToken();
    }
    return true;
  }

  // Logout
  Future<void> logout(BuildContext context) async {
    try {
      await _apiManager.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage(selectedIndex: 0)),
          (route) => false,
        );
      }

    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      _setState(AuthState.unauthenticated);
      _clearError();
    }
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(AuthState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }
}
