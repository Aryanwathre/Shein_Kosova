class AddressModel {
  final String id;
  final String receiverName;    // API: receiverName
  final String contactNumber;   // API: contact_number
  final bool isDefault;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String postalCode; // keep as String for consistency

  AddressModel({
    required this.id,
    required this.receiverName,
    required this.contactNumber,
    required this.isDefault,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // helpers to be tolerant of API key variations
    String readString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    return AddressModel(
      id: readString(json['id'] ?? json['addressId'] ?? DateTime.now().millisecondsSinceEpoch),
      receiverName: readString(json['receiverName'] ?? json['name'] ?? ''),
      contactNumber: readString(json['contact_number'] ?? json['contactNumber'] ?? json['phone'] ?? ''),
      isDefault: (json['isDefault'] is bool) ? json['isDefault'] : (json['is_default'] is bool ? json['is_default'] : (json['default'] as bool?) ?? false),
      addressLine1: readString(json['addressLine1'] ?? json['address_line1'] ?? ''),
      addressLine2: readString(json['addressLine2'] ?? json['address_line2'] ?? ''),
      city: readString(json['city'] ?? ''),
      state: readString(json['state'] ?? ''),
      country: readString(json['country'] ?? ''),
      postalCode: (json['postalCode'] ?? json['postal_code'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverName': receiverName,
      'contact_number': contactNumber, // backend expects this key per your payload example
      'isDefault': isDefault,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }

  factory AddressModel.object(Map<String, dynamic> json) {


    return AddressModel(
      id: '',
      receiverName: '',
      contactNumber: '',
      isDefault: false,
      addressLine1: '',
      addressLine2: '',
      city: '',
      state: '',
      country: '',
      postalCode:'',
    );
  }

  AddressModel copyWith({
    String? id,
    String? receiverName,
    String? contactNumber,
    bool? isDefault,
    String? addressType,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) {
    return AddressModel(
      id: id ?? this.id,
      receiverName: receiverName ?? this.receiverName,
      contactNumber: contactNumber ?? this.contactNumber,
      isDefault: isDefault ?? this.isDefault,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
    );
  }


}
