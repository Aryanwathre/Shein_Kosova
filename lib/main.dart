import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/Address_Provider.dart';
import 'package:shein_kosova/provider/AuthProvider.dart';
import 'package:shein_kosova/provider/LandingPageProvider.dart';
import 'package:shein_kosova/provider/ProductDetailsProvider.dart';
import 'package:shein_kosova/provider/Profile_provider.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/provider/orders_provider.dart';
import 'package:shein_kosova/provider/search_provider.dart';
import 'package:shein_kosova/provider/wishListProvider.dart';
import 'package:shein_kosova/services/api_service.dart';
import 'package:shein_kosova/utils/theam.dart';
import 'package:shein_kosova/widgets/bottomNavigationBar.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final tokenValid = await TokenManager.isTokenValid();

  if (!tokenValid) {
    final refreshed = await TokenManager.forceRefreshToken();
    if (!refreshed) {
      print('⚠️ Token refresh failed — user needs to log in again');
      await TokenManager.clearAllData();
    } else {
      print('✅ Token refreshed successfully on startup');
    }
  } else {
    print('✅ Access token still valid');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => LandingProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shein kosova',
      theme: AppTheme.theme,
      themeMode: ThemeMode.system,
      home: const SplashScreenPage(),
    );
  }
}
