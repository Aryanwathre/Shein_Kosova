import 'package:flutter/material.dart';
import 'package:shein_kosova/services/api_service.dart';

enum FAQState { initial, loading, loaded, error }

class FAQProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  FAQState _state = FAQState.initial;
  FAQState get state => _state;

  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> get faqs => _faqs;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadFAQs() async {
    _state = FAQState.loading;
    notifyListeners();

    try {
      final response = await _api.faqApi.getFAQs();

      if (response.success && response.data != null) {
        _faqs = response.data!;
        _state = FAQState.loaded;
        debugPrint('✅ FAQs loaded successfully: ${_faqs.length} items');
      } else {
        _errorMessage = response.error ?? 'Failed to load FAQs';
        _state = FAQState.error;
        debugPrint('❌ FAQ API Error: ${response.error}');
      }
    } catch (e) {
      _errorMessage = 'Error loading FAQs: $e';
      _state = FAQState.error;
      debugPrint('❌ Exception loading FAQs: $e');
    }

    notifyListeners();
  }

  void reset() {
    _state = FAQState.initial;
    _faqs = [];
    _errorMessage = null;
    notifyListeners();
  }
}

