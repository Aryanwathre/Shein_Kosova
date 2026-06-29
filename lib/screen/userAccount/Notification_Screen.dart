import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.state != AuthState.authenticated) {
        final loggedIn = await showLoginPrompt(context);
        if (!mounted) return;
        if (loggedIn != true && authProvider.state != AuthState.authenticated) {
          context.pop(); // Bop back
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.state != AuthState.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.notifications),
            title: Text("Notification ${index + 1}"),
            subtitle: const Text("Your order has been shipped."),
          );
        },
      ),
    );
  }
}

