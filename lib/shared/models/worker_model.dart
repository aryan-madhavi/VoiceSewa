import 'package:cloud_firestore/cloud_firestore.dart';

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
      reviews: (map['reviews'] as List?)
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

// ── Address — only location (GeoPoint), city, pincode ─────────────────────

class WorkerAddress {
  final GeoPoint? location;
  final String city;
  final String pincode;

  WorkerAddress({
    this.location,
    required this.city,
    required this.pincode,
  });

  Map<String, dynamic> toMap() => {
        'location': location,
        'city': city,
        'pincode': pincode,
      };

  factory WorkerAddress.fromMap(Map<String, dynamic> map) => WorkerAddress(
        location: map['location'] as GeoPoint?,
        city: map['city'] as String? ?? '',
        pincode: map['pincode'] as String? ?? '',
      );
}

// ── Jobs ───────────────────────────────────────────────────────────────────

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

// ── Review ─────────────────────────────────────────────────────────────────

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