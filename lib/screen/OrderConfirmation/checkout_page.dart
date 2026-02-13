import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/CheckoutProvider.dart';
import 'package:shein_kosova/provider/address_provider.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';


class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final ScrollController _scrollController = ScrollController();
  String selectedShipping = "standard";
  String selectedPayment = "cod";


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
                      cart.totalAmount,
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
                    onTap: () async{
                      final success = await checkout.placeOrder();
                      if (success) {
                        if (context.mounted) {
                          context.pushReplacement('/order-success');
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
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
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


           _paymentMethod(),
           const SizedBox(height: 20),

           Container(
             key: priceBreakKey,
             child: _priceDetails(cart),
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
                onPressed: () => _openAddressSelector(context, addressProvider, checkoutProvider),
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
                          "${item.price}€ x${item.quantity}",
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

  Widget _paymentMethod() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _sectionTitle("Payment Method"),

          RadioListTile(
            value: "cod",
            groupValue: selectedPayment,
            onChanged: (val) {
              setState(() => selectedPayment = val.toString());
            },
            title: Text("Cash on Delivery",
                style: TextStyle(color: AppColors.textDark)),
          ),

          // RadioListTile(
          //   value: "card",
          //   groupValue: selectedPayment,
          //   onChanged: (val) {
          //     setState(() => selectedPayment = val.toString());
          //   },
          //   title: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     mainAxisAlignment: MainAxisAlignment.start,
          //     children: [
          //        Text("Credit / Debit Card", style: TextStyle(color: AppColors.textDark)),
          //       SizedBox(
          //         height: 40,
          //         child: ListView.builder(
          //           scrollDirection: Axis.horizontal,
          //           physics: const NeverScrollableScrollPhysics(),
          //             shrinkWrap: true,
          //             itemCount: card.length,
          //             itemBuilder: (context, index){
          //             return SvgPicture.asset(card[index], height: 20, width: 20,);
          //             }
          //         ),
          //       ),
          //
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _priceDetails(CartProvider cart) {
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
          const Divider(),
          _priceRow("Grand Total", cart.totalAmount, bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal)),
          styledPrice(value, color: Colors.black),
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
