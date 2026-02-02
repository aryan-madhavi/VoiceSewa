import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';

class WorkerModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String profileImg;
  final double avgRating;
  final List<Review> reviews;
  final List<String> skillsList; // Renamed from 'skills' to avoid conflict
  final WorkerAddress address;
  final WorkerJobs jobs;
  final String fcmToken;

  // Additional fields for UI (derived from service/availability)
  final Services service;
  final bool? available;
  final String? voiceText;

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

  // Computed properties for UI compatibility
  double get rating => avgRating;
  String get photoUrl => profileImg;
  List<String>? get skills => skillsList; // Getter for backward compatibility
  bool get verified => reviews.length >= 5 && avgRating >= 4.5;

  // Service-related properties using ServicesData
  Color get serviceColor => ServicesData.services[service]![0] as Color;
  IconData get serviceIcon => ServicesData.services[service]![1] as IconData;
  String get serviceLabel => ServicesData.services[service]![2] as String;

  // Calculate distance from user location (you'll implement this with actual coordinates)
  String get distance {
    // TODO: Calculate actual distance using user's location and worker's address.location
    return '${(address.location.latitude * 10 % 5).toStringAsFixed(1)} km';
  }

  // Calculate price range based on service type
  String get priceRange {
    switch (service) {
      case Services.houseCleaner:
        return '₹400 - ₹700';
      case Services.plumber:
        return '₹350 - ₹600';
      case Services.electrician:
        return '₹500 - ₹900';
      case Services.carpenter:
        return '₹450 - ₹800';
      case Services.painter:
        return '₹600 - ₹1000';
      case Services.acApplianceTechnician:
        return '₹500 - ₹1200';
      case Services.mechanic:
        return '₹400 - ₹900';
      case Services.cook:
        return '₹300 - ₹600';
      case Services.driverOnDemand:
        return '₹500 - ₹1000';
      case Services.handymanMasonryWork:
        return '₹400 - ₹800';
      default:
        return '₹300 - ₹800';
    }
  }

  String get experience {
    // Calculate based on reviews or use a default
    if (reviews.length > 20) return '7+';
    if (reviews.length > 10) return '5';
    if (reviews.length > 5) return '3';
    return '2';
  }

  // Factory constructor from Firestore
  factory WorkerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WorkerModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      bio: data['bio'] ?? '',
      profileImg: data['profile_img'] ?? '',
      avgRating: (data['avg_rating'] ?? 0.0).toDouble(),
      reviews:
          (data['reviews'] as List<dynamic>?)
              ?.map((r) => Review.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      skillsList: List<String>.from(data['skills'] ?? []),
      address: WorkerAddress.fromMap(data['address'] as Map<String, dynamic>),
      jobs: WorkerJobs.fromMap(data['jobs'] as Map<String, dynamic>),
      fcmToken: data['fcm_token'] ?? '',
      service: _getServiceFromSkills(List<String>.from(data['skills'] ?? [])),
      available: _checkAvailability(data['jobs']),
      voiceText: data['bio'] ?? '',
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
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
  }

  // Helper to determine service type from skills
  static Services _getServiceFromSkills(List<String> skills) {
    final skillsLower = skills.map((s) => s.toLowerCase()).toList();

    if (skillsLower.any((s) => s.contains('clean'))) {
      return Services.houseCleaner;
    } else if (skillsLower.any((s) => s.contains('plumb'))) {
      return Services.plumber;
    } else if (skillsLower.any((s) => s.contains('electric'))) {
      return Services.electrician;
    } else if (skillsLower.any((s) => s.contains('carpen'))) {
      return Services.carpenter;
    } else if (skillsLower.any((s) => s.contains('paint'))) {
      return Services.painter;
    } else if (skillsLower.any(
      (s) => s.contains('ac') || s.contains('appliance'),
    )) {
      return Services.acApplianceTechnician;
    } else if (skillsLower.any(
      (s) => s.contains('mechanic') || s.contains('2w') || s.contains('4w'),
    )) {
      return Services.mechanic;
    } else if (skillsLower.any(
      (s) => s.contains('cook') || s.contains('chef'),
    )) {
      return Services.cook;
    } else if (skillsLower.any((s) => s.contains('driv'))) {
      return Services.driverOnDemand;
    } else if (skillsLower.any(
      (s) => s.contains('mason') || s.contains('handyman'),
    )) {
      return Services.handymanMasonryWork;
    }
    return Services.houseCleaner; // default
  }

  // Helper to check availability
  static bool _checkAvailability(Map<String, dynamic>? jobsData) {
    if (jobsData == null) return true;
    final confirmed = jobsData['confirmed'] as List<dynamic>? ?? [];
    // If worker has less than 3 confirmed jobs, they're available
    return confirmed.length < 3;
  }
}

class Review {
  final double rating;
  final String review;

  Review({required this.rating, required this.review});

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      rating: (map['rating'] ?? 0.0).toDouble(),
      review: map['review'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'rating': rating, 'review': review};
  }
}

class WorkerAddress {
  final GeoPoint location;
  final String line1;
  final String line2;
  final String landmark;
  final String pincode;
  final String city;

  WorkerAddress({
    required this.location,
    required this.line1,
    required this.line2,
    required this.landmark,
    required this.pincode,
    required this.city,
  });

  factory WorkerAddress.fromMap(Map<String, dynamic> map) {
    return WorkerAddress(
      location: map['location'] as GeoPoint,
      line1: map['line1'] ?? '',
      line2: map['line2'] ?? '',
      landmark: map['landmark'] ?? '',
      pincode: map['pincode'] ?? '',
      city: map['city'] ?? '',
    );
  }

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

  factory WorkerJobs.fromMap(Map<String, dynamic> map) {
    return WorkerJobs(
      applied: List<DocumentReference>.from(map['applied'] ?? []),
      confirmed: List<DocumentReference>.from(map['confirmed'] ?? []),
      completed: List<DocumentReference>.from(map['completed'] ?? []),
      declined: List<DocumentReference>.from(map['declined'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applied': applied,
      'confirmed': confirmed,
      'completed': completed,
      'declined': declined,
    };
  }
}
