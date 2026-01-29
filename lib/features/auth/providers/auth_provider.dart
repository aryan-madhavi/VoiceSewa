import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/shared/models/client_model.dart';
import '../data/firebase/client_firebase_repository.dart';

// ==================== FIREBASE PROVIDERS ====================

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Client Firebase Repository provider
final clientFirebaseRepositoryProvider = Provider<ClientFirebaseRepository>((ref) {
  return ClientFirebaseRepository();
});

// ==================== AUTH STATE PROVIDERS ====================

/// Stream of Firebase Auth state changes
final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Current Firebase user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value;
});

/// Check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Get current user's UID
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

/// Get current user's email
final currentUserEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

// ==================== PROFILE PROVIDERS ====================

/// Check if current user has a profile in Firestore
final userHasProfileProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(clientFirebaseRepositoryProvider);
  return await repo.currentUserHasProfile();
});

/// Get current user's profile
final currentClientProfileProvider = StreamProvider.autoDispose<ClientProfile?>((ref) {
  final repo = ref.watch(clientFirebaseRepositoryProvider);
  return repo.watchCurrentUserProfile();
});

/// Get profile by UID
final clientProfileByUidProvider = StreamProvider.autoDispose.family<ClientProfile?, String>(
  (ref, uid) {
    final repo = ref.watch(clientFirebaseRepositoryProvider);
    return repo.watchProfile(uid);
  },
);

/// Check if current user's profile is complete
final isProfileCompleteProvider = Provider.autoDispose<bool>((ref) {
  final profileAsync = ref.watch(currentClientProfileProvider);
  
  return profileAsync.when(
    data: (profile) => profile?.isComplete ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

// ==================== UI STATE PROVIDERS ====================

/// Toggle between login and register mode (true = login, false = register)
final authModeProvider = StateProvider<bool>((ref) => true);

/// Loading state for auth operations
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Password visibility toggles
final loginPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final registerPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final confirmPasswordVisibleProvider = StateProvider<bool>((ref) => false);

// ==================== SESSION STATUS ENUM ====================

/// Session status based on Firebase Auth state
enum SessionStatus {
  loading,    // Checking auth state
  loggedIn,   // User authenticated
  loggedOut,  // No authenticated user
}

/// Session status provider based on Firebase Auth
final sessionStatusProvider = Provider<SessionStatus>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  return authState.when(
    data: (user) => user != null ? SessionStatus.loggedIn : SessionStatus.loggedOut,
    loading: () => SessionStatus.loading,
    error: (_, __) => SessionStatus.loggedOut,
  );
});