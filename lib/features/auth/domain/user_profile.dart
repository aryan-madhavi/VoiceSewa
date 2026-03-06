// lib/features/auth/domain/user_profile.dart
//
// Firestore document stored at users/{uid}.
// Written on sign-up and updated whenever FCM token rotates.
//
// Fields:
//   uid         — Firebase Auth UID (also the doc ID)
//   displayName — set during sign-up or Google sign-in
//   email       — user's email address
//   language    — BCP-47 sourceLang code e.g. "hi-IN", default "hi-IN"
//   fcmToken    — latest FCM registration token (set by FcmService)
//   createdAt   — account creation timestamp

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.language,
    required this.createdAt,
    this.fcmToken,
  });

  final String    uid;
  final String    displayName;
  final String    email;
  final String    language;   // BCP-47 sourceLang e.g. "hi-IN"
  final DateTime  createdAt;
  final String?   fcmToken;

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid:         doc.id,
      displayName: data['displayName'] as String? ?? '',
      email:       data['email']       as String? ?? '',
      language:    data['language']    as String? ?? 'hi-IN',
      fcmToken:    data['fcmToken']    as String?,
      createdAt:   data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid':         uid,
        'displayName': displayName,
        'email':       email,
        'language':    language,
        'fcmToken':    fcmToken,
        'createdAt':   Timestamp.fromDate(createdAt),
      };

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? language,
    String? fcmToken,
  }) =>
      UserProfile(
        uid:         uid,
        displayName: displayName ?? this.displayName,
        email:       email       ?? this.email,
        language:    language    ?? this.language,
        fcmToken:    fcmToken    ?? this.fcmToken,
        createdAt:   createdAt,
      );
}