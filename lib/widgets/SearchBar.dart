import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:shein_kosova/widgets/bottomNavigationBar.dart';


Widget buildSearchBar(BuildContext context) {
  return InkWell(
    onTap: () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context)=>LandingPage(selectedIndex: 3))); // your search page route
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.04,
      width: MediaQuery.of(context).size.width * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Search products...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),


        ],
      ),
    ),
  );
}