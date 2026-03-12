import 'package:flutter/material.dart';
import 'package:shein_kosova/utils/htmlWidget.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  // HTML content for Terms & Conditions
  static const String termsHTML = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Terms & Conditions - SH Kosova</title>

  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      margin: 20px;
      color: #333;
      max-width: 900px;
      margin-left: auto;
      margin-right: auto;
    }
    h1, h2 {
      color: #222;
    }
    h1 {
      margin-bottom: 10px;
    }
    p {
      margin: 10px 0;
    }
    ul {
      margin: 10px 0 20px 20px;
    }
    a {
      color: #007bff;
      text-decoration: none;
    }
  </style>
</head>

<body>

<h1>Terms & Conditions (SH Kosova)</h1>
<p><strong>Effective date:</strong> 22.01.2026</p>

<p>
These Terms govern your use of 
<a href="https://www.s-kosova.com" target="_blank">www.s-kosova.com</a> 
and any purchases made through the website. By using the website or placing an order, you agree to these Terms.
</p>

<h2>1. Business information</h2>
<p><strong>Legal name:</strong> SH Unit Kosova (“SH Kosova”)</p>
<p><strong>NUI:</strong> 812274091</p>
<p><strong>Address:</strong> Bulevardi Nënë Tereza, Prishtinë</p>
<p><strong>Email:</strong> <a href="mailto:info@s-kosova.com">info@s-kosova.com</a></p>
<p><strong>Phone:</strong> +383 49 862 834</p>
<p><strong>Website:</strong> <a href="https://www.s-kosova.com" target="_blank">www.s-kosova.com</a></p>

<h2>2. Use of the website</h2>
<p>
You agree not to misuse the website, attempt unauthorized access, interfere with security, 
or use the website for unlawful purposes.
</p>

<h2>3. Accounts</h2>
<p>
If you create an account, you are responsible for keeping your login credentials secure. 
We may suspend or terminate accounts in cases of abuse, fraud, or violations of these Terms.
</p>

<h2>4. Products and information accuracy</h2>
<p>We aim to provide accurate product information (descriptions, images, and prices). However:</p>
<ul>
  <li>Colors may appear slightly different due to screen settings</li>
  <li>Availability and prices may change</li>
</ul>
<p>
We reserve the right to correct errors and update listings at any time.
</p>

<h2>5. Prices and payments</h2>
<p>Prices are displayed in EUR (€).</p>
<p>We accept Card payments and Cash on Delivery (COD) (where available).</p>
<p>
If card payment is used through a payment processor, we do not store full card details.
</p>

<h2>6. Orders and acceptance</h2>
<p>
An order is considered accepted after we confirm it (via website/email/phone).
</p>
<p>If an item becomes unavailable after you place an order, we may cancel the order and:</p>
<ul>
  <li>Provide a refund (if paid), or</li>
  <li>Offer an alternative item</li>
</ul>

<h2>7. Shipping and delivery</h2>
<p>
Delivery timelines and conditions are shown during checkout and/or in our Shipping Policy. 
Delivery times are estimates and may vary due to logistical reasons.
</p>

<h2>8. Returns and refunds</h2>
<p>
Returns and refunds are handled according to our Returns & Refund Policy and applicable consumer rules. 
Certain items may be non-returnable (e.g., hygiene-related items) where applicable.
</p>

</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        elevation: 0,
      ),
      body: HtmlWidget(
        htmlString: termsHTML,
        scrollable: true,
        padding: const EdgeInsets.all(16.0),
        backgroundColor: Colors.white,
        textColor: Colors.grey[800],
        fontSize: 15.0,
      ),
    );
  }
}

