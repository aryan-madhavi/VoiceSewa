import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';

/// Services tracking for client - stores DocumentReferences to jobs
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
    requested:
        (map['requested'] as List<dynamic>?)
            ?.map((e) => e as DocumentReference)
            .toList() ??
        [],
    scheduled:
        (map['scheduled'] as List<dynamic>?)
            ?.map((e) => e as DocumentReference)
            .toList() ??
        [],
    completed:
        (map['completed'] as List<dynamic>?)
            ?.map((e) => e as DocumentReference)
            .toList() ??
        [],
    cancelled:
        (map['cancelled'] as List<dynamic>?)
            ?.map((e) => e as DocumentReference)
            .toList() ??
        [],
  );

  /// Get job IDs from references
  List<String> get requestedIds => requested.map((ref) => ref.id).toList();
  List<String> get scheduledIds => scheduled.map((ref) => ref.id).toList();
  List<String> get completedIds => completed.map((ref) => ref.id).toList();
  List<String> get cancelledIds => cancelled.map((ref) => ref.id).toList();
}

/// Client Profile model matching Firestore schema
/// Location: lib/features/auth/models/client_model.dart
class ClientProfile {
  final String uid; // Firebase Auth UID (used as document ID)
  final String name;
  final String email;
  final String phone;
  final List<Address> addresses; // Uses shared Address model
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

  /// Check if client has addresses
  bool get hasAddresses => addresses.isNotEmpty;

  /// Get primary address (first one)
  Address? get primaryAddress => addresses.isEmpty ? null : addresses.first;

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'phone': phone,
    'addresses': addresses.map((a) => a.toMap()).toList(),
    'services': services.toMap(),
    if (fcmToken != null) 'fcm_token': fcmToken,
  };

  /// Create from Firestore document snapshot
  factory ClientProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ClientProfile(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      addresses:
          (data['addresses'] as List<dynamic>?)
              ?.map((a) => Address.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      services: data['services'] != null
          ? ClientServices.fromMap(data['services'] as Map<String, dynamic>)
          : ClientServices(),
      fcmToken: data['fcm_token'] as String?,
    );
  }

  /// ✅ Create from Map (for compatibility with client_provider.dart)
  factory ClientProfile.fromMap(String uid, Map<String, dynamic> data) {
    return ClientProfile(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      addresses:
          (data['addresses'] as List<dynamic>?)
              ?.map((a) => Address.fromMap(a as Map<String, dynamic>))
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
    List<Address>? addresses,
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

  @override
  String toString() => 'ClientProfile(uid: $uid, name: $name, email: $email)';
}
