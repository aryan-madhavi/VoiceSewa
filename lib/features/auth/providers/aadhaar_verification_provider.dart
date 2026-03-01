import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class AadhaarData {
  final bool success;
  final String? name;
  final String? gender;
  final String? dob;
  final String? yearOfBirth;
  final String? address;
  final String? state;
  final String? district;
  final String? pincode;
  final String? uidLast4;
  final String? photoBase64;
  final bool isSecureQr;
  final String? error;

  const AadhaarData({
    required this.success,
    this.name,
    this.gender,
    this.dob,
    this.yearOfBirth,
    this.address,
    this.state,
    this.district,
    this.pincode,
    this.uidLast4,
    this.photoBase64,
    this.isSecureQr = false,
    this.error,
  });

  factory AadhaarData.fromJson(Map<String, dynamic> json) => AadhaarData(
    success: json['success'] as bool,
    name: json['name'] as String?,
    gender: json['gender'] as String?,
    dob: json['dob'] as String?,
    yearOfBirth: json['year_of_birth'] as String?,
    address: json['address'] as String?,
    state: json['state'] as String?,
    district: json['district'] as String?,
    pincode: json['pincode'] as String?,
    uidLast4: json['uid_last4'] as String?,
    photoBase64: json['photo_base64'] as String?,
    isSecureQr: json['is_secure_qr'] as bool? ?? false,
    error: json['error'] as String?,
  );

  /// Firestore-safe map — never stores full UID
  Map<String, dynamic> toFirestoreMap() => {
    'aadhaarVerified': true,
    'is_worker_verified': true,
    'aadhaarUidLast4': uidLast4,
    'aadhaarName': name,
    'aadhaarGender': gender,
    'aadhaarDob': dob,
    'aadhaarState': state,
    'aadhaarDistrict': district,
    'aadhaarPincode': pincode,
    'aadhaarVerifiedAt': DateTime.now().toIso8601String(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

enum AadhaarVerificationStatus { idle, scanning, loading, verified, failed }

class AadhaarVerificationState {
  final AadhaarVerificationStatus status;
  final AadhaarData? data;
  final String? errorMessage;

  const AadhaarVerificationState({
    this.status = AadhaarVerificationStatus.idle,
    this.data,
    this.errorMessage,
  });

  bool get isVerified => status == AadhaarVerificationStatus.verified;
  bool get isLoading => status == AadhaarVerificationStatus.loading;

  AadhaarVerificationState copyWith({
    AadhaarVerificationStatus? status,
    AadhaarData? data,
    String? errorMessage,
  }) => AadhaarVerificationState(
    status: status ?? this.status,
    data: data ?? this.data,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

/// 🔧 Change this to your deployed backend URL
const _kAadhaarBackendUrl = 'https://voicesewa-1.onrender.com/decode-aadhaar';

class AadhaarVerificationNotifier
    extends StateNotifier<AadhaarVerificationState> {
  AadhaarVerificationNotifier() : super(const AadhaarVerificationState());

  /// Called after QR scanner returns raw QR string.
  /// Sends it to Python backend → pyaadhaar decodes → returns demographic data.
  Future<void> decodeQr(String rawQrData) async {
    state = state.copyWith(status: AadhaarVerificationStatus.loading);

    try {
      final response = await http
          .post(
            Uri.parse(_kAadhaarBackendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'qr_data': rawQrData}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        state = state.copyWith(
          status: AadhaarVerificationStatus.failed,
          errorMessage: 'Server error (${response.statusCode}). Try again.',
        );
        return;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = AadhaarData.fromJson(json);

      if (data.success) {
        state = state.copyWith(
          status: AadhaarVerificationStatus.verified,
          data: data,
        );
      } else {
        state = state.copyWith(
          status: AadhaarVerificationStatus.failed,
          errorMessage: data.error ?? 'Could not read Aadhaar QR. Try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AadhaarVerificationStatus.failed,
        errorMessage: 'Network error. Please check your connection.',
      );
    }
  }

  void reset() => state = const AadhaarVerificationState();
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final aadhaarVerificationProvider =
    StateNotifierProvider<
      AadhaarVerificationNotifier,
      AadhaarVerificationState
    >((ref) => AadhaarVerificationNotifier());
