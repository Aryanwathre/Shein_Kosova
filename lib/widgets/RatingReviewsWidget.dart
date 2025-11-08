import 'package:flutter/material.dart';

class RatingsReviewsWidget extends StatefulWidget {
  final double averageRating;
  final List<Map<String, dynamic>> reviews;

  const RatingsReviewsWidget({
    super.key,
    required this.averageRating,
    required this.reviews,
  });

  @override
  State<RatingsReviewsWidget> createState() => _RatingsReviewsWidgetState();
}

class _RatingsReviewsWidgetState extends State<RatingsReviewsWidget> {
  bool _isExpanded = false;

  Widget _buildStarRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header — Average Rating + Arrow
            GestureDetector(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildStarRow(widget.averageRating),
                      const SizedBox(width: 8),
                      Text(
                        widget.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "(${widget.reviews.length} reviews)",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 26,
                    color: Colors.grey[700],
                  ),
                ],
              ),
            ),

            // Collapsible Reviews Section
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const Divider(height: 20),
                  ...widget.reviews.map((review) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blueGrey[100],
                            child: Text(
                              review['user'][0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review['user'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                _buildStarRow(review['rating']),
                                const SizedBox(height: 4),
                                Text(
                                  review['comment'],
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
