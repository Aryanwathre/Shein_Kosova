import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Shein Kosova", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("We are your trusted fashion e-commerce platform bringing the latest trends "
                "at affordable prices. Our goal is to make fashion accessible for everyone."),
            SizedBox(height: 20),
            Text("Version 1.0.0"),
          ],
        ),
      ),
    );
  }
}
