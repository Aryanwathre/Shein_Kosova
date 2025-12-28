import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/screen/Cart/cartScreen.dart';
import 'package:shein_kosova/screen/userAccount/profile/Profile.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/theam.dart';

import '../provider/auth_provider.dart';
import '../provider/LandingPageProvider.dart';
import '../provider/cart_provider.dart';
import '../screen/Home/homeScreen.dart';
import '../screen/Search/categorySearchScreen.dart';
import 'login_prompt_sheet.dart';

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

    await Future.delayed(const Duration(seconds: 3));

    await authProvider.initializeAuth(context);

    if (mounted) {
      _navigateToNextScreen();
    }
  }


  Future<void> _navigateToNextScreen() async {
    context.go('/shop');
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset("assets/logo3.png", height: 150, width: 150),
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
      const Homescreen(),
      const CargorySearchScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<LandingProvider>().changePage(widget.selectedIndex);
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  void didUpdateWidget(covariant LandingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<LandingProvider>().changePage(widget.selectedIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Performance optimization: Use Selector to only rebuild when the tab actually changes
    return Selector<LandingProvider, int>(
      selector: (_, provider) => provider.selectedIndex,
      builder: (context, selectedIndex, child) {
        final cartProvider = context.watch<CartProvider>();

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: _pages[selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Colors.white,
              elevation: 0.0,
              currentIndex: selectedIndex,
              selectedItemColor: AppTheme.theme.primaryColor,
              unselectedItemColor: AppTheme.theme.primaryColor,
              selectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              onTap: (index) async {
                final authProvider = context.read<AuthProvider>();

                // Cart (2) & Profile (3) need login
                final requiresAuth = index == 2 || index == 3;

                if (requiresAuth && authProvider.state != AuthState.authenticated) {
                  await showLoginPrompt(context);
                  
                  // After the prompt (and potential login), check state again
                  if (authProvider.state != AuthState.authenticated) return;

                  // Login successful → proceed
                  if (index == 2) {
                    // Refresh cart if moving to cart
                    if (mounted) context.read<CartProvider>().loadCart();
                  }
                }

                // Instead of just calling context.read<LandingProvider>().changePage(index);
                // We navigate via GoRouter to keep the URL/state in sync
                context.go('/shop?index=$index');
              },

              items: [
                BottomNavigationBarItem(
                  icon: (selectedIndex == 0)
                      ? const Icon(Icons.home)
                      : const Icon(Icons.home_outlined),
                  label: 'Shop',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    'assets/icon/categorySearch.png',
                    width: 24,
                    height: 24,
                    color: (selectedIndex == 1)
                        ? AppColors.primaryDark
                        : AppColors.primary,
                  ),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      (selectedIndex == 2)
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
                  icon: (selectedIndex == 3)
                      ? const Icon(Icons.person)
                      : const Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
