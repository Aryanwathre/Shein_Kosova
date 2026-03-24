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
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    int crossAxisCount = isDesktop ? 2 : 3;

    double gridHeight = isDesktop
        ? MediaQuery.of(context).size.height * 0.3
        : MediaQuery.of(context).size.height * 0.35;

    gridHeight = gridHeight.clamp(180.0, 350.0);

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: categories.isEmpty ? 12 : categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          if (categories.isEmpty) {
            return const CategoryItemShimmer();
          }
          return CategoryCard(category: categories[index]);
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
                  borderRadius: BorderRadius.circular(imageSize / 3),
                  color: Colors.grey[200],
                ),
                child: categoryImage.isEmpty
                    ? Icon(Icons.category,
                        color: Colors.grey[400],
                        size: imageSize * 0.5)
                    : null,
              ),
              const SizedBox(height: 6),
              Expanded(
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
