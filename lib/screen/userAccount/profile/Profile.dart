import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

import '../../../provider/Profile_provider.dart';
import '../../../provider/auth_provider.dart'; // Import AuthProvider for logout

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

    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      // Safety fallback (should rarely happen)
      return const Scaffold(body: Center(child: ShimmerWidget.rectangular(height: 200)));
    }
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
              return _buildShimmerLoading();
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
                        child: const Text('Logout', style: TextStyle(color: Colors.red))
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
                        context.push('/edit-profile', extra: user);
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

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const ShimmerWidget.circular(width: 70, height: 70),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerWidget.rectangular(height: 24, width: 150),
                  const SizedBox(height: 10),
                  const ShimmerWidget.rectangular(height: 16, width: 200),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 40),
        ...List.generate(5, (index) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: ShimmerWidget.rectangular(height: 50),
        )),
      ],
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
              context.push('/my-orders');
            }),
        _MenuTile(
            icon: Icons.favorite_border,
            title: "Wishlist",
            onTap: () {
              context.push('/wishlist');
            }),
        _MenuTile(
            icon: Icons.notifications_none,
            title: "Notifications",
            onTap: () {
              context.push('/notifications');
            }),
        const Divider(),
        _MenuTile(
            icon: Icons.location_on_outlined,
            title: "Saved Addresses",
            onTap: () {
              context.push('/addresses');
            }),
        _MenuTile(
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () {
              context.push('/change-password');
            }),
        const Divider(),
        _MenuTile(
            icon: Icons.help_outline,
            title: "Help Center",
            onTap: () {
              context.push('/help-center');
            }),
        _MenuTile(
            icon: Icons.info_outline,
            title: "About Us",
            onTap: () {
              context.push('/about-us');
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
