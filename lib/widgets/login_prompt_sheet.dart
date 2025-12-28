import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/utils/AppColors.dart';

Future<bool?> showLoginPrompt(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(Icons.account_circle_outlined, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please log in to access your account, manage your cart, and enjoy a personalized shopping experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop(); // Close bottom sheet
                    context.push('/login?isModal=true');
                  },
                  child: const Text(
                    'Log In',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Not Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
