import 'package:cloud_firestore/cloud_firestore.dart';

/// Address model for client addresses
class ClientAddress {
  final GeoPoint location;
  final String line1;
  final String line2;
  final String landmark;
  final String pincode;
  final String city;

  ClientAddress({
    required this.location,
    required this.line1,
    required this.line2,
    required this.landmark,
    required this.pincode,
    required this.city,
  });

  Map<String, dynamic> toMap() => {
        'location': location,
        'line1': line1,
        'line2': line2,
        'landmark': landmark,
        'pincode': pincode,
        'city': city,
      };

  factory ClientAddress.fromMap(Map<String, dynamic> map) => ClientAddress(
        location: map['location'] as GeoPoint,
        line1: map['line1'] as String,
        line2: map['line2'] as String,
        landmark: map['landmark'] as String,
        pincode: map['pincode'] as String,
        city: map['city'] as String,
      );
}

/// Services tracking for client
class ClientServices {
  final List<DocumentReference> requested;
  final List<DocumentReference> scheduled;
  final List<DocumentReference> completed;
  final List<DocumentReference> cancelled;

  ClientServices({
    this.requested = const [],
    this.scheduled = const [],
    this.completed = const [],
    this.cancelled = const [],
  });

  Map<String, dynamic> toMap() => {
        'requested': requested,
        'scheduled': scheduled,
        'completed': completed,
        'cancelled': cancelled,
      };

  factory ClientServices.fromMap(Map<String, dynamic> map) => ClientServices(
        requested: (map['requested'] as List<dynamic>?)
                ?.map((e) => e as DocumentReference)
                .toList() ??
            [],
        scheduled: (map['scheduled'] as List<dynamic>?)
                ?.map((e) => e as DocumentReference)
                .toList() ??
            [],
        completed: (map['completed'] as List<dynamic>?)
                ?.map((e) => e as DocumentReference)
                .toList() ??
            [],
        cancelled: (map['cancelled'] as List<dynamic>?)
                ?.map((e) => e as DocumentReference)
                .toList() ??
            [],
      );
}

/// Client Profile model matching Firestore schema
class ClientProfile {
  final String uid; // Firebase Auth UID
  final String name;
  final String email;
  final String phone;
  final List<ClientAddress> addresses;
  final ClientServices services;
  final String? fcmToken;

  ClientProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.addresses = const [],
    ClientServices? services,
    this.fcmToken,
  }) : services = services ?? ClientServices();

  /// Check if profile is complete (has minimum required data)
  bool get isComplete => name.isNotEmpty && phone.isNotEmpty;

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'addresses': addresses.map((a) => a.toMap()).toList(),
        'services': services.toMap(),
        if (fcmToken != null) 'fcm_token': fcmToken,
      };

  /// Create from Firestore document
  factory ClientProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ClientProfile(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      addresses: (data['addresses'] as List<dynamic>?)
              ?.map((a) => ClientAddress.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      services: data['services'] != null
          ? ClientServices.fromMap(data['services'] as Map<String, dynamic>)
          : ClientServices(),
      fcmToken: data['fcm_token'] as String?,
    );
  }

  /// Create copy with updated fields
  ClientProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    List<ClientAddress>? addresses,
    ClientServices? services,
    String? fcmToken,
  }) {
    return ClientProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      addresses: addresses ?? this.addresses,
      services: services ?? this.services,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}