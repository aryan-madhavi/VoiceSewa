import 'package:cloud_firestore/cloud_firestore.dart';

/// Address model used across the app (for both clients and workers)
/// Location: lib/shared/models/address_model.dart
class Address {
  final GeoPoint location;
  final String line1;
  final String line2;
  final String landmark;
  final String pincode;
  final String city;

  Address({
    required this.location,
    required this.line1,
    required this.line2,
    required this.landmark,
    required this.pincode,
    required this.city,
  });

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'line1': line1,
      'line2': line2,
      'landmark': landmark,
      'pincode': pincode,
      'city': city,
    };
  }

  /// Create from Firestore Map
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      location: map['location'] as GeoPoint,
      line1: map['line1'] as String? ?? '',
      line2: map['line2'] as String? ?? '',
      landmark: map['landmark'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
      city: map['city'] as String? ?? '',
    );
  }

  /// Get full address as string
  String get fullAddress {
    final parts = [
      line1,
      line2,
      landmark,
      city,
      pincode,
    ].where((part) => part.isNotEmpty).join(', ');
    return parts;
  }

  /// Get short address (line1 + city)
  String get shortAddress {
    return '$line1, $city';
  }

  Address copyWith({
    GeoPoint? location,
    String? line1,
    String? line2,
    String? landmark,
    String? pincode,
    String? city,
  }) {
    return Address(
      location: location ?? this.location,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      landmark: landmark ?? this.landmark,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
    );
  }

  @override
  String toString() => fullAddress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Address &&
        other.location == location &&
        other.line1 == line1 &&
        other.line2 == line2 &&
        other.landmark == landmark &&
        other.pincode == pincode &&
        other.city == city;
  }

  @override
  int get hashCode {
    return location.hashCode ^
        line1.hashCode ^
        line2.hashCode ^
        landmark.hashCode ^
        pincode.hashCode ^
        city.hashCode;
  }
}