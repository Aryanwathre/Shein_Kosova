import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shein_kosova/screen/Cart/cartScreen.dart';
import 'package:shein_kosova/screen/userAccount/profile/Profile.dart';
import 'package:shein_kosova/utils/theam.dart';

import '../provider/AuthProvider.dart';
import '../provider/LandingPageProvider.dart';
import '../provider/cart_provider.dart';
import '../screen/Auth/loginScreen.dart';
import '../screen/Home/homeScreen.dart';
import '../screen/Search/searchScreen.dart';


class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.wait([

      Future.delayed(const Duration(seconds: 3)),

      authProvider.initializeAuth(context),
    ]);


    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Widget nextScreen;

    switch (authProvider.state) {
      case AuthState.authenticated:

        nextScreen = const LandingPage(selectedIndex: 0);
        break;
      case AuthState.unauthenticated:
      case AuthState.error:
      default:

        nextScreen = const LoginScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/logo3.png",
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 32),
            // Optional: Add loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}


class LandingPage extends StatefulWidget {
  final int selectedIndex;
  const LandingPage({super.key, required this.selectedIndex});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      Homescreen(),
      const SearchScreen(),
      const SearchScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Set the initial page index
      context.read<LandingProvider>().changePage(widget.selectedIndex);
      // It's also good practice to load the initial cart state here
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch both providers. When either one notifies listeners, this widget rebuilds.
    final landingProvider = context.watch<LandingProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[landingProvider.selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        currentIndex: landingProvider.selectedIndex,
        selectedItemColor: AppTheme.darkOrange,
        unselectedItemColor: AppTheme.primaryOrange,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: landingProvider.changePage,
        items: [
          BottomNavigationBarItem(
            icon: (landingProvider.selectedIndex == 0)
                ? const Icon(Icons.home)
                : const Icon(Icons.home_outlined),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: (landingProvider.selectedIndex == 1)
                ? const Icon(Icons.search)
                : const Icon(Icons.search_outlined),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: (landingProvider.selectedIndex == 1)
                ?  Image.asset(
                    'assets/icons/trend.png',
                    width: 24,
                    height: 24,
                  )
                : const Icon(Icons.search_outlined),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none, // Allows the badge to render outside the icon's bounds
              children: [
                (landingProvider.selectedIndex == 2)
                    ? const Icon(Icons.shopping_cart)
                    : const Icon(Icons.shopping_cart_outlined),

                // Use the itemCount directly from CartProvider
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        cartProvider.itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: (landingProvider.selectedIndex == 3)
                ? const Icon(Icons.person)
                : const Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

