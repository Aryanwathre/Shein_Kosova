import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/constants/routes.dart';
import 'package:shein_kosova/provider/address_provider.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/banner_provider.dart';
import 'package:shein_kosova/provider/CheckoutProvider.dart';
import 'package:shein_kosova/provider/LandingPageProvider.dart';
import 'package:shein_kosova/provider/product_details_provider.dart';
import 'package:shein_kosova/provider/Profile_provider.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/provider/category_provider.dart';
import 'package:shein_kosova/provider/orders_provider.dart';
import 'package:shein_kosova/provider/search_provider.dart';
import 'package:shein_kosova/provider/wishlist_provider.dart';
import 'package:shein_kosova/utils/theam.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();


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
        ChangeNotifierProvider(create: (_) => BannerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Shein kosova',
      theme: AppTheme.theme,
      themeMode: ThemeMode.system,
      routerConfig: AppRoutes.router,
    );
  }
}
