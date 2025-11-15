import 'package:flutter/material.dart';
import 'package:voicesewa_client/features/home/data/services_data.dart';

class WorkerModel {
  final String name;
  final double rating;
  final String distance; // e.g. "2.3 km"
  final String priceRange; // e.g. "₹500 - ₹800"
  final bool verified;
  final String photoUrl;
  final String voiceText;
  final Services service; // 👈 Now linked to the service enum

  // Optional fields for richer profiles
  final int? experience; // years of experience
  final List<String>? skills;
  final bool? available; // if worker is currently taking jobs

  WorkerModel({
    required this.name,
    required this.rating,
    required this.distance,
    required this.priceRange,
    required this.verified,
    required this.photoUrl,
    required this.voiceText,
    required this.service,
    this.experience,
    this.skills,
    this.available,
  });

  /// ✅ Service-related data helpers from ServicesData
  Color get serviceColor => ServicesData.services[service]![0] as Color;
  IconData get serviceIcon => ServicesData.services[service]![1] as IconData;
  String get serviceName => ServicesData.services[service]![2] as String;

  /// ✅ Verification badge color
  Color get verifiedColor => verified ? Colors.green : Colors.grey;

  /// ✅ Availability label
  String get availabilityStatus =>
      available == true ? 'Available' : 'Unavailable';

  /// ✅ Factory constructor to create from Map (e.g., Firebase)
  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkerModel(
      name: map['name'] ?? '',
      rating: double.tryParse(map['rating'].toString()) ?? 0.0,
      distance: map['distance'] ?? '',
      priceRange: map['priceRange'] ?? '',
      verified: map['verified'] ?? false,
      photoUrl: map['photoUrl'] ?? '',
      voiceText: map['voiceText'] ?? '',
      service: Services.values.firstWhere(
        (e) => e.toString() == map['service'],
        orElse: () => Services.handymanMasonryWork,
      ),
      experience: map['experience'],
      skills: map['skills'] != null
          ? List<String>.from(map['skills'])
          : null,
      available: map['available'],
    );
  }

  /// ✅ Convert to Map for Firebase/local DB
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rating': rating.toStringAsFixed(1),
      'distance': distance,
      'priceRange': priceRange,
      'verified': verified,
      'photoUrl': photoUrl,
      'voiceText': voiceText,
      'service': service.toString(),
      if (experience != null) 'experience': experience,
      if (skills != null) 'skills': skills,
      if (available != null) 'available': available,
    };
  }

  /// ✅ Clone with updated fields
  WorkerModel copyWith({
    String? name,
    double? rating,
    String? distance,
    String? priceRange,
    bool? verified,
    String? photoUrl,
    String? voiceText,
    Services? service,
    int? experience,
    List<String>? skills,
    bool? available,
  }) {
    return WorkerModel(
      name: name ?? this.name,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      priceRange: priceRange ?? this.priceRange,
      verified: verified ?? this.verified,
      photoUrl: photoUrl ?? this.photoUrl,
      voiceText: voiceText ?? this.voiceText,
      service: service ?? this.service,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      available: available ?? this.available,
    );
  }
}
