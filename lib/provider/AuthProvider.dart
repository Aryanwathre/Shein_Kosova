import 'package:flutter/material.dart';
import 'package:shein_kosova/screen/Auth/loginScreen.dart';
import '../services/api_service.dart';
import '../widgets/bottomNavigationBar.dart';

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
      final isLoggedIn = await _apiManager.isUserLoggedIn();

      if (isLoggedIn) {
        _currentUser = await _apiManager.getCurrentUser();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);

        // Navigate to login if not authenticated
        Future.microtask(() {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>LoginScreen(),));
        });
      }
    } catch (e) {
      _setState(AuthState.unauthenticated);

      // Also navigate to login on error
      Future.microtask(() {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>LoginScreen(),));
      });
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>LandingPage(selectedIndex: 0),));
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

  // Logout
  Future<void> logout(BuildContext context) async {
    try {
      await _apiManager.logout();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>LoginScreen(),));

    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      _setState(AuthState.unauthenticated);
      _clearError();
    }
  }

  // Helper methods
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(AuthState.error);
    debugPrint("AuthProvider Error: $error");
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
