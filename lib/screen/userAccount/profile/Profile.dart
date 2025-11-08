import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/screen/userAccount/AboutUs_Screen.dart';
import 'package:shein_kosova/screen/userAccount/HelpCenter_Screen.dart';

import '../../../provider/Profile_provider.dart';
import '../../../provider/AuthProvider.dart'; // Import AuthProvider for logout
import '../Address/Addresses_Screen.dart';
import '../MyOrder/MyOrder_Screen.dart';
import '../Wishlist_Screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch profile data from the API as soon as the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadUserProfile();
    });
  }

  /// Handles the logout process
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout(context);
      // The AuthWrapper will handle navigating to the login screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          // Handle different states from the provider
          switch (provider.state) {
            case ProfileState.loading:
              return const Center(child: CircularProgressIndicator());
            case ProfileState.error:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(provider.errorMessage ?? 'An error occurred'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadUserProfile(),
                      child: const Text('Retry'),
                    ),
                    TextButton(
                        onPressed: _handleLogout,
                        child: Text('Logout', style: TextStyle(color: Colors.red))
                    )
                  ],
                ),
              );
            case ProfileState.loaded:
            case ProfileState.updating:
              final user = provider.userProfile;
              if (user == null) {
                return const Center(child: Text("Could not load profile."));
              }

              // Main profile UI
              return RefreshIndicator(
                onRefresh: () => provider.loadUserProfile(),
                child: ListView(
                  children: [
                    _ProfileHeader(
                      name: user.fullName,
                      email: user.email,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _ProfileMenu(onLogout: _handleLogout),
                  ],
                ),
              );
            default:
              return const Center(child: Text("Welcome!"));
          }
        },
      ),
    );
  }
}

/// A dedicated widget for the profile header.
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // A simple circle avatar with initials
          CircleAvatar(
            radius: 35,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'G',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onEdit,
                  child: const Text("Edit Profile"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// A dedicated widget for the menu options.
class _ProfileMenu extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfileMenu({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuTile(
            icon: Icons.shopping_bag_outlined,
            title: "My Orders",
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const MyOrdersScreen()));
            }),
        _MenuTile(
            icon: Icons.favorite_border,
            title: "Wishlist",
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const WishlistScreen()));
            }),
        _MenuTile(
            icon: Icons.notifications_none,
            title: "Notifications",
            onTap: () {
              // TODO: Navigate to Notifications Page
            }),
        const Divider(),
        _MenuTile(
            icon: Icons.location_on_outlined,
            title: "Saved Addresses",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedAddressesPage()),
              );
            }),
        _MenuTile(
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () {
              // TODO: Navigate to Change Password Page
            }),
        const Divider(),
        _MenuTile(
            icon: Icons.help_outline,
            title: "Help Center",
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const HelpCenterPage()));
            }),
        _MenuTile(
            icon: Icons.info_outline,
            title: "About Us",
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage()));
            }),
        const Divider(),
        _MenuTile(
          icon: Icons.logout,
          title: "Logout",
          color: Colors.red,
          onTap: onLogout,
        ),
      ],
    );
  }
}

/// A reusable widget for each menu item tile.
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = color ?? Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icon, color: titleColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      onTap: onTap,
    );
  }
}
