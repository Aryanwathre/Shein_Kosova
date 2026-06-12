import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shein_kosova/constants/payment_error_codes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentProcessingPage extends StatefulWidget {
  final String redirectUrl;
  final String orderId;

  const PaymentProcessingPage({
    super.key,
    required this.redirectUrl,
    required this.orderId,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _redirectToPaymentGateway();
    } else {
      _initializeWebView();
    }
  }

  Future<void> _redirectToPaymentGateway() async {
    final url = Uri.parse(widget.redirectUrl);
    debugPrint('🌐 Web: Redirecting to payment gateway: ${widget.redirectUrl}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch payment page')),
        );
      }
    }
  }

  void _initializeWebView() {
    // Clear cookies to ensure a fresh payment session on mobile
    // This helps prevent "Session is unavailable" errors caused by stale session data
    // On Web, we avoid this as it might clear the user's authentication token
    if (!kIsWeb) {
      WebViewCookieManager().clearCookies();
    }
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🌐 Page started loading: $url');
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            debugPrint('✅ Page finished loading: $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ Web resource error: ${error.description}');
            // Only show error for major failures, ignore minor resource issues
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error loading payment page')),
                );
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('🔗 Navigation requested: ${request.url}');
            final uri = Uri.parse(request.url);

            // Check for success redirect URLs
            if (request.url.contains('success') ||
                request.url.contains('order-success') ||
                request.url.contains('paymentSuccess')) {
              debugPrint(
                '✅ Payment successful! Redirecting to order success page...',
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  context.pushReplacement('/order-success');
                }
              });
              return NavigationDecision.prevent;
            }

            // Check for failure/cancel redirects
            if (request.url.contains('cancel') ||
                request.url.contains('failed') ||
                request.url.contains('fail') ||
                request.url.contains('error')) {
              
              // Extract error code from query parameters if available
              String? errorCode = uri.queryParameters['code'] ?? 
                                 uri.queryParameters['errorCode'] ?? 
                                 uri.queryParameters['resultCode'] ??
                                 uri.queryParameters['error'] ??
                                 uri.queryParameters['responseCode'] ??
                                 uri.queryParameters['reasonCode'];
                                 
              String errorMessage = errorCode != null 
                  ? PaymentErrorCodes.getMessage(errorCode)
                  : 'Payment was cancelled or failed';

              debugPrint('❌ Payment cancelled or failed: $errorMessage');
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              });
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
    
    // Explicitly log the URL being loaded for debugging
    debugPrint('🎬 Loading Payment URL: ${widget.redirectUrl}');
    _webViewController.loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text("Redirecting to payment gateway..."),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _redirectToPaymentGateway,
                child: const Text("Click here if you are not redirected automatically"),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
      },
      child: Scaffold(
        body: SafeArea(child: WebViewWidget(controller: _webViewController)),
      ),
    );
  }
}
