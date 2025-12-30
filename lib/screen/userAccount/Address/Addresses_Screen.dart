import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/provider/address_provider.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

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
      Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Addresses"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
        },
        child: Consumer<AddressProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.addresses.isEmpty) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerWidget.rectangular(height: 80),
                ),
              );
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
                        onPressed: () => context.push('/add-address'),
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
                return _buildAddressCard(address, index);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-address'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address, int index) {
    return Dismissible(
      key: ValueKey(address.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Address?"),
            content: const Text("Are you sure you want to delete this address?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => context.pop(false),
              ),
              ElevatedButton(
                child: const Text("Delete"),
                onPressed: () async {
                  final provider = Provider.of<AddressProvider>(context, listen: false);
                  await provider.deleteAddress(address.id);
                  await provider.fetchAddresses();
                  if (context.mounted) context.pop(true);
                },
              ),
            ],
          ),
        );
      },

      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(
            '${address.receiverName}, ${address.contactNumber}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${address.addressLine1}, ${address.city}, ${address.state} - ${address.postalCode}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/edit-address', extra: address);
            },
          ),
        ),
      ),
    );
  }


}
