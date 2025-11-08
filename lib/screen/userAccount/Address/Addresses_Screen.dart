import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/provider/Address_Provider.dart';
import 'package:shein_kosova/screen/userAccount/Address/EditAddress_Screen.dart';
import 'AddAddress_Screen.dart';

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressProvider>(context, listen: false).loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Addresses"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<AddressProvider>(context, listen: false).loadAddresses(),
          ),
        ],
      ),
      body: Consumer<AddressProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.addresses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.addresses.isEmpty) {
            return Center(child: Text(provider.errorMessage ?? 'An error occurred.'));
          }
          if (provider.isEmpty) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No addresses saved."),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAddressScreen())),
                      child: const Text('Add Address'),
                    )
                  ],
                )
            );
          }
          return ListView.builder(
            itemCount: provider.addresses.length,
            itemBuilder: (context, index) {
              final address = provider.addresses[index];
              return _buildAddressCard(address);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAddressScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(address.name), // Uses the default 'My Address' or a name if provided by API
        subtitle: Text(
          '${address.addressLine1}, ${address.city}, ${address.state} - ${address.postalCode}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditAddressScreen(address: address)),
            );
          },
        ),
      ),
    );
  }
}
