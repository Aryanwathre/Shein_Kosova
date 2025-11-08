import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/provider/Address_Provider.dart';
import '../../../widgets/custom_text_fields.dart';

class EditAddressScreen extends StatefulWidget {
  final AddressModel address;
  const EditAddressScreen({super.key, required this.address});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _postalCodeController;

  @override
  void initState() {
    super.initState();
    final adr = widget.address;
    _addressLine1Controller = TextEditingController(text: adr.addressLine1);
    _addressLine2Controller = TextEditingController(text: adr.addressLine2);
    _cityController = TextEditingController(text: adr.city);
    _stateController = TextEditingController(text: adr.state);
    _countryController = TextEditingController(text: adr.country);
    _postalCodeController = TextEditingController(text: adr.postalCode);
  }

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

  Future<void> _updateAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AddressProvider>(context, listen: false);
    final success = await provider.updateAddress(
      id: widget.address.id,
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
          SnackBar(content: Text(provider.errorMessage ?? 'Failed to update address')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Address")),
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
                    onPressed: provider.isLoading ? null : _updateAddress,
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Save Changes"),
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
