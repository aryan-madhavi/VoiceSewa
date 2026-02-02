import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/services/fcm_service.dart';
import 'package:voicesewa_client/shared/models/client_model.dart';
import '../firebase/client_firebase_repository.dart';


/// Authentication service - handles Firebase Auth + Firestore profile management + FCM
/// No SQLite dependencies - everything is Firebase-based
class AuthService {
  final WidgetRef ref;
  final FirebaseAuth _auth;
  final ClientFirebaseRepository _clientRepo;
  final FCMService _fcmService;

  AuthService(
    this.ref, {
    FirebaseAuth? auth,
    ClientFirebaseRepository? clientRepo,
    FCMService? fcmService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _clientRepo = clientRepo ?? ClientFirebaseRepository(),
       _fcmService = fcmService ?? FCMService();

  /// Handle user login with Firebase Auth + FCM initialization
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting login process for: $email');

      // Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ Firebase authentication successful');
      print('   UID: ${userCredential.user?.uid}');

      // Initialize FCM and get/update token for this user
      await _initializeFCMForUser(userCredential.user!.uid);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Login error: $e');
      return 'Unexpected error: ${e.toString()}';
    }
  }

  /// Handle user registration with Firebase Auth
  Future<String?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      print('🔐 Starting registration process for: $email');

      // 1. Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ Firebase registration successful');
      print('   UID: ${userCredential.user?.uid}');

      // 2. Update display name
      await userCredential.user?.updateDisplayName(username.trim());
      print('✅ Display name updated');

      // 3. Initialize FCM (token will be saved when profile is created)
      final hasPermission = await _fcmService.initialize();
      print('🔔 FCM initialized: $hasPermission');

      // Note: Profile creation happens in ProfileSetupScreen
      // FCM token will be saved there

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase registration error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Registration error: $e');
      return 'Unexpected error: ${e.toString()}';
    }
  }

  /// Initialize FCM for logged-in user
  /// Gets FCM token and updates it in Firestore profile
  Future<void> _initializeFCMForUser(String uid) async {
    try {
      print('🔔 Initializing FCM for user: $uid');

      // Initialize FCM and request permissions
      final hasPermission = await _fcmService.initialize();

      if (!hasPermission) {
        print('⚠️ FCM permissions denied - skipping token update');
        return;
      }

      // Get FCM token
      final token = await _fcmService.getToken();

      if (token == null) {
        print('⚠️ Failed to get FCM token');
        return;
      }

      // Check if profile exists
      final profile = await _clientRepo.getProfile(uid);

      if (profile == null) {
        print(
          'ℹ️ No profile yet - FCM token will be saved during profile creation',
        );
        return;
      }

      // Update FCM token in Firestore if it changed
      if (profile.fcmToken != token) {
        await _clientRepo.updateFcmToken(uid, token);
        print('✅ FCM token updated in Firestore');
      } else {
        print('ℹ️ FCM token unchanged');
      }

      // Subscribe to default client topics
      // await _fcmService.subscribeToDefaultClientTopics();

      // Subscribe to location-based topics if user has address
      if (profile.hasAddresses && profile.primaryAddress != null) {
        final address = profile.primaryAddress!;
        // await _fcmService.subscribeToLocationTopics(city: address.city);
      }

      print('✅ FCM setup complete for user');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
      // Don't throw - FCM is not critical for login
    }
  }

  /// Logout user from Firebase
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
      rethrow;
    }
  }

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Get current user's email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Get current user's UID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if current user has a profile in Firestore
  Future<bool> currentUserHasProfile() async {
    try {
      return await _clientRepo.currentUserHasProfile();
    } catch (e) {
      print('❌ Error checking profile: $e');
      return false;
    }
  }

  /// Get current user's profile
  Future<ClientProfile?> getCurrentUserProfile() async {
    try {
      return await _clientRepo.getCurrentUserProfile();
    } catch (e) {
      print('❌ Error fetching profile: $e');
      return null;
    }
  }

  /// Send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ Password reset email sent to: $email');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Password reset error: $e');
      return 'Unexpected error: ${e.toString()}';
    }
  }

  /// Update user password
  Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'No user logged in';
      }

      // Re-authenticate before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      print('✅ Password updated successfully');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ Password update error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Password update error: $e');
      return 'Unexpected error: ${e.toString()}';
    }
  }

  /// Delete user account and profile
  Future<String?> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'No user logged in';
      }

      // Re-authenticate before deleting
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete Firestore profile first
      await _clientRepo.deleteProfile(user.uid);

      // Then delete Firebase Auth account
      await user.delete();

      print('✅ Account deleted successfully');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ Account deletion error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Account deletion error: $e');
      return 'Unexpected error: ${e.toString()}';
    }
  }

  /// Get user-friendly error messages from Firebase Auth exceptions
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      // Login errors
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';

      // Registration errors
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';

      // Common errors
      case 'invalid-email':
        return 'Invalid email address';
      case 'network-request-failed':
        return 'Network error. Please check your connection';

      // Password reset errors
      case 'expired-action-code':
        return 'Reset link has expired';
      case 'invalid-action-code':
        return 'Invalid or already used reset link';

      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }
}
