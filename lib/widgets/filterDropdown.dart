import 'package:flutter/material.dart';
import 'package:shein_kosova/utils/AppColors.dart';

class FilterSection extends StatefulWidget {
  String lable;
  List<String> productTypes;
  FilterSection({super.key, required this.lable, required this.productTypes});

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  bool _isExpanded = false;
  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.lable,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.black),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.productTypes.map((type) {
                final isSelected = selected.contains(type);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selected.remove(type);
                      } else {
                        selected.add(type);
                      }
                    });
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      border: Border.all(
                        color:
                        isSelected ? Colors.black : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}
