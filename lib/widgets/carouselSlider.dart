import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shein_kosova/models/BannerModel.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';
import 'package:shein_kosova/utils/responsive_helper.dart';

Widget buildCarouselSlider(
  List<BannerModel> banners,
  BuildContext context, {
  Function(bool)? onThemeChanged,
}) {
  final bool isDesktop = ResponsiveHelper.isDesktop(context);
  final bool isTablet = ResponsiveHelper.isTablet(context);
  
  // Use a wider aspect ratio for desktop/tablet web views
  final double aspectRatio = isDesktop ? 2.5 : (isTablet ? 2.0 : 0.8);

  return RepaintBoundary(
    child: CarouselSlider(
      options: CarouselOptions(
        aspectRatio: aspectRatio,
        viewportFraction: 1.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        enableInfiniteScroll: true,
        enlargeCenterPage: false,
        scrollPhysics: const BouncingScrollPhysics(), // Allow swiping
        onPageChanged: (index, reason) {
          if (onThemeChanged != null && banners.isNotEmpty) {
            onThemeChanged(banners[index].isLight);
          }
        },
      ),
      items: banners.map((banner) {
        // Choose the appropriate image URL based on the device
        String imageUrl = (isDesktop || isTablet) && banner.webImageUrl.isNotEmpty
            ? banner.webImageUrl
            : banner.mobileImageUrl;
            
        // Fallback if the chosen one is empty
        if (imageUrl.isEmpty) {
          imageUrl = banner.mobileImageUrl.isNotEmpty ? banner.mobileImageUrl : banner.webImageUrl;
        }

        return GestureDetector(
          onTap: () {
            debugPrint("Clicked Banner: ${banner.redirectUrl}");
          },
          child: SizedBox.expand(
            child: imageUrl.isEmpty
                ? Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  )
                : kIsWeb 
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const ShimmerWidget.rectangular(height: double.infinity);
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    )
                  : CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: imageUrl,
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
