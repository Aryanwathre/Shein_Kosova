import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/UserProfile.dart';
import '../../../provider/Profile_provider.dart';
import '../../../widgets/custom_text_fields.dart';


class EditProfileScreen extends StatefulWidget {

  final UserProfile user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the current user's data
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? "");
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Handles the save button press
  Future<void> _saveProfile() async {
    // First, validate the form
    if (_formKey.currentState?.validate() ?? false) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      // Call the provider to update the profile via the API
      bool success = await profileProvider.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      // Show feedback to the user based on the API call result
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.of(context).pop(); // Go back to the profile screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileProvider.errorMessage ?? 'Failed to update profile.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // First Name Field
              Text("First Name", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              inputField(
                controller: _firstNameController,
                label: "First Name",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name Field
              Text("Last Name", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              inputField(
                controller: _lastNameController,
                label: "Last Name",
              ),
              const SizedBox(height: 16),

              // Email Field
              Text("Email", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              inputField(
                controller: _emailController,
                label: "Email",
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              Text("Phone (Optional)", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              inputField(
                controller: _phoneController,
                label: "Phone",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Save Button with Loading State
              Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    // Disable the button when the provider is in the 'updating' state
                    onPressed: provider.isUpdating ? null : _saveProfile,
                    child: provider.isUpdating
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
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
