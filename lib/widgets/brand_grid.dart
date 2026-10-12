import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/models/store_model.dart';

/// "Top Brands" grid: tall tiles with the brand image, name, short description
/// and an arrow. Tapping a tile opens that brand's page (/brand/:id).
class BrandGrid extends StatelessWidget {
  final List<StoreModel> stores;
  final bool loading;

  /// Section heading; null hides the header row (used by the All Brands page).
  final String? title;
  final bool showSeeAll;

  /// Renders as a sliver-free box, so it can sit inside a SliverToBoxAdapter.
  const BrandGrid({
    super.key,
    required this.stores,
    this.loading = false,
    this.title = 'Top Brands',
    this.showSeeAll = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1100 ? 6 : (width >= 700 ? 4 : 3);

    if (!loading && stores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (showSeeAll)
                    OutlinedButton(
                      onPressed: () => context.push('/brands'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('See All', style: TextStyle(fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: loading ? columns * 2 : stores.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemBuilder: (context, index) {
              if (loading) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }
              return _BrandTile(store: stores[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  final StoreModel store;
  const _BrandTile({required this.store});

  @override
  Widget build(BuildContext context) {
    final logo = store.logo ?? '';
    final initial = store.name.trim().isEmpty ? '?' : store.name.trim()[0].toUpperCase();
    final fallback = Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2B2B2B), Color(0xFF111111)]),
      ),
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
      ),
    );

    return GestureDetector(
      onTap: () => context.push('/brand/${store.id}', extra: store),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF1C1C1C)),
            if (logo.isNotEmpty)
              CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => fallback,
              )
            else
              fallback,
            // Caption over a dark gradient so white text stays readable.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xC0000000), Color(0x00000000)],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if ((store.description ?? '').isNotEmpty)
                            Text(
                              store.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward, size: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
