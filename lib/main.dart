import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/constants/routes.dart';
import 'package:shein_kosova/firebase_options.dart';
import 'package:shein_kosova/provider/CheckoutProvider.dart';
import 'package:shein_kosova/provider/LandingPageProvider.dart';
import 'package:shein_kosova/provider/Profile_provider.dart';
import 'package:shein_kosova/provider/address_provider.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/provider/category_provider.dart';
import 'package:shein_kosova/provider/config_provider.dart';
import 'package:shein_kosova/provider/faq_provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/provider/orders_provider.dart';
import 'package:shein_kosova/provider/product_details_provider.dart';
import 'package:shein_kosova/provider/search_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/services/api_service.dart';
import 'package:shein_kosova/services/notification_service.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/theam.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize storage service (handles web storage limitations)
  await TokenManager.initializeStorage();

  // Initialize Notification Service (web-safe)
  final notificationService = NotificationService();
  await notificationService.init();

  // Load configuration from API (this saves to Shared Preferences)
  final configProvider = ConfigProvider();
  await configProvider.loadConfig();

  // Load local config for colors (depends on saved config)
  await AppColors.loadConfig();

  // Refresh JWT token on startup if a refresh token is available
  try {
    final tokenData = await TokenManager.getTokenData();
    if (tokenData != null && tokenData.refreshToken.isNotEmpty) {
      await TokenManager.forceRefreshToken();
    }
  } catch (e) {
    debugPrint("Initial token refresh error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => LandingProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProvider(create: (_) => FAQProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Global listener for auth events (e.g. session expired)
    _authSubscription = TokenManager.authEventStream.listen((isAuthenticated) {
      if (!isAuthenticated) {
        // Force navigate to login on session expiry
        AppRoutes.router.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SH Kosova',
      theme: AppTheme.theme,
      themeMode: ThemeMode.system,
      routerConfig: AppRoutes.router,
      builder: (context, child) {
        if (kIsWeb) {
          return Container(
            color: const Color(0xFFF5F5F5), // Light grey background for the "sides"
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child!,
              ),
            ),
          );
        }
        return child!;
      },
    );
  }
}
