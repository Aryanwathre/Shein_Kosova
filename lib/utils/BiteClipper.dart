import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BiteSearchBar extends StatelessWidget {
  final Color iconColor;

  const BiteSearchBar({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    // A compact, proper search pill: fixed height, fills the width its parent
    // (an Expanded in the app bar) gives it, so it sits neatly between the logo
    // and the wishlist icon.
    return GestureDetector(
      onTap: () {
        context.push('/search');
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.black54, size: 20),
            SizedBox(width: 8),
            Text(
              'Search',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
