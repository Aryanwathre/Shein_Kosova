import 'package:flutter/material.dart';
import 'package:shein_kosova/utils/htmlWidget.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // HTML content for Privacy Policy
  static const String privacyHTML = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy - SH Kosova</title>
</head>
<body style="font-family: Arial; padding: 20px; line-height: 1.6;">

<h1>Privacy Policy (SH Kosova)</h1>
<p><strong>Effective date:</strong> 22.01.2026</p>

<p>This Privacy Policy explains how SH Kosova collects, uses, and protects personal data when you use www.s-kosova.com.</p>

<h2>1. Who we are (Data Controller)</h2>
<p><strong>Legal name:</strong> SH Unit Kosova (“SH Kosova”)</p>
<p><strong>NUI:</strong> 812274091</p>
<p><strong>Address:</strong> Bulevardi Nënë Tereza, Prishtinë</p>
<p><strong>Email:</strong> info@s-kosova.com</p>
<p><strong>Phone:</strong> +383 49 862 834</p>
<p><strong>Website:</strong> www.s-kosova.com</p>

<h2>2. What data we collect</h2>
<ul>
<li>Identity & contact data: name, email, phone number</li>
<li>Order data: delivery address, ordered items, invoices</li>
<li>Payment data: payment status and transaction references</li>
<li>Support communications</li>
<li>Technical data: IP, device info, cookies</li>
</ul>

<h2>3. Why we use your data</h2>
<ul>
<li>Account management</li>
<li>Order processing</li>
<li>Customer support</li>
<li>Security & fraud prevention</li>
<li>Legal compliance</li>
<li>Service improvement</li>
</ul>

<h2>4. Sharing your data</h2>
<p>We share data only with delivery, payment, and hosting providers. We do not sell your data.</p>

<h2>5. Data retention</h2>
<p>We retain data only as long as necessary for services and legal obligations.</p>

<h2>6. Security</h2>
<p>No system is 100% secure, but we apply reasonable protections.</p>

<h2>7. Your rights</h2>
<p>You can request access, correction, or deletion via info@s-kosova.com.</p>

<h2>8. Cookies</h2>
<p>We use only essential cookies.</p>

<h2>9. Children</h2>
<p>Not intended for children.</p>

<h2>10. Updates</h2>
<p>Policy may be updated with a new effective date.</p>

</body>
</html>''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy"), elevation: 0),
      body: HtmlWidget(
        htmlString: privacyHTML,
        scrollable: true,
        padding: const EdgeInsets.all(16.0),
        backgroundColor: Colors.white,
        textColor: Colors.grey[800],
        fontSize: 15.0,
      ),
    );
  }
}
