import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/provider/address_provider.dart';
import 'package:shein_kosova/widgets/custom_text_fields.dart';

class EditAddressScreen extends StatefulWidget {
  final AddressModel address;

  const EditAddressScreen({super.key, required this.address});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _receiverNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _postalCodeController;

  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final a = widget.address;

    _receiverNameController = TextEditingController(text: a.receiverName);
    _contactNumberController = TextEditingController(text: a.contactNumber);
    _addressLine1Controller = TextEditingController(text: a.addressLine1);
    _addressLine2Controller = TextEditingController(text: a.addressLine2);
    _cityController = TextEditingController(text: a.city);
    _stateController = TextEditingController(text: a.state);
    _countryController = TextEditingController(text: a.country);
    _postalCodeController = TextEditingController(text: a.postalCode);
    _isDefault = a.isDefault;
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _contactNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  /// 🔍 Detect changes for enabling/disabling button
  bool _hasChanges() {
    final a = widget.address;
    return
      _receiverNameController.text.trim() != a.receiverName ||
          _contactNumberController.text.trim() != a.contactNumber ||
          _isDefault != (a.isDefault) ||
          _addressLine1Controller.text.trim() != a.addressLine1 ||
          _addressLine2Controller.text.trim() != a.addressLine2 ||
          _cityController.text.trim() != a.city ||
          _stateController.text.trim() != a.state ||
          _countryController.text.trim() != a.country ||
          _postalCodeController.text.trim() != a.postalCode;
  }

  Future<void> _updateAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AddressProvider>(context, listen: false);

    final success = await provider.updateAddress(
    AddressModel(
      id: widget.address.id,
      receiverName: _receiverNameController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      isDefault: _isDefault,
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
    )
    );

    if (!mounted) return;

    if (success) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to update address'),
        ),
      );
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              /// Receiver Name
              inputField(
                label: "Receiver Name",
                controller: _receiverNameController,
                validator: (v) => v!.isEmpty ? "Required" : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              /// Contact Number
              inputField(
                label: "Contact Number",
                controller: _contactNumberController,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Required" : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              /// Default toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Set as Default Address", style: TextStyle(fontSize: 16)),
                  Switch(
                    value: _isDefault,
                    onChanged: (val) {
                      setState(() => _isDefault = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Address Line 1
              inputField(
                label: "Address Line 1",
                controller: _addressLine1Controller,
                validator: (v) => v!.isEmpty ? "Required" : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              /// Address Line 2
              inputField(
                label: "Address Line 2 (Optional)",
                controller: _addressLine2Controller,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              /// City
              inputField(
                label: "City",
                controller: _cityController,
                validator: (v) => v!.isEmpty ? "Required" : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              /// State
              inputField(
                label: "State",
                controller: _stateController,
                validator: (v) => v!.isEmpty ? "Required" : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              /// Country
              inputField(
                label: "Country",
                controller: _countryController,
                validator: (v) => v!.isEmpty ? "Required" : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              /// Postal Code
              inputField(
                label: "Postal Code",
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              Consumer<AddressProvider>(
                builder: (context, provider, child) {
                  final isDisabled = provider.isLoading || !_hasChanges();

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isDisabled ? null : _updateAddress,
                      child: provider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes"),
                    ),
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
