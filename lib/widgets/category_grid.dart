import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/utils/responsive_helper.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

class CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  const CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    // Two-row horizontal grid of circular category thumbnails with the name
    // below, matching the storefront style. crossAxisCount = 2 rows (the grid
    // scrolls horizontally, so the cross axis is vertical).
    return SizedBox(
      height: 240,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.isEmpty ? 8 : categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,      // 2 rows
          mainAxisExtent: 76,     // width of each item
          mainAxisSpacing: 14,    // horizontal gap between columns
          crossAxisSpacing: 8,    // vertical gap between the two rows
        ),
        itemBuilder: (context, index) {
          if (categories.isEmpty) {
            return const CategoryItemShimmer();
          }
          return CategoryCard(
            category: categories[index],
            forcedImageSize: 58,
          );
        },
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final double? forcedImageSize;

  const CategoryCard({
    super.key, 
    required this.category,
    this.forcedImageSize,
  });

  @override
  Widget build(BuildContext context) {
    String categoryId = category.id.toString();
    String categoryName = category.name;
    String categoryImage = category.categoryImage ?? '';

    return GestureDetector(
      onTap: () {
        context.push(
          '/search-result?categoryId=$categoryId&searchTitle=$categoryName',
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          double itemHeight = constraints.maxHeight;
          // Use forced size if provided (e.g. in vertical grids), otherwise calculate
          double imageSize = forcedImageSize ?? (itemHeight * 0.55).clamp(40.0, 75.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: imageSize,
                width: imageSize,
                decoration: BoxDecoration(
                  image: categoryImage.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(categoryImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  color: Colors.grey[100],
                ),
                child: categoryImage.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Align(
                        alignment: AlignmentGeometry.center,
                        child: Text("SH",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobileSize: 24,
                              tabletSize: 24,
                              desktopSize: 24,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : null,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobileSize: 10,
                      tabletSize: 11,
                      desktopSize: 12,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
