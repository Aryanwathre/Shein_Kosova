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
         Flexible(
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
