import 'package:flutter/material.dart';
import 'package:shein_kosova/services/api_service.dart';

enum ConfigState { initial, loading, loaded, error }

class ConfigProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  ConfigState _state = ConfigState.initial;
  ConfigState get state => _state;

  Map<String, dynamic>? _configData;
  Map<String, dynamic>? get configData => _configData;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _codEnabled = false;
  bool get codEnabled => _codEnabled;

  bool _bankEnabled = false;
  bool get bankEnabled => _bankEnabled;

  bool _cardEnabled = false;
  bool get cardEnabled => _cardEnabled;

  bool _upiEnabled = false;
  bool get upiEnabled => _upiEnabled;

  List<String> get enabledMethods {
    final List<String> methods = [];
    if (_codEnabled) methods.add("COD");
    if (_bankEnabled) methods.add("CARD"); // Mapping bankEnabled -> Card Payment
    return methods;
  }

  Future<void> loadConfig() async {
    _state = ConfigState.loading;
    notifyListeners();

    try {
      final response = await _api.configApi.getConfig();

      if (response.success && response.data != null) {
        _configData = response.data;
        
        // Save to Shared Preferences
        await TokenManager.saveConfigData(_configData!);
        
        // Update local state
        _codEnabled = await TokenManager.isCodEnabled();
        _bankEnabled = await TokenManager.isBankEnabled();
        _cardEnabled = await TokenManager.isCardEnabled();
        _upiEnabled = await TokenManager.isUpiEnabled();
        
        _state = ConfigState.loaded;
        debugPrint('✅ Config loaded successfully: $_configData');
      } else if (response.statusCode == 401) {
        // 401 Unauthorized - Skip config and continue
        _state = ConfigState.loaded;
        debugPrint('⚠️ Config API returned 401 Unauthorized - Skipping config and continuing');
      } else {
        _errorMessage = response.error ?? 'Failed to load config';
        _state = ConfigState.error;
        debugPrint('❌ Config API Error: ${response.error}');
      }
    } catch (e) {
      _errorMessage = 'Error loading config: $e';
      _state = ConfigState.error;
      debugPrint('❌ Exception loading config: $e');
    }

    notifyListeners();
  }

  void reset() {
    _state = ConfigState.initial;
    _configData = null;
    _errorMessage = null;
    _codEnabled = false;
    _bankEnabled = false;
    notifyListeners();
  }
}
