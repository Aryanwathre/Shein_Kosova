import 'package:flutter/material.dart';
import 'package:shein_kosova/models/store_model.dart';
import 'package:shein_kosova/services/api_service.dart';
import 'package:shein_kosova/widgets/brand_grid.dart';

/// "See All" target from the home Top Brands section: every active brand.
class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  final _api = ApiServiceManager();
  List<StoreModel> _stores = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.storesApi.getStores(page: 0, size: 500);
    if (!mounted) return;
    setState(() {
      _stores = res.success ? (res.data ?? []) : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? _stores
        : _stores.where((s) => s.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // The app theme sets a dark title/icon style; force white on black.
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        title: const Text('All Brands'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search brands...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (!_loading && visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No brands found')),
              )
            else
              BrandGrid(stores: visible, loading: _loading, title: null, showSeeAll: false),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
