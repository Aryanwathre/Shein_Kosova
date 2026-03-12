import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web-aware storage service that provides a fallback chain for data persistence
/// Fallback order: SharedPreferences → In-memory cache
///
/// On web platform, this service gracefully handles browser storage limitations:
/// - Private browsing mode blocking localStorage
/// - CORS restrictions
/// - Storage quota exceeded
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  final Map<String, dynamic> _memoryCache = {};

  bool _initialized = false;
  bool _persistenceAvailable = false;
  String _failureReason = '';

  /// Initialize the storage service
  /// Returns true if persistent storage is available, false if using in-memory fallback
  Future<bool> initialize() async {
    if (_initialized) return _persistenceAvailable;

    try {
      _prefs = await SharedPreferences.getInstance();
      _persistenceAvailable = true;
      _failureReason = '';
      debugPrint('✅ Storage: SharedPreferences initialized successfully');
    } catch (e) {
      _persistenceAvailable = false;
      _failureReason = e.toString();
      debugPrint('⚠️ Storage: SharedPreferences failed, using in-memory cache');
      debugPrint('📝 Error: $e');

      if (kIsWeb) {
        _logWebStorageIssue(e);
      }
    }

    _initialized = true;
    return _persistenceAvailable;
  }

  /// Check if persistent storage is available
  bool isPersistenceAvailable() => _persistenceAvailable;

  /// Get the reason for storage failure (for debugging)
  String getFailureReason() => _failureReason;

  /// Set a string value
  Future<bool> setString(String key, String value) async {
    try {
      if (_persistenceAvailable) {
        final result = await _prefs.setString(key, value);
        if (result) {
          _memoryCache[key] = value;
          debugPrint('💾 Storage: Set string "$key" (persistent)');
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ Storage: Failed to set string "$key": $e');
      if (kIsWeb) {
        _logWebStorageIssue(e);
      }
    }

    // Fallback to memory cache
    _memoryCache[key] = value;
    debugPrint('💾 Storage: Set string "$key" (in-memory)');
    return true;
  }

  /// Get a string value
  Future<String?> getString(String key) async {
    try {
      if (_persistenceAvailable) {
        final value = _prefs.getString(key);
        if (value != null) {
          debugPrint('📖 Storage: Retrieved string "$key" (persistent)');
          return value;
        }
      }
    } catch (e) {
      debugPrint('❌ Storage: Failed to get string "$key": $e');
    }

    // Fallback to memory cache
    final cachedValue = _memoryCache[key];
    if (cachedValue is String) {
      debugPrint('📖 Storage: Retrieved string "$key" (in-memory)');
      return cachedValue;
    }

    return null;
  }

  /// Set a boolean value
  Future<bool> setBool(String key, bool value) async {
    try {
      if (_persistenceAvailable) {
        final result = await _prefs.setBool(key, value);
        if (result) {
          _memoryCache[key] = value;
          debugPrint('💾 Storage: Set bool "$key" = $value (persistent)');
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ Storage: Failed to set bool "$key": $e');
    }

    // Fallback to memory cache
    _memoryCache[key] = value;
    debugPrint('💾 Storage: Set bool "$key" = $value (in-memory)');
    return true;
  }

  /// Get a boolean value
  Future<bool> getBool(String key) async {
    try {
      if (_persistenceAvailable) {
        final value = _prefs.getBool(key);
        if (value != null) {
          debugPrint('📖 Storage: Retrieved bool "$key" (persistent)');
          return value;
        }
      }
    } catch (e) {
      debugPrint('❌ Storage: Failed to get bool "$key": $e');
    }

    // Fallback to memory cache
    final cachedValue = _memoryCache[key];
    if (cachedValue is bool) {
      debugPrint('📖 Storage: Retrieved bool "$key" (in-memory)');
      return cachedValue;
    }

    return false;
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    try {
      if (_persistenceAvailable) {
        final result = await _prefs.remove(key);
        _memoryCache.remove(key);
        debugPrint('🗑️ Storage: Removed key "$key" (persistent)');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Storage: Failed to remove "$key": $e');
    }

    // Fallback to memory cache
    _memoryCache.remove(key);
    debugPrint('🗑️ Storage: Removed key "$key" (in-memory)');
    return true;
  }

  /// Clear all stored values
  Future<bool> clear() async {
    try {
      if (_persistenceAvailable) {
        final result = await _prefs.clear();
        _memoryCache.clear();
        debugPrint('🗑️ Storage: Cleared all data (persistent)');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Storage: Failed to clear all data: $e');
    }

    // Fallback to memory cache
    _memoryCache.clear();
    debugPrint('🗑️ Storage: Cleared all data (in-memory)');
    return true;
  }

  /// Get the in-memory cache (for debugging purposes)
  Map<String, dynamic> getMemoryCache() => Map.from(_memoryCache);

  /// Log details about web storage issues
  static void _logWebStorageIssue(Object error) {
    debugPrint('');
    debugPrint('🌐 Web Storage Issue Detected:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Error: $error');
    debugPrint('');
    debugPrint('Common causes:');
    debugPrint('1. Browser running in private/incognito mode');
    debugPrint('2. localStorage disabled in browser settings');
    debugPrint('3. Cross-origin isolation blocking storage');
    debugPrint('4. Storage quota exceeded');
    debugPrint('5. CORS policy restrictions');
    debugPrint('');
    debugPrint('Fallback: Using in-memory cache (data lost on refresh)');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('');
  }

  /// Get storage diagnostics (for debugging)
  Map<String, dynamic> getDiagnostics() {
    return {
      'initialized': _initialized,
      'persistenceAvailable': _persistenceAvailable,
      'failureReason': _failureReason,
      'memoryCacheSize': _memoryCache.length,
      'memoryCacheKeys': _memoryCache.keys.toList(),
      'platform': kIsWeb ? 'web' : 'mobile',
    };
  }
}

