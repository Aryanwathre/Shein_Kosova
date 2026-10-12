class SizeUtils {
  /// Priority list for sorting sizes. 
  /// Combines common alpha sizes and their numeric equivalents (EU sizes) 
  /// to handle mixed alpha-numeric data.
  static final List<String> _sizeOrder = [
    '32', 'XXS',
    '34', 'XS',
    '36', 'S',
    '38', 'M',
    '40', 'L',
    '42', 'XL',
    '44', 'XXL', '0XL',
    '46', '1XL',
    '48', '2XL',
    '50', '3XL',
    '52', '4XL',
    '54', '5XL',
    '56', '6XL',
    '58', '7XL',
    '60', '8XL',
    '62', '9XL',
    '64', '10XL',
    'ONE-SIZE', 'OS',
  ];

  static List<String> sortSizes(List<String> sizes) {
    if (sizes.isEmpty) return [];
    
    final List<String> sorted = List.from(sizes);
    
    sorted.sort((a, b) {
      final aVal = a.trim().toUpperCase();
      final bVal = b.trim().toUpperCase();

      // 1. Try to get weight from predefined list
      double aWeight = _getPredefinedWeight(aVal);
      double bWeight = _getPredefinedWeight(bVal);

      if (aWeight != bWeight) {
        return aWeight.compareTo(bWeight);
      }

      // 2. Fallback for pure numeric sorting if neither is in the list
      final aNum = _extractNumber(aVal);
      final bNum = _extractNumber(bVal);

      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }

      if (aNum != null) return -1;
      if (bNum != null) return 1;

      // 3. Last fallback: alphabetical
      return aVal.compareTo(bVal);
    });

    return sorted;
  }

  /// Returns a weight based on the predefined _sizeOrder list.
  /// Handles ranges like "XS-XL" by using the first part.
  static double _getPredefinedWeight(String size) {
    String s = size;

    // Handle ranges like "XS-XL" or "S/M" by evaluating based on the first size in range
    if (s.contains('-') || s.contains('/')) {
      s = s.split(RegExp(r'[-/]'))[0].trim();
    }

    int index = _sizeOrder.indexOf(s);
    if (index != -1) return index.toDouble();

    // Special check for variants like "SIZE 38" or "EU 40"
    final match = RegExp(r'(\d+)').firstMatch(s);
    if (match != null) {
      int idx = _sizeOrder.indexOf(match.group(1)!);
      if (idx != -1) return idx.toDouble();
    }

    return 999.0; // Push unknowns to the end
  }

  static double? _extractNumber(String s) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(s);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }
}
