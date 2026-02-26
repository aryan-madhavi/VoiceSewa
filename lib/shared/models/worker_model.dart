import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';

// ── Geohash helper ─────────────────────────────────────────────────────────
// Precision 9 = ~5m accuracy.
// NOTE: dart_geohash takes (longitude, latitude) — longitude FIRST.
//
// Add to pubspec.yaml:
//   dart_geohash: ^1.0.2

String? _computeGeohash(GeoPoint? point, {int precision = 9}) {
  if (point == null) return null;
  return GeoHasher().encode(
    point.longitude, // longitude first!
    point.latitude,
    precision: precision,
  );
}

// ── Worker Model ───────────────────────────────────────────────────────────

class WorkerModel {
  final String workerId;
  final String name;
  final String email;
  final String phone;
  final String? bio;
  final String? profileImg;
  final double avgRating;
  final List<String> skills;
  final String? fcmToken;
  final WorkerAddress? address;
  final WorkerJobs jobs;
  final List<WorkerReview> reviews;

  WorkerModel({
    required this.workerId,
    required this.name,
    required this.email,
    required this.phone,
    this.bio,
    this.profileImg,
    this.avgRating = 0.0,
    this.skills = const [],
    this.fcmToken,
    this.address,
    WorkerJobs? jobs,
    this.reviews = const [],
  }) : jobs = jobs ?? WorkerJobs();

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'bio': bio,
    'profile_img': profileImg,
    'avg_rating': avgRating,
    'skills': skills,
    'fcm_token': fcmToken,
    'address': address?.toMap(),
    'jobs': jobs.toMap(),
    'reviews': reviews.map((r) => r.toMap()).toList(),
  };

  factory WorkerModel.fromMap(String uid, Map<String, dynamic> map) {
    return WorkerModel(
      workerId: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      bio: map['bio'] as String?,
      profileImg: map['profile_img'] as String?,
      avgRating: (map['avg_rating'] as num?)?.toDouble() ?? 0.0,
      skills: List<String>.from(map['skills'] as List? ?? []),
      fcmToken: map['fcm_token'] as String?,
      address: map['address'] != null
          ? WorkerAddress.fromMap(map['address'] as Map<String, dynamic>)
          : null,
      jobs: map['jobs'] != null
          ? WorkerJobs.fromMap(map['jobs'] as Map<String, dynamic>)
          : WorkerJobs(),
      reviews:
          (map['reviews'] as List?)
              ?.map((r) => WorkerReview.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory WorkerModel.fromDoc(DocumentSnapshot doc) =>
      WorkerModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  WorkerModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? profileImg,
    double? avgRating,
    List<String>? skills,
    String? fcmToken,
    WorkerAddress? address,
    WorkerJobs? jobs,
    List<WorkerReview>? reviews,
  }) {
    return WorkerModel(
      workerId: workerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      profileImg: profileImg ?? this.profileImg,
      avgRating: avgRating ?? this.avgRating,
      skills: skills ?? this.skills,
      fcmToken: fcmToken ?? this.fcmToken,
      address: address ?? this.address,
      jobs: jobs ?? this.jobs,
      reviews: reviews ?? this.reviews,
    );
  }
}

// ── WorkerAddress ──────────────────────────────────────────────────────────
// Stores location (GeoPoint), city, pincode, and geohash.
//
// Geohash is auto-computed from location in the constructor —
// no manual call needed anywhere in the app.
//
// Firestore schema:
//   address: {
//     location: GeoPoint,
//     geohash: "tdr1wz3kp",   ← queryable via where('address.geohash', ...)
//     city: "Mumbai",
//     pincode: "400001",
//   }
//
// Cloud Function queries workers near a job using:
//   .where('address.geohash', '>=', prefix)
//   .where('address.geohash', '<',  prefix + '\uf8ff')

class WorkerAddress {
  final GeoPoint? location;
  final String city;
  final String pincode;

  /// Auto-computed from [location] using dart_geohash (precision 9 = ~5m).
  /// Null only if location is null.
  final String? geohash;

  WorkerAddress({
    this.location,
    required this.city,
    required this.pincode,
    String? geohash,
  }) : geohash = geohash ?? _computeGeohash(location);

  Map<String, dynamic> toMap() => {
    'location': location,
    'geohash': geohash,
    'city': city,
    'pincode': pincode,
  };

  factory WorkerAddress.fromMap(Map<String, dynamic> map) {
    final geoPoint = map['location'] as GeoPoint?;
    return WorkerAddress(
      location: geoPoint,
      city: map['city'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
      // Read stored geohash from Firestore if present.
      // Falls back to computing it on the fly for any existing
      // docs saved before geohash was added.
      geohash: map['geohash'] as String? ?? _computeGeohash(geoPoint),
    );
  }
}

// ── WorkerJobs ─────────────────────────────────────────────────────────────

class WorkerJobs {
  final List<DocumentReference> applied;
  final List<DocumentReference> confirmed;
  final List<DocumentReference> completed;
  final List<DocumentReference> declined;

  WorkerJobs({
    this.applied = const [],
    this.confirmed = const [],
    this.completed = const [],
    this.declined = const [],
  });

  Map<String, dynamic> toMap() => {
    'applied': applied,
    'confirmed': confirmed,
    'completed': completed,
    'declined': declined,
  };

  factory WorkerJobs.fromMap(Map<String, dynamic> map) => WorkerJobs(
    applied: List<DocumentReference>.from(map['applied'] as List? ?? []),
    confirmed: List<DocumentReference>.from(map['confirmed'] as List? ?? []),
    completed: List<DocumentReference>.from(map['completed'] as List? ?? []),
    declined: List<DocumentReference>.from(map['declined'] as List? ?? []),
  );
}

// ── WorkerReview ───────────────────────────────────────────────────────────

class WorkerReview {
  final double rating;
  final String review;

  WorkerReview({required this.rating, required this.review});

  Map<String, dynamic> toMap() => {'rating': rating, 'review': review};

  factory WorkerReview.fromMap(Map<String, dynamic> map) => WorkerReview(
    rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    review: map['review'] as String? ?? '',
  );
}
