import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/address_provider.dart';
import '../../provider/cart_provider.dart';
import '../../provider/orders_provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AddressProvider>(context, listen: false).loadAddresses();
      Provider.of<CartProvider>(context, listen: false).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final checkoutProvider = Provider.of<OrdersProvider>(context);

    final totalAmount = cartProvider.totalAmount;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: checkoutProvider.state == CheckoutState.loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _addressSection(addressProvider),
              const SizedBox(height: 16),
              _cartItemsSection(cartProvider),
              const SizedBox(height: 16),
              _amountSummarySection(totalAmount),
              const SizedBox(height: 16),
              _paymentMethodSection(),
              const SizedBox(height: 20),
              if (selectedPaymentMethod != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: checkoutProvider.state ==
                        CheckoutState.loading
                        ? null
                        : () async {
                      final selectedAddress =
                      addressProvider.addresses.isNotEmpty
                          ? addressProvider.addresses.first
                          : null;

                      if (selectedAddress == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please select a delivery address'),
                          ),
                        );
                        return;
                      }

                      await checkoutProvider.createOrder(
                        addressId: selectedAddress.id.toString(),
                        paymentMethod: selectedPaymentMethod!,
                      );

                      if (checkoutProvider.state ==
                          CheckoutState.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Order placed successfully')),
                        );
                        Navigator.pop(context);
                      } else if (checkoutProvider.state ==
                          CheckoutState.error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              checkoutProvider.errorMessage ??
                                  'Failed to place order',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: checkoutProvider.state ==
                        CheckoutState.loading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      "Place Order",
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Delivery Address Section ---
  Widget _addressSection(AddressProvider provider) {
    final address =
    provider.addresses.isNotEmpty ? provider.addresses.first : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        title: Text(
          address != null
              ? "${address.addressLine1}, ${address.city}"
              : "No address found",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          address != null
              ? "${address.state}, ${address.country} - ${address.postalCode}"
              : "Add a delivery address",
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to address selection page
        },
      ),
    );
  }

  // --- Cart Items Section ---
  Widget _cartItemsSection(CartProvider provider) {
    if (provider.state == CartState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.items.isEmpty) {
      return const Center(child: Text("No items in cart"));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: provider.items.map((item) {
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(item.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text("Qty: ${item.quantity}"),
            trailing: Text("€${(item.price * item.quantity).toStringAsFixed(2)}"),
          );
        }).toList(),
      ),
    );
  }

  // --- Amount Summary Section ---
  Widget _amountSummarySection(double total) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _priceRow("Subtotal", total),
            _priceRow("Shipping", 0),
            const Divider(),
            _priceRow("Total Payable", total, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("€${amount.toStringAsFixed(2)}",
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // --- Payment Method Section ---
  Widget _paymentMethodSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            RadioListTile<String>(
              title: const Text("Cash on Delivery (COD)"),
              value: "COD",
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() => selectedPaymentMethod = value);
              },
            ),
            RadioListTile<String>(
              title: const Text("Online Payment"),
              value: "ONLINE",
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() => selectedPaymentMethod = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
