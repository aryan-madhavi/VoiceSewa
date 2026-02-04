import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_worker/features/auth/data/database/db_login.dart';
import 'package:voicesewa_worker/features/auth/model/AuthResult.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final DbLogin _dbLogin = DbLogin();

  // Check if user is logged in (Firebase or Local)
  Future<bool> isUserLoggedIn() async {
    // First check Firebase
    if (_firebaseAuth.currentUser != null) {
      return true;
    }
    
    // Then check local DB and session validity
    return await _dbLogin.isSessionValid();
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    // Try Firebase first
    if (_firebaseAuth.currentUser != null) {
      return {
        'email': _firebaseAuth.currentUser!.email,
        'uid': _firebaseAuth.currentUser!.uid,
        'source': 'firebase'
      };
    }
    
    // Fallback to local DB
    final localUser = await _dbLogin.getLoggedInUser();
    if (localUser != null) {
      return {
        'username': localUser['username'],
        'source': 'local'
      };
    }
    
    return null;
  }

  // Register with Firebase and save to local DB
  Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      // Try Firebase registration
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // ONLY save to local DB after Firebase confirms success
      await _dbLogin.setLoggedInUser(
        username: email, // Use email as username for consistency
        password: password, // In production, never store plain passwords
      );
      
      return AuthResult(
        success: true,
        message: 'Registration successful',
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'network-request-failed':
          // If it's a network issue and we want to allow offline registration
          // Save locally as fallback
          await _dbLogin.setLoggedInUser(
            username: email,
            password: password,
          );
          return AuthResult(
            success: true,
            message: 'Registered locally. Will sync when online.',
            isOffline: true,
          );
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      
      return AuthResult(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Login with Firebase and local DB
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Try Firebase login first
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // ONLY save to local DB after Firebase confirms success
      await _dbLogin.setLoggedInUser(
        username: email,
        password: password,
      );
      
      return AuthResult(
        success: true,
        message: 'Login successful',
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      // If Firebase fails, try local DB as fallback
      if (e.code == 'network-request-failed') {
        // Network issue - try offline login
        final localUser = await _dbLogin.getLoggedInUser();
        
        if (localUser != null && 
            localUser['username'] == email && 
            localUser['password'] == password &&
            await _dbLogin.isSessionValid()) {
          
          return AuthResult(
            success: true,
            message: 'Logged in offline',
            isOffline: true,
          );
        }
      }
      
      // Handle specific Firebase errors
      String errorMessage = 'Login failed';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }
      
      return AuthResult(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    // Sign out from Firebase
    await _firebaseAuth.signOut();
    
    // Logout from local DB
    final user = await _dbLogin.getLoggedInUser();
    if (user != null) {
      await _dbLogin.logoutUser(user['username']);
    }
  }
}

