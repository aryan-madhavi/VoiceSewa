import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_worker/core/database/db_login.dart';

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
      // Try Firebase first
      try {
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Save to local DB as backup
        await _dbLogin.setLoggedInUser(
          username: username,
          password: password, // In production, never store plain passwords
        );
        
        return AuthResult(
          success: true,
          message: 'Registration successful',
          user: credential.user,
        );
      } catch (e) {
        // If Firebase fails but we have the credentials, save locally
        await _dbLogin.setLoggedInUser(
          username: username,
          password: password,
        );
        
        return AuthResult(
          success: true,
          message: 'Registered locally. Will sync with server when online.',
          isOffline: true,
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Login with Firebase and local DB
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Try Firebase first
      try {
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Update local DB
        await _dbLogin.setLoggedInUser(
          username: email,
          password: password,
        );
        
        return AuthResult(
          success: true,
          message: 'Login successful',
          user: credential.user,
        );
      } catch (e) {
        // If Firebase fails, try local DB
        final localUser = await _dbLogin.getLoggedInUser();
        
        if (localUser != null && 
            localUser['username'] == email && 
            localUser['password'] == password) {
          
          return AuthResult(
            success: true,
            message: 'Logged in offline',
            isOffline: true,
          );
        }
        
        throw Exception('Invalid credentials');
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    
    final user = await _dbLogin.getLoggedInUser();
    if (user != null) {
      await _dbLogin.logoutUser(user['username']);
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final bool isOffline;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.isOffline = false,
  });
}