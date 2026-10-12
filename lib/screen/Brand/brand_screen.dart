import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/models/store_model.dart';
import 'package:shein_kosova/services/api_service.dart';
import 'package:shein_kosova/utils/responsive_helper.dart';
import 'package:shein_kosova/widgets/ProductCard.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

/// A brand's page: its details, the categories the brand manages for itself,
/// filters (size / color / price), sorting, and its products (paged).
class BrandScreen extends StatefulWidget {
  final String storeId;

  /// Passed from the brands grid so the header shows instantly.
  final StoreModel? initialStore;

  const BrandScreen({super.key, required this.storeId, this.initialStore});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  static const int _pageSize = 20;
  final _api = ApiServiceManager();
  final _scroll = ScrollController();

  StoreModel? _store;
  List<CategoryModel> _categories = [];
  StoreFilters _filterOptions = const StoreFilters();

  // Active filters
  String? _categoryId;
  Set<String> _sizes = {};
  String? _color;
  double? _minPrice;
  double? _maxPrice;
  String _sort = '';

  final List<ProductModel> _products = [];
  int _page = 0;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;

  static const _sortOptions = <String, String>{
    '': 'Default',
    'newest': 'Newest',
    'price_asc': 'Price: Low to High',
    'price_desc': 'Price: High to Low',
  };

  @override
  void initState() {
    super.initState();
    _store = widget.initialStore;
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) _loadMore();
    });
    _loadStore();
    _loadProducts(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadStore() async {
    final results = await Future.wait([
      _api.storesApi.getStore(widget.storeId),
      _api.storesApi.getStoreCategories(widget.storeId),
      _api.storesApi.getStoreFilters(widget.storeId),
    ]);
    if (!mounted) return;
    setState(() {
      final store = results[0] as ApiResponse<StoreModel>;
      final cats = results[1] as ApiResponse<List<CategoryModel>>;
      final filters = results[2] as ApiResponse<StoreFilters>;
      if (store.success && store.data != null) _store = store.data;
      _categories = cats.success ? (cats.data ?? []) : [];
      if (filters.success && filters.data != null) {
        final f = filters.data!;
        // Colour matching is case-insensitive, so "Red" and "red" are one option.
        final seen = <String>{};
        final colors = f.colors.where((c) => seen.add(c.toLowerCase())).toList();
        _filterOptions = StoreFilters(
          sizes: _sortSizes(f.sizes),
          colors: colors,
          minPrice: f.minPrice,
          maxPrice: f.maxPrice,
        );
      }
    });
  }

  /// Clothing sizes in wearing order (XS, S, M, L...), then numeric sizes.
  List<String> _sortSizes(List<String> sizes) {
    const order = ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', '2XL', 'XXXL', '3XL', '4XL', '5XL'];
    double rank(String s) {
      final i = order.indexOf(s.toUpperCase());
      if (i >= 0) return i.toDouble();
      final n = double.tryParse(s);
      return n == null ? 1000 : 100 + n;
    }

    final list = [...sizes];
    list.sort((a, b) {
      final c = rank(a).compareTo(rank(b));
      return c != 0 ? c : a.compareTo(b);
    });
    return list;
  }

  (String?, String?) _sortParams() {
    switch (_sort) {
      case 'newest':
        return ('productId', 'desc');
      case 'price_asc':
        return ('salePrice', 'asc');
      case 'price_desc':
        return ('salePrice', 'desc');
      default:
        return (null, null);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> _fetch(int page) {
    final (sortBy, sortDir) = _sortParams();
    return _api.searchApi.searchProducts(
      storeId: widget.storeId,
      categoryId: _categoryId,
      sizeRange: _sizes.isEmpty ? null : _sizes.join(','),
      color: _color,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sortBy: sortBy,
      sortDir: sortDir,
      page: page,
      size: _pageSize,
    );
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _products.clear();
        _page = 0;
        _hasMore = true;
      });
    }
    final res = await _fetch(0);
    if (!mounted) return;
    setState(() {
      final content = (res.data?['content'] as List?) ?? [];
      _products
        ..clear()
        ..addAll(content.map((j) => ProductModel.fromJson(Map<String, dynamic>.from(j))));
      _total = (res.data?['totalElements'] as num?)?.toInt() ?? _products.length;
      _hasMore = res.success && !(res.data?['last'] ?? true) && content.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    final res = await _fetch(next);
    if (!mounted) return;
    setState(() {
      final content = (res.data?['content'] as List?) ?? [];
      _products.addAll(content.map((j) => ProductModel.fromJson(Map<String, dynamic>.from(j))));
      _page = next;
      _hasMore = res.success && !(res.data?['last'] ?? true) && content.isNotEmpty;
      _loadingMore = false;
    });
  }

  int get _activeFilterCount =>
      _sizes.length + (_color != null ? 1 : 0) + (_minPrice != null || _maxPrice != null ? 1 : 0);

  void _openFilters() {
    final minCtrl = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');
    var sizes = {..._sizes};
    var color = _color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => setSheet(() {
                        sizes = {};
                        color = null;
                        minCtrl.clear();
                        maxCtrl.clear();
                      }),
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                if (_filterOptions.sizes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('SIZE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _filterOptions.sizes.map((s) {
                      final on = sizes.contains(s);
                      return _Chip(
                        label: s,
                        selected: on,
                        onTap: () => setSheet(() => on ? sizes.remove(s) : sizes.add(s)),
                      );
                    }).toList(),
                  ),
                ],
                if (_filterOptions.colors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('COLOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _filterOptions.colors.map((c) {
                      final on = color?.toLowerCase() == c.toLowerCase();
                      return _Chip(
                        label: c,
                        selected: on,
                        onTap: () => setSheet(() => color = on ? null : c),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('PRICE (€)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _priceField(minCtrl, 'Min ${_filterOptions.minPrice?.toStringAsFixed(0) ?? ''}')),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
                    Expanded(child: _priceField(maxCtrl, 'Max ${_filterOptions.maxPrice?.toStringAsFixed(0) ?? ''}')),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _sizes = sizes;
                        _color = color;
                        _minPrice = double.tryParse(minCtrl.text.trim());
                        _maxPrice = double.tryParse(maxCtrl.text.trim());
                      });
                      Navigator.of(sheetContext).pop();
                      _loadProducts(reset: true);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: hint.trim(),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final columns = ResponsiveHelper.getGridColumns(context);

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
        title: Text(store?.name ?? 'Brand'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadStore(), _loadProducts(reset: true)]);
        },
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            // Brand header
            if (store != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: (store.logo ?? '').isNotEmpty
                              ? CachedNetworkImage(imageUrl: store.logo!, fit: BoxFit.cover, width: 64, height: 64)
                              : Text(
                                  store.name.isEmpty ? '?' : store.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            if ((store.description ?? '').isNotEmpty)
                              Text(store.description!, style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // The brand's own categories
            if (_categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    children: [
                      _Chip(
                        label: 'All',
                        selected: _categoryId == null,
                        onTap: () {
                          setState(() => _categoryId = null);
                          _loadProducts(reset: true);
                        },
                      ),
                      ..._categories.map((c) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _Chip(
                              label: c.name,
                              selected: _categoryId == c.id,
                              onTap: () {
                                setState(() => _categoryId = c.id);
                                _loadProducts(reset: true);
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ),

            // Toolbar: count, filters, sort
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('$_total Items Found', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text(_activeFilterCount > 0 ? 'Filters ($_activeFilterCount)' : 'Filters'),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      initialValue: _sort,
                      onSelected: (v) {
                        setState(() => _sort = v);
                        _loadProducts(reset: true);
                      },
                      itemBuilder: (_) => _sortOptions.entries
                          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sort, size: 18),
                            const SizedBox(width: 4),
                            Text(_sortOptions[_sort] ?? 'Sort', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ProductCardShimmer(),
                    childCount: columns * 2,
                  ),
                ),
              )
            else if (_products.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No products yet')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final product = _products[i];
                      return ProductCard(
                        onTap: () => context.push('/products/${product.id}', extra: product),
                        context: context,
                        product: product,
                      );
                    },
                    childCount: _products.length,
                  ),
                ),
              ),

            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          border: Border.all(color: selected ? Colors.black : const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 13),
        ),
      ),
    );
  }
}
