class AddressModel {
  // Fields that are not in the API response but are useful for the UI
  final String id;
  String name;
  String phone;
  bool isDefault;
  String addressType;

  // Fields that directly match the API response
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.isDefault,
    required this.addressType,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  /// The fromJson factory correctly maps the API keys to the model's fields.
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      // --- Mapped from API ---
      addressLine1: json['addressLine1'] as String? ?? '',
      addressLine2: json['addressLine2'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      postalCode: (json['postalCode'] as num?)?.toString() ?? '',

      // --- Fields NOT in API - Using safe defaults ---
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'My Address', // A default name
      phone: json['phone'] as String? ?? '', // Default to empty string
      addressType: json['addressType'] as String? ?? 'Home',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
