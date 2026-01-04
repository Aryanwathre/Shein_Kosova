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
          aspectRatio: 0.72,
          child: ShimmerWidget.rounded(
            height: double.infinity,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 8),
        const ShimmerWidget.rectangular(height: 12, width: 100),
        const SizedBox(height: 4),
        const ShimmerWidget.rectangular(height: 14, width: 60),
        const SizedBox(height: 4),
        const ShimmerWidget.rectangular(height: 10, width: 40),
      ],
    );
  }
}

class CategoryItemShimmer extends StatelessWidget {
  const CategoryItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerWidget.rounded(
          height: 60,
          width: 60,
          borderRadius: 20,
        ),
        const SizedBox(height: 8),
        const ShimmerWidget.rectangular(height: 10, width: 50),
      ],
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
                child: CategoryItemShimmer(),
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
                childAspectRatio: 0.57,
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
