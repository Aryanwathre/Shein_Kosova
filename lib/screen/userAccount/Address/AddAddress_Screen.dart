import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import '../../../provider/address_provider.dart';

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
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _receiverFirstNameController = TextEditingController();
  final _receiverLastNameController = TextEditingController();
  final _contactCodeController = TextEditingController();
  final _contactNumberController = TextEditingController();

  bool _isDefault = false;

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _receiverFirstNameController.dispose();
    _receiverLastNameController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    // Use FULL validation including country, state, city, phone
    if (!_validateAddressForm()) return;

    final provider = Provider.of<AddressProvider>(context, listen: false);

    final success = await provider.addAddress(
      AddressModel(
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        receiverName: "${_receiverFirstNameController.text.trim()} ${_receiverLastNameController.text.trim()}",
        contactNumber: _contactCodeController.text.trim() +
            _contactNumberController.text.trim(),
        isDefault: _isDefault,
        id: '',
      ),
    );

    if (mounted) {
      if (success) Navigator.pop(context);
    }
  }


  bool _validateAddressForm() {
    // Validate all TextFormFields controlled by the Form widget
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Country
    if (_countryController.text.trim().isEmpty) {
      _showError("Please select a country");
      return false;
    }

    // State
    if (_stateController.text.trim().isEmpty) {
      _showError("Please select a state");
      return false;
    }

    // City
    if (_cityController.text.trim().isEmpty) {
      _showError("Please select a city");
      return false;
    }

    // Phone code
    if (_contactCodeController.text.trim().isEmpty) {
      _showError("Select phone code");
      return false;
    }

    // Phone number
    if (_contactNumberController.text.trim().isEmpty) {
      _showError("Enter phone number");
      return false;
    }

    return true; // Everything is valid
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shipping Address"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// FIRST NAME
              _label("First Name*"),
              _textField(
                controller: _receiverFirstNameController,
                label: "",
                validator: _requiredValidator,
              ),
              const SizedBox(height: 20),

              /// LAST NAME
              _label("Last Name*"),
              _textField(
                controller: _receiverLastNameController,
                label: "",
                validator: _requiredValidator,
              ),
              const SizedBox(height: 20),

              /// PHONE NUMBER (with prefix)
              _label("Phone Number*"),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color:   AppColors.border),
                    ),
                    child: CountryCodePicker(
                      padding: const EdgeInsets.all(0),
                      onChanged: (country) {
                        _contactCodeController.text = country.dialCode ?? "";
                      },
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: false,
                      showFlag: false,
                      textStyle: TextStyle(
                        color: AppColors.textNormal,
                        fontSize: 12,
                      ),
                      flagWidth: 20,

                      boxDecoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Flexible(
                    child: _textField(
                      controller: _contactNumberController,
                      label: "",
                      keyboardType: TextInputType.phone,
                      validator: _requiredValidator,

                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),


              _label("Country*"),
              _textField(
                controller: _countryController,
                label: "",
                validator: _requiredValidator,
              ),
              _label("State*"),
              _textField(
                controller: _stateController,
                label: "",
                validator: _requiredValidator,
              ),
              _label("City*"),
              _textField(
                controller: _cityController,
                label: "",
                validator: _requiredValidator,
              ),

              const SizedBox(height: 20),


              /// ZIP CODE
              _label("Post/Zip Code*"),
              _textField(
                controller: _postalCodeController,
                label: "",
                validator: _requiredValidator,
              ),

              const SizedBox(height: 20),

              /// ADDRESS LINE 1
              _label("Address Line 1*"),
              _textField(
                controller: _addressLine1Controller,
                label: "",
                validator: _requiredValidator,
              ),

              const SizedBox(height: 20),

              /// ADDRESS LINE 2
              _label("Address Line 2"),
              _textField(
                label: "",
                controller: _addressLine2Controller,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    onChanged: (value) => setState(() => _isDefault = value!),
                  ),
                  const Text("Set as default address", style: TextStyle(fontSize: 16)),
                ],
              ),

              const SizedBox(height: 30),

              Consumer<AddressProvider>(
                builder: (context, provider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveAddress,
                      child: provider.isLoading
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                          : const Text("Save"),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            width: 0.8,
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            width: 0.8,
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            width: 1,
            color: AppColors.border,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            width: 0.8,
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            width: 1,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }


  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }
    return null;
  }



}
