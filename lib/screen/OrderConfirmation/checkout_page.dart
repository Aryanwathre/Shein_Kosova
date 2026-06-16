import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/CheckoutProvider.dart';
import 'package:shein_kosova/provider/address_provider.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/provider/config_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';


class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _couponController = TextEditingController();
  String selectedShipping = "standard";


  /// When true → hide total amount and expand button
  bool isPriceBreakdownVisible = false;

  /// Key to detect the position of price breakdown widget
  final GlobalKey priceBreakKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      _checkIfPriceBreakdownVisible();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final addressProvider = context.read<AddressProvider>();
      final checkoutProvider = context.read<CheckoutProvider>();
      final configProvider = context.read<ConfigProvider>();
      final cartProvider = context.read<CartProvider>();

      // If cart is empty, clear any existing coupon state
      if (cartProvider.items.isEmpty) {
        checkoutProvider.removeCoupon();
      }

      // Sync coupon field if already applied
      if (checkoutProvider.appliedCoupon != null) {
        _couponController.text = checkoutProvider.appliedCoupon!['code'] ?? "";
      }

      // Ensure addresses are fetched
      if (addressProvider.addresses.isEmpty) {
        await addressProvider.fetchAddresses();
      }

      // Now pick default or fallback to first
      if (addressProvider.addresses.isNotEmpty) {
        final defaultAddress = addressProvider.addresses.firstWhere(
              (a) => a.isDefault == true,
          orElse: () => addressProvider.addresses.first,
        );

        // Set in AddressProvider
        addressProvider.selectAddress(defaultAddress.id);

        // Set in CheckoutProvider
        checkoutProvider.setAddress(defaultAddress);
      }
      // Select first available payment method if current one is disabled
      if (!configProvider.enabledMethods.contains(checkoutProvider.paymentMethod)) {
        if (configProvider.enabledMethods.isNotEmpty) {
          checkoutProvider.setPayment(configProvider.enabledMethods.first);
        } else if (checkoutProvider.paymentMethods.isNotEmpty) {
          // Fallback to first available hardcoded method if server ones are off
          for (var method in checkoutProvider.paymentMethods) {
            if (!["COD", "CARD"].contains(method)) {
               checkoutProvider.setPayment(method);
               break;
            }
          }
        }
      }
    });
  }

  List<String> card =[
    'assets/cards/visa.svg',
    'assets/cards/mastercard.svg',
    'assets/cards/DinersClub.svg',
    'assets/cards/JCB.svg',
    'assets/cards/Discover.svg',
  ];


  /// Checks if the price breakdown is visible on screen
  void _checkIfPriceBreakdownVisible() {
    final RenderBox? renderBox =
    priceBreakKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero).dy;
      final screenHeight = MediaQuery.of(context).size.height;

      bool isVisible = position < screenHeight - 200;

      if (isVisible != isPriceBreakdownVisible) {
        setState(() {
          isPriceBreakdownVisible = isVisible;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final address = context.watch<AddressProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final config = context.watch<ConfigProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                opacity: isPriceBreakdownVisible ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: isPriceBreakdownVisible
                    ? const SizedBox(width: 0)
                    : Row(
                  children: [
                    styledPrice(
                      checkout.getTotalWithDiscount(cart.totalAmount),
                      fontSize: 24,
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),

              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () async {
                      if (checkout.isPlacingOrder) return;
                      final success = await checkout.placeOrder();
                      if (success) {
                        if (context.mounted) {
                          // Check if there's a payment redirect URL
                          if (checkout.redirectUrl != null && checkout.redirectUrl!.isNotEmpty) {
                            debugPrint('💳 Navigating to payment gateway...');
                            context.pushNamed(
                              'payment',
                              queryParameters: {
                                'redirectUrl': checkout.redirectUrl!,
                                'orderId': checkout.orderId ?? '',
                              },
                            );
                          } else {
                            // If redirectUrl is null but success is true, it means the order is placed (e.g. COD)
                            debugPrint('✅ Order placed successfully. Navigating to success page...');
                            
                            // Clear the cart since the order is successfully placed
                            context.read<CartProvider>().clearCart();

                            context.go('/order-success');
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.read<CheckoutProvider>().errorMessage ?? "Order failed")),
                          );
                        }
                      }

                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: checkout.isPlacingOrder ? Colors.grey : AppColors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: checkout.isPlacingOrder
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Order and Pay",
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.start,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [

           _addressCard(context, address,checkout),
           const SizedBox(height: 20),


           _cartItemTile( cart,context),
           const SizedBox(height: 20),


           // _shippingOptions(),
           // const SizedBox(height: 20),


           _paymentMethod(config, checkout),
           const SizedBox(height: 20),

           _couponSection(checkout, cart.totalAmount),
           const SizedBox(height: 20),

           Container(
             key: priceBreakKey,
             child: _priceDetails(cart, checkout),
           ),
         ],
       ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(title,
        style:  TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        )),
  );

  Widget _addressCard(BuildContext context, AddressProvider addressProvider, CheckoutProvider checkoutProvider) {
    final selected = addressProvider.selectedAddress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle("Shipping Address"),
              TextButton(
                onPressed: (checkoutProvider.isPlacingOrder || checkoutProvider.isValidatingCoupon)
                    ? null
                    : () => _openAddressSelector(context, addressProvider, checkoutProvider),
                child: const Text("Change"),
              )
            ],
          ),

          // If user has no address
          if (selected == null) ...[
            const Row(
              children: [
                Icon(Icons.location_on_outlined),
                SizedBox(width: 12),
                Text("Select Address"),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.receiverName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(selected.addressLine1),
                      Text(selected.addressLine2),
                      Text("${selected.city}, ${selected.state}"),
                      Text("${selected.country} - ${selected.postalCode}"),
                    ],
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _cartItemTile(CartProvider cartItems, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      height: 260,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Your Items"),
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.items.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final item = cartItems.items[index];

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.image,
                          width: 100,
                          height: 120,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          "Size: ${item.size}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (item.color != null && item.color!.isNotEmpty)
                        Text(
                          "Color: ${item.color}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 2),
                      Text(
                          "€${item.price.toStringAsFixed(2)} x${item.quantity}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget shippingOptions() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Shipping Method"),

          RadioListTile(
            value: "standard",

            groupValue: selectedShipping,
            onChanged: (val) {
              setState(() => selectedShipping = val.toString());
            },
            title: Text(
              "Standard Delivery - Free",
              style: TextStyle(color: AppColors.textDark),
            ),
          ),

          RadioListTile(
            value: "express",
            groupValue: selectedShipping,
            onChanged: (val) {
              setState(() => selectedShipping = val.toString());
            },
            title: Row(
              children: [
                Text(
                  "Express Delivery",
                  style: TextStyle(color: AppColors.textDark),
                ),
                styledPrice(60)
              ],
            )
          ),
        ],
      ),
    );
  }

  Widget _paymentMethod(ConfigProvider config, CheckoutProvider checkout) {
    final List<Map<String, String>> methods = [];

    if (config.codEnabled) {
      methods.add({'value': 'COD', 'label': 'Cash on Delivery'});
    }

    if (config.bankEnabled) {
      methods.add({'value': 'CARD', 'label': 'Card Payment'});
    }

    // Add any other provider methods that might be in checkoutProvider but not in config
    for (final m in checkout.paymentMethods) {
      if (m == 'COD' || m == 'CARD') continue;
      methods.add({'value': m, 'label': m});
    }

    if (methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _boxDecoration(),
        child: const Text(
          "No payment methods available at the moment.",
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Payment Method"),
          ...methods.map((m) {
            return RadioListTile<String>(
              value: m['value']!,
              groupValue: checkout.paymentMethod,
              onChanged: (checkout.isPlacingOrder || checkout.isValidatingCoupon)
                  ? null
                  : (val) {
                      if (val == null) return;
                      checkout.setPayment(val);
                      // local setState not required for provider, but if you used any local UI state you can call setState(() {});
                    },
              title: Text(m['label']!, style: const TextStyle(color: AppColors.textDark)),
            );
          }),
        ],
      ),
    );
  }

  Widget _couponSection(CheckoutProvider checkout, double subtotal) {
    final bool isApplied = checkout.appliedCoupon != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApplied ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApplied ? Colors.green : Colors.transparent,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Coupon Code"),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  enabled: !isApplied && !checkout.isValidatingCoupon && !checkout.isPlacingOrder,
                  decoration: InputDecoration(
                    hintText: "Enter coupon code",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isApplied ? Colors.green.shade100 : Colors.grey.shade100,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isApplied)
                IconButton(
                  onPressed: (checkout.isPlacingOrder || checkout.isValidatingCoupon)
                      ? null
                      : () {
                          checkout.removeCoupon();
                          _couponController.clear();
                        },
                  icon: const Icon(Icons.clear, color: Colors.red),
                )
              else
                ElevatedButton(
                  onPressed: checkout.isValidatingCoupon
                      ? null
                      : () async {
                    if (_couponController.text.trim().isEmpty) return;
                    final success = await checkout.validateAndApplyCoupon(
                      _couponController.text.trim(),
                      subtotal,
                    );
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(checkout.couponErrorMessage ?? "Invalid coupon")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: checkout.isValidatingCoupon
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text("Apply"),
                ),
            ],
          ),
          if (isApplied)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Coupon '${checkout.appliedCoupon!['code']}' applied successfully!",
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _priceDetails(CartProvider cart, CheckoutProvider checkout) {
    final double discount = checkout.appliedCoupon != null
        ? (double.tryParse(checkout.appliedCoupon!['discountAmount'].toString()) ?? 0)
        : 0;
    final double grandTotal = checkout.getTotalWithDiscount(cart.totalAmount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Price Breakdown"),
          _priceRow("Subtotal", cart.totalAmount),
          _priceRow("Shipping", 0),
          if (discount > 0)
            _priceRow("Discount", -discount, color: Colors.green),
          const Divider(),
          _priceRow("Grand Total", grandTotal, bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String title, double value, {bool bold = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
                  color: color
              )),
          styledPrice(value, color: color),
        ],
      ),
    );
  }

  void _openAddressSelector(
      BuildContext context,
      AddressProvider addressProvider,
      CheckoutProvider checkoutProvider,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        if(addressProvider.isEmpty){
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No Address Found'),
                ElevatedButton(
                    onPressed: (){
                      context.pushReplacement('/addresses');
                    },
                    child: const Text('Add Address')
                ),
              ],
            ),
          );
        }else{
          return
            SizedBox(
              height: 400,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  const Text(
                    "Select Address",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  Expanded(
                    child: ListView.builder(
                      itemCount: addressProvider.addresses.length,
                      itemBuilder: (ctx, i) {
                        final adr = addressProvider.addresses[i];
                        final isSelected = addressProvider.selectedAddress?.id == adr.id;

                        return ListTile(
                          title: Text(adr.receiverName),
                          subtitle: Text(
                            "${adr.addressLine1}, ${adr.addressLine2}, ${adr.city}",
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          onTap: () {
                            // 🔥 Select inside AddressProvider
                            addressProvider.selectAddress(adr.id);

                            // 🔥 Set inside CheckoutProvider
                            checkoutProvider.setAddress(adr);

                            context.pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
          color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
    ],
  );
}
