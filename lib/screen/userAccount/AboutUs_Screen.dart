import 'package:flutter/material.dart';
import 'package:shein_kosova/utils/htmlWidget.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  // HTML content for About Us
  static const String aboutUsHTML = '''
    <h1>About SH Kosova</h1>
    
    <p>Welcome to <b>SH Kosova</b>, your trusted online fashion and lifestyle destination. 
    We are committed to bringing the latest fashion trends at affordable prices directly to your doorstep.</p>
    
    <h2>Our Mission</h2>
    <p>To make fashion accessible and affordable for everyone in Kosova. We believe that everyone deserves 
    to express their personal style without breaking the bank.</p>
    
    <h2>Why Choose Us?</h2>
    <ul>
      <li><b>Wide Selection:</b> Discover thousands of trendy products from clothing to accessories</li>
      <li><b>Affordable Prices:</b> Competitive pricing on all our products</li>
      <li><b>Fast Delivery:</b> Quick and reliable shipping across Kosova</li>
      <li><b>Quality Assurance:</b> We ensure all products meet our quality standards</li>
      <li><b>Easy Returns:</b> Hassle-free return and exchange policy</li>
      <li><b>24/7 Support:</b> Our customer service team is always ready to help</li>
    </ul>
    
    <h2>Our Story</h2>
    <p>Founded with a passion for fashion, SH Kosova started as a small venture to bring international 
    fashion trends to Kosova. Today, we have grown into a leading e-commerce platform serving thousands 
    of satisfied customers.</p>
    
    <h2>Customer First</h2>
    <p>Your satisfaction is our priority. We strive to provide excellent customer service, high-quality 
    products, and a seamless shopping experience.</p>
    
    <h2>Contact Us</h2>
    <p>
      <b>Email:</b> support@s-kosova.com<br>
      <b>Phone:</b> +383 (0) 123 456 789<br>
      <b>Address:</b> S-Kosova HQ, Prishtina, Kosova
    </p>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        elevation: 0,
      ),
      body: HtmlWidget(
        htmlString: aboutUsHTML,
        scrollable: true,
        padding: const EdgeInsets.all(16.0),
        backgroundColor: Colors.white,
        textColor: Colors.grey[800],
        fontSize: 15.0,
      ),
    );
  }
}
