import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/core/database/app_database.dart';

/// Result of profile status check
class ProfileCheckResult {
  final bool isNewUser;
  final bool hasLocalProfile;
  // final bool hasCloudProfile;

  const ProfileCheckResult({
    required this.isNewUser,
    required this.hasLocalProfile,
    // required this.hasCloudProfile,
  });

  @override
  String toString() =>
      'ProfileCheckResult('
      'isNewUser: $isNewUser, '
      'hasLocalProfile: $hasLocalProfile, '
      // 'hasCloudProfile: $hasCloudProfile'
      ')';
}

/// Service for checking user profile status
///
/// Provides methods to:
/// - Detect if user just registered
/// - Check if profile exists in LOCAL database (PRIORITY CHECK)
/// - Check if profile exists in Firestore
/// - Combine all checks for routing decision
class UserProfileChecker {
  // Time window (in seconds) to consider a user as "new"
  static const int _newUserWindowSeconds = 120; // 2 minutes

  /// Check complete profile status for routing decision
  ///
  /// IMPORTANT: Checks local database FIRST before checking Firestore.
  /// If local profile exists, user should go to main app.
  static Future<ProfileCheckResult> checkProfileStatus(User user) async {
    final results = await Future.wait([
      _checkIfUserIsNew(user),
      _checkProfileExistsInLocalDB(user.email!),
      // _checkProfileExistsInFirestore(user.email!),
    ]);

    return ProfileCheckResult(
      isNewUser: results[0] as bool,
      hasLocalProfile: results[1] as bool,
      // hasCloudProfile: results[2] as bool,
    );
  }

  /// Detect if user just registered (within last 2 minutes)
  ///
  /// Uses Firebase Auth metadata to compare creation time
  /// with last sign-in time. If they're very close, user
  /// just completed registration flow.
  static Future<bool> _checkIfUserIsNew(User user) async {
    final creationTime = user.metadata.creationTime;
    final lastSignInTime = user.metadata.lastSignInTime;

    if (creationTime == null || lastSignInTime == null) {
      print('⚠️ Missing user metadata timestamps');
      return false;
    }

    // Calculate time difference in seconds
    final difference = lastSignInTime.difference(creationTime).inSeconds.abs();
    final isNewUser = difference < _newUserWindowSeconds;

    print('🔍 User Timestamps:');
    print('   - Created: $creationTime');
    print('   - Last sign-in: $lastSignInTime');
    print('   - Difference: $difference seconds');
    print('   - Is new user: $isNewUser');

    return isNewUser;
  }

  /// Check if profile exists in LOCAL database
  ///
  /// THIS IS THE KEY FIX: Check local DB first!
  /// If profile was just created, it will be in local DB
  /// even if not yet synced to Firestore.
  static Future<bool> _checkProfileExistsInLocalDB(String userEmail) async {
    try {
      print('🔍 Checking LOCAL database for profile: $userEmail');

      final db = ClientDatabase.instance;
      final profile = await db.clientProfileDao.get(userEmail);

      final exists = profile != null;

      if (exists) {
        print('✅ Profile found in LOCAL database');
        print('   - Name: ${profile!.name}');
        print('   - Phone: ${profile.phone}');
      } else {
        print('⚠️ Profile not found in LOCAL database');
      }

      return exists;
    } catch (e, stackTrace) {
      print('❌ Error checking LOCAL database profile: $e');
      print('Stack trace: $stackTrace');

      // On error, assume profile doesn't exist (safe default)
      return false;
    }
  }

  /// Check if profile exists in Firestore
  ///
  /// Queries the 'client_profiles' collection using user email
  /// as document ID. Returns true if document exists.
  static Future<bool> _checkProfileExistsInFirestore(String userEmail) async {
    try {
      print('🔍 Checking Firestore for profile: $userEmail');

      final doc = await FirebaseFirestore.instance
          .collection('client_profiles')
          .doc(userEmail)
          .get();

      final exists = doc.exists;

      if (exists) {
        print('✅ Profile found in Firestore');
        print('   - Data: ${doc.data()}');
      } else {
        print('⚠️ Profile not found in Firestore');
      }

      return exists;
    } catch (e, stackTrace) {
      print('❌ Error checking Firestore profile: $e');
      print('Stack trace: $stackTrace');

      // On error, assume profile doesn't exist (safe default)
      return false;
    }
  }

  /// Manually check if user is new (useful for testing)
  static Future<bool> isUserNew(User user) async {
    return await _checkIfUserIsNew(user);
  }

  /// Manually check if profile exists in local DB (useful for testing)
  static Future<bool> hasLocalProfile(String userEmail) async {
    return await _checkProfileExistsInLocalDB(userEmail);
  }

  /// Manually check if profile exists in Firestore (useful for testing)
  static Future<bool> hasCloudProfile(String userEmail) async {
    return await _checkProfileExistsInFirestore(userEmail);
  }
}
