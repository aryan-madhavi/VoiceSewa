import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'dart:math' as math;

class WorkerModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String profileImg;
  final double avgRating;
  final List<Review> reviews;
  final List<String> skillsList;
  final WorkerAddress address;
  final WorkerJobs jobs;
  final String fcmToken;

  // UI fields — nullable/optional, not in Firestore schema
  final Services service; // derived from skills
  final bool? available; // derived from jobs.confirmed count
  final String? voiceText; // derived from bio

  WorkerModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.profileImg,
    required this.avgRating,
    required this.reviews,
    required this.skillsList,
    required this.address,
    required this.jobs,
    required this.fcmToken,
    required this.service,
    this.available,
    this.voiceText,
  });

  // ── Computed UI properties ──────────────────────────────────────────────────

  double get rating => avgRating;
  String get photoUrl => profileImg;
  List<String>? get skills => skillsList;

  /// A worker is "verified" if they have ≥5 reviews and avg rating ≥ 4.5
  bool get verified => reviews.length >= 5 && avgRating >= 4.5;

  Color get serviceColor => ServicesData.services[service]![0] as Color;
  IconData get serviceIcon => ServicesData.services[service]![1] as IconData;
  String get serviceLabel => ServicesData.services[service]![2] as String;

  /// Compute distance string from a reference GeoPoint (client's selected address)
  /// Returns formatted string like "1.2 km". Returns null if no reference given.
  String distanceFrom(GeoPoint reference) {
    final km = calculateDistance(
      reference.latitude,
      reference.longitude,
      address.location.latitude,
      address.location.longitude,
    );
    return '${km.toStringAsFixed(1)} km';
  }

  /// Raw distance in km from a reference GeoPoint
  double distanceKmFrom(GeoPoint reference) {
    return calculateDistance(
      reference.latitude,
      reference.longitude,
      address.location.latitude,
      address.location.longitude,
    );
  }

  // ── Firestore ───────────────────────────────────────────────────────────────

  factory WorkerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final skillsList = List<String>.from(data['skills'] ?? []);
    final jobsMap = data['jobs'] as Map<String, dynamic>? ?? {};

    return WorkerModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      profileImg: data['profile_img'] as String? ?? '',
      avgRating: (data['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviews:
          (data['reviews'] as List<dynamic>?)
              ?.map((r) => Review.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      skillsList: skillsList,
      address: WorkerAddress.fromMap(
        data['address'] as Map<String, dynamic>? ?? {},
      ),
      jobs: WorkerJobs.fromMap(jobsMap),
      fcmToken: data['fcm_token'] as String? ?? '',
      service: _getServiceFromSkills(skillsList),
      available: _checkAvailability(jobsMap),
      voiceText: data['bio'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'phone': phone,
    'bio': bio,
    'profile_img': profileImg,
    'avg_rating': avgRating,
    'reviews': reviews.map((r) => r.toMap()).toList(),
    'skills': skillsList,
    'address': address.toMap(),
    'jobs': jobs.toMap(),
    'fcm_token': fcmToken,
  };

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Derive service enum from skills list keywords
  static Services _getServiceFromSkills(List<String> skills) {
    final lower = skills.map((s) => s.toLowerCase()).toList();

    if (lower.any((s) => s.contains('clean'))) return Services.houseCleaner;
    if (lower.any((s) => s.contains('plumb'))) return Services.plumber;
    if (lower.any((s) => s.contains('electric'))) return Services.electrician;
    if (lower.any((s) => s.contains('carpen'))) return Services.carpenter;
    if (lower.any((s) => s.contains('paint'))) return Services.painter;
    if (lower.any((s) => s.contains('ac') || s.contains('appliance'))) {
      return Services.acApplianceTechnician;
    }
    if (lower.any(
      (s) => s.contains('mechanic') || s.contains('2w') || s.contains('4w'),
    )) {
      return Services.mechanic;
    }
    if (lower.any((s) => s.contains('cook') || s.contains('chef'))) {
      return Services.cook;
    }
    if (lower.any((s) => s.contains('driv'))) return Services.driverOnDemand;
    if (lower.any((s) => s.contains('mason') || s.contains('handyman'))) {
      return Services.handymanMasonryWork;
    }
    return Services.houseCleaner;
  }

  /// Worker is available if they have fewer than 3 active confirmed jobs
  static bool _checkAvailability(Map<String, dynamic> jobsData) {
    final confirmed = jobsData['confirmed'] as List<dynamic>? ?? [];
    return confirmed.length < 3;
  }
}

// ── Sub-models ──────────────────────────────────────────────────────────────

class Review {
  final double rating;
  final String review;

  Review({required this.rating, required this.review});

  factory Review.fromMap(Map<String, dynamic> map) => Review(
    rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    review: map['review'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'rating': rating, 'review': review};
}

class WorkerAddress {
  final GeoPoint location;
  final String pincode;
  final String city;

  // Optional — schema only requires location, pincode, city for workers
  final String line1;
  final String line2;
  final String landmark;

  WorkerAddress({
    required this.location,
    required this.pincode,
    required this.city,
    this.line1 = '',
    this.line2 = '',
    this.landmark = '',
  });

  factory WorkerAddress.fromMap(Map<String, dynamic> map) => WorkerAddress(
    location:
        map['location'] as GeoPoint? ??
        const GeoPoint(19.1958, 73.1964), // Ambarnath fallback
    pincode: map['pincode'] as String? ?? '',
    city: map['city'] as String? ?? '',
    line1: map['line1'] as String? ?? '',
    line2: map['line2'] as String? ?? '',
    landmark: map['landmark'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'location': location,
    'pincode': pincode,
    'city': city,
    if (line1.isNotEmpty) 'line1': line1,
    if (line2.isNotEmpty) 'line2': line2,
    if (landmark.isNotEmpty) 'landmark': landmark,
  };
}

class WorkerJobs {
  final List<DocumentReference> applied;
  final List<DocumentReference> confirmed;
  final List<DocumentReference> completed;
  final List<DocumentReference> declined;

  WorkerJobs({
    required this.applied,
    required this.confirmed,
    required this.completed,
    required this.declined,
  });

  factory WorkerJobs.fromMap(Map<String, dynamic> map) => WorkerJobs(
    applied: List<DocumentReference>.from(map['applied'] ?? []),
    confirmed: List<DocumentReference>.from(map['confirmed'] ?? []),
    completed: List<DocumentReference>.from(map['completed'] ?? []),
    declined: List<DocumentReference>.from(map['declined'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'applied': applied,
    'confirmed': confirmed,
    'completed': completed,
    'declined': declined,
  };
}

// ── Haversine distance utility ───────────────────────────────────────────────

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0; // Earth radius in km
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * math.pi / 180;
