import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shein_kosova/models/BannerModel.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

Widget buildCarouselSlider(
  List<BannerModel> banners,
  BuildContext context, {
  Function(bool)? onThemeChanged,
}) {
  return RepaintBoundary(
    child: CarouselSlider(
      options: CarouselOptions(
        aspectRatio: 4 / 5,
        viewportFraction: 1.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        enableInfiniteScroll: true,
        enlargeCenterPage: false,
        onPageChanged: (index, reason) {
          if (onThemeChanged != null && banners.isNotEmpty) {
            onThemeChanged(banners[index].isLight);
          }
        },
      ),
      items: banners.map((banner) {
        return GestureDetector(
          onTap: () {
            debugPrint("Clicked Banner: ${banner.redirectUrl}");
          },
          child: SizedBox(
            width: double.infinity,
            child: CachedNetworkImage(
              alignment: Alignment.bottomCenter,
              fit: BoxFit.fitWidth,
              imageUrl: banner.mobileImageUrl,
              placeholder: (context, url) =>
                  const ShimmerWidget.rectangular(height: double.infinity),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 50),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
