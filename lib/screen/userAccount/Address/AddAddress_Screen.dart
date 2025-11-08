import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/Address_Provider.dart';
import '../../../widgets/custom_text_fields.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  final _postalCodeController = TextEditingController();

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AddressProvider>(context, listen: false);
    final success = await provider.addAddress(
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Failed to add address')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Address")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              inputField(label: "Address Line 1", controller: _addressLine1Controller, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              inputField(label: "Address Line 2 (Optional)", controller: _addressLine2Controller),
              const SizedBox(height: 12),
              inputField(label: "City", controller: _cityController, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              inputField(label: "State", controller: _stateController, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              inputField(label: "Country", controller: _countryController, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              inputField(label: "Postal Code", controller: _postalCodeController, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 24),
              Consumer<AddressProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _saveAddress,
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save Address"),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
