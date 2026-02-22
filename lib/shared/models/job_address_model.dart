import 'package:cloud_firestore/cloud_firestore.dart';

/// Job address — stores only what the schema defines for a job's address:
/// location (GeoPoint), city, and pincode.
/// Full address details live on the client's address (workers don't need line1/line2).
class JobAddress {
  final GeoPoint? location;
  final String city;
  final String pincode;

  const JobAddress({this.location, this.city = '', this.pincode = ''});

  factory JobAddress.fromMap(Map<String, dynamic> map) => JobAddress(
    location: map['location'] as GeoPoint?,
    city: map['city'] as String? ?? '',
    pincode: map['pincode'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'location': location,
    'city': city,
    'pincode': pincode,
  };

  /// Display string for UI — "City, Pincode"
  String get displayAddress {
    final parts = [city, pincode].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  String toString() => displayAddress;
}
