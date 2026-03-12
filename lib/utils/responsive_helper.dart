import 'package:flutter/material.dart';

/// Responsive design breakpoints and helper utilities for web, tablet, and mobile support
class ResponsiveHelper {
  /// Breakpoint constants for different device sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1000;
  static const double desktopBreakpoint = 1200;

  /// Checks if the current device is mobile (width < 600)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Checks if the current device is tablet (600 <= width < 1000)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Checks if the current device is desktop (width >= 1000)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Returns the current device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Returns responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Returns responsive grid column count
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  /// Returns responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize ?? mobileSize * 1.1;
    return desktopSize ?? mobileSize * 1.2;
  }

  /// Returns responsive width with max constraint for web
  static double getResponsiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return width > 1400 ? 1400 : width;
    }
    return width;
  }

  /// Returns responsive height for cards/containers
  static double getResponsiveHeight(
    BuildContext context, {
    required double mobileHeight,
    double? tabletHeight,
    double? desktopHeight,
  }) {
    if (isMobile(context)) return mobileHeight;
    if (isTablet(context)) return tabletHeight ?? mobileHeight;
    return desktopHeight ?? mobileHeight;
  }

  /// Horizontal spacing helper - useful for centering content on desktop
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return (width - 1200) / 2;
    }
    return 0;
  }

  /// Gets the ideal max width for a container on any device
  static double getMaxContainerWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return double.infinity;
  }

  /// Helper to determine if layout should be vertical or horizontal
  static bool shouldUseVerticalLayout(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }
}

/// Enum to represent device types
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Widget that rebuilds when orientation or size changes
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper.getDeviceType(context));
  }
}

