import 'package:flutter/material.dart';
import '../models/BannerModel.dart';
import '../services/api_service.dart';

class BannerProvider with ChangeNotifier {
  final BannerApi _bannerApi = BannerApi();

  List<BannerModel> _banners = [];
  List<BannerModel> get banners => _banners;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> fetchBanners() async {
    _loading = true;
    notifyListeners();

    try {
      final ApiResponse<List<dynamic>> response =
      await _bannerApi.getAllBanners();

      if (response.success && response.data != null) {
        _banners = response.data!
            .map((item) => BannerModel.fromJson(item))
            .toList();
        _error = null;
      } else {
        _error = response.error ?? 'Failed to load banners';
      }
      debugPrint("Loaded banners: ${_banners.length}");
    } catch (e) {
      _error = e.toString();
      debugPrint("Banner load error: $e");
    }

    _loading = false;
    notifyListeners();
  }

}
