import 'package:flutter/material.dart';

class BiteSearchBar extends StatelessWidget {
  final Color iconColor; // 👈 accept color from parent

  const BiteSearchBar({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.04;
    final width = MediaQuery.of(context).size.width * 0.9;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          ClipPath(
            clipper: BiteClipper(),
            child: Container(
              height: height,
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 👇 “Bite” area with dynamic icon color
          Positioned(
            right: MediaQuery.of(context).size.width * 0.01,
            top: 0,
            bottom: 0,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Icon(
                Icons.search,
                color: iconColor, // 👈 dynamic color
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌀 Custom Clipper to cut out circular "bite" from the right edge
class BiteClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start top-left
    path.moveTo(0, 0);

    // Line to top-right before bite
    path.lineTo(size.width - 40, 0);

    // Circular "bite" cut
    path.arcToPoint(
      Offset(size.width - 40, size.height),
      radius: const Radius.circular(20),
      clockwise: false,
    );

    // Line back to bottom-left
    path.lineTo(0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
