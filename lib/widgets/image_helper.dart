import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

/// Helper function to safely load network images with proper error handling
/// Returns CachedNetworkImage if URL is valid, otherwise returns placeholder
Widget buildNetworkImage(
  String imageUrl, {
  required BoxFit fit,
  required double width,
  required double height,
  BorderRadius? borderRadius,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  // Return placeholder immediately if URL is empty or null
  if (imageUrl.isEmpty || imageUrl.trim().isEmpty) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  // Try to validate URL format
  try {
    Uri.parse(imageUrl);
  } catch (e) {
    // Invalid URL format
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Widget content = CachedNetworkImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    placeholder: (context, url) =>
        placeholder ?? const ShimmerWidget.rectangular(height: double.infinity),
    errorWidget: (context, url, error) =>
        errorWidget ??
        Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
  );

  if (borderRadius != null) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: content,
    );
  }

  return content;
}

/// Helper for AspectRatio wrapped network images
Widget buildNetworkImageAspectRatio(
  String imageUrl, {
  required BoxFit fit,
  required double aspectRatio,
  BorderRadius? borderRadius,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  // Return placeholder immediately if URL is empty
  if (imageUrl.isEmpty || imageUrl.trim().isEmpty) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Widget content = CachedNetworkImage(
    imageUrl: imageUrl,
    fit: fit,
    placeholder: (context, url) =>
        placeholder ?? const ShimmerWidget.rectangular(height: double.infinity),
    errorWidget: (context, url, error) =>
        errorWidget ??
        Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
  );

  Widget wrappedContent = AspectRatio(
    aspectRatio: aspectRatio,
    child: content,
  );

  if (borderRadius != null) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: wrappedContent,
    );
  }

  return wrappedContent;
}

