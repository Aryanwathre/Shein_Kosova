import 'package:flutter/material.dart';
import 'package:shein_kosova/provider/auth_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/widgets/login_prompt_sheet.dart';

/// Body for account screens when the user is not authenticated.
///
/// These screens used to render a bare CircularProgressIndicator for every
/// non-authenticated state, so a genuinely logged-out user watched it spin
/// forever. Only the transient states justify a spinner; an unauthenticated
/// user needs a way in.
class AuthGateBody extends StatelessWidget {
  final AuthState state;
  final String message;

  const AuthGateBody({
    super.key,
    required this.state,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final resolving =
        state == AuthState.loading || state == AuthState.initial;

    if (resolving) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => showLoginPrompt(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
