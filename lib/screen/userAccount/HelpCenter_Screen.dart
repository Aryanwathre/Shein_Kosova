import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help Center")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text("FAQs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Q: How to track my order?\nA: You can track it from My Orders."),
          SizedBox(height: 20),
          Text("Q: How to change my password?\nA: Use the Change Password option in Profile."),
          SizedBox(height: 20),
          Text("For more help, contact support@sheinkosova.com"),
        ],
      ),
    );
  }
}
