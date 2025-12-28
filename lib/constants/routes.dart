
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/models/ProductModel.dart';
import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/models/order_model.dart';
import 'package:shein_kosova/screen/Auth/loginScreen.dart';
import 'package:shein_kosova/screen/Auth/registerScreen.dart';
import 'package:shein_kosova/screen/ProductDetails/productDetails.dart';
import 'package:shein_kosova/screen/Search/searchesultScreen.dart';
import 'package:shein_kosova/screen/userAccount/Wishlist_Screen.dart';
import 'package:shein_kosova/screen/userAccount/AboutUs_Screen.dart';
import 'package:shein_kosova/screen/userAccount/HelpCenter_Screen.dart';
import 'package:shein_kosova/screen/userAccount/Notification_Screen.dart';
import 'package:shein_kosova/screen/userAccount/MyOrder/MyOrder_Screen.dart';
import 'package:shein_kosova/screen/userAccount/MyOrder/order_details_screen.dart';
import 'package:shein_kosova/screen/userAccount/Address/Addresses_Screen.dart';
import 'package:shein_kosova/screen/userAccount/Address/AddAddress_Screen.dart';
import 'package:shein_kosova/screen/userAccount/Address/EditAddress_Screen.dart';
import 'package:shein_kosova/screen/userAccount/profile/edit_profile_screen.dart';
import 'package:shein_kosova/models/UserProfile.dart';
import 'package:shein_kosova/widgets/bottomNavigationBar.dart';
import 'package:shein_kosova/screen/OrderConfirmation/checkout_page.dart';
import 'package:shein_kosova/screen/OrderConfirmation/OrderPlacedSuccess.dart';
import 'package:shein_kosova/screen/Search/searchScreen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String landing = '/shop';
  static const String login = '/login';
  static const String register = '/register';
  static const String productDetails = '/product/:id';
  static const String searchResult = '/search-result';
  static const String wishlist = '/wishlist';
  static const String aboutUs = '/about-us';
  static const String helpCenter = '/help-center';
  static const String notifications = '/notifications';
  static const String myOrders = '/my-orders';
  static const String orderDetails = '/order-details';
  static const String addresses = '/addresses';
  static const String addAddress = '/add-address';
  static const String editAddress = '/edit-address';
  static const String editProfile = '/edit-profile';
  static const String checkout = '/checkout';
  static const String orderPlacedSuccess = '/order-success';
  static const String search = '/search';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreenPage(),
      ),
      GoRoute(
        path: landing,
        builder: (context, state) {
          final index = int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0;
          return LandingPage(selectedIndex: index);
        },
      ),
      GoRoute(
        path: login,
        builder: (context, state) {
          final isModal = state.uri.queryParameters['isModal'] == 'true';
          return LoginScreen(isModal: isModal);
        },
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: productDetails,
        builder: (context, state) {
          final product = state.extra as ProductModel?;
          return ProductDetailsScreen(product: product);
        },
      ),
      GoRoute(
        path: searchResult,
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          final searchQuery = state.uri.queryParameters['searchQuery'];
          final searchTitle = state.uri.queryParameters['searchTitle'] ?? 'Search';
          return SearchResultScreen(
            categoryId: categoryId,
            searchQuery: searchQuery,
            searchTitle: searchTitle,
          );
        },
      ),
      GoRoute(
        path: wishlist,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: aboutUs,
        builder: (context, state) => const AboutUsPage(),
      ),
      GoRoute(
        path: helpCenter,
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: myOrders,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: orderDetails,
        builder: (context, state) {
          final order = state.extra as OrderModel;
          return OrderDetailsScreen(order: order);
        },
      ),
      GoRoute(
        path: addresses,
        builder: (context, state) => const SavedAddressesPage(),
      ),
      GoRoute(
        path: addAddress,
        builder: (context, state) => const AddAddressScreen(),
      ),
      GoRoute(
        path: editAddress,
        builder: (context, state) {
          final address = state.extra as AddressModel;
          return EditAddressScreen(address: address);
        },
      ),
      GoRoute(
        path: editProfile,
        builder: (context, state) {
          final user = state.extra as UserProfile;
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: checkout,
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: orderPlacedSuccess,
        builder: (context, state) => const OrderSuccessPage(),
      ),
      GoRoute(
        path: search,
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
}
