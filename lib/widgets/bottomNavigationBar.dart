import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/LandingPageProvider.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/provider/config_provider.dart';
import 'package:shein_kosova/provider/home_provider.dart';
import 'package:shein_kosova/screen/Cart/cartScreen.dart';
import 'package:shein_kosova/screen/Home/homeScreen.dart';
import 'package:shein_kosova/screen/Search/categorySearchScreen.dart';
import 'package:shein_kosova/screen/userAccount/profile/Profile.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/theam.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    // Delay initialization to after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);

    // Load config API first
    await configProvider.loadConfig();

    if (!mounted) return;

    // Then initialize auth
    await authProvider.initializeAuth(context);

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (mounted) {
      context.go('/shop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(
              'assets/logo.png',
              width: 250,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            // Show loading indicator while config is being loaded
            Align(
              alignment: Alignment.bottomCenter,
              child: Consumer<ConfigProvider>(
                builder: (context, configProvider, child) {
                  if (configProvider.state == ConfigState.loading) {
                    return Column(
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading configuration...',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
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
                final requiresAuth = index == 2 || index == 3;

                if (requiresAuth && authProvider.state != AuthState.authenticated) {
                  await showLoginPrompt(context);
                  if (!mounted) return;

                  // Re-read after async gap
                  final updatedAuthProvider = context.read<AuthProvider>();
                  if (updatedAuthProvider.state != AuthState.authenticated) return;
                }

                // --- FRESH DATA LOGIC ---
                // Trigger background refresh when switching to a tab
                if (mounted) {
                  if (index == 0) {
                    // Refresh home data silently
                    context.read<HomeProvider>().initHome(forceRefresh: true);
                  } else if (index == 2) {
                    // Refresh cart
                    context.read<CartProvider>().loadCart(showLoading: false);
                  }
                }

                // Navigate if still mounted
                if (mounted) {
                  context.go('/shop?index=$index');
                }
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
