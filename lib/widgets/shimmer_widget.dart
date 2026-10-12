import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double? width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerWidget.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.shapeBorder = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
  });

  const ShimmerWidget.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  ShimmerWidget.rounded({
    super.key,
    this.width = double.infinity,
    required this.height,
    double borderRadius = 12,
  }) : shapeBorder = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(borderRadius)));

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: ShapeDecoration(
            color: Colors.grey[400]!,
            shape: shapeBorder,
          ),
        ),
      );
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.75,
          child: ShimmerWidget.rounded(
            height: double.infinity,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const ShimmerWidget.rectangular(height: 10, width: double.infinity),
                const ShimmerWidget.rectangular(height: 12, width: 60),
                const ShimmerWidget.rectangular(height: 8, width: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryItemShimmer extends StatelessWidget {
  const CategoryItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: ShimmerWidget.rounded(
            height: double.infinity,
            width: double.infinity,
            borderRadius: 20,
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(
          flex: 2,
          child: ShimmerWidget.rectangular(height: 10, width: 50),
        ),
      ],
    );
  }
}

/// Placeholder in the shape of the product detail page: gallery, title,
/// price, option chips and the action button.
class ProductDetailsShimmer extends StatelessWidget {
  const ProductDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ShimmerWidget.rectangular(height: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerWidget.rectangular(height: 14),
                const SizedBox(height: 8),
                const ShimmerWidget.rectangular(height: 14, width: 220),
                const SizedBox(height: 20),
                const ShimmerWidget.rectangular(height: 22, width: 110),
                const SizedBox(height: 24),
                const ShimmerWidget.rectangular(height: 12, width: 70),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    4,
                    (_) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ShimmerWidget.rounded(
                        width: 56,
                        height: 56,
                        borderRadius: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const ShimmerWidget.rectangular(height: 12, width: 50),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    5,
                    (_) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ShimmerWidget.rounded(
                        width: 48,
                        height: 36,
                        borderRadius: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ShimmerWidget.rounded(height: 48, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Shimmer
          ShimmerWidget.rectangular(height: MediaQuery.of(context).size.width * 0.6),
          
          const SizedBox(height: 16),
          
          // Categories Grid Shimmer
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 70,
                  child: CategoryItemShimmer()
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tag Pill Shimmer
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ShimmerWidget.rounded(width: 80, height: 32, borderRadius: 20),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Product Grid Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.55,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const ProductCardShimmer(),
            ),
          ),
        ],
      ),
    );
  }
}
