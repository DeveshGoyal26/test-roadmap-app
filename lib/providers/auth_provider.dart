import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

// Add a class to represent user data
class UserInfo {
  final String? id;
  final String? name;
  final String? username;
  final String? email;
  final String? role;
  final String? personaType;
  final String? authProvider;
  final String? status;
  final String? subscriptionStatus;
  final int? dailyChatLimit;
  final int? remainingChats;
  final List<String> badges;
  final bool shareIncomePublicly;
  final String? profileVisibility;
  final int followerCount;
  final int followingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? userLoggedOutAt;
  final bool hasSeenOnboarding;
  final String? avatarUrl;
  final String? profileImage;
  final String? referralCode;
  final int referralCount;
  final double referralRewards;
  UserInfo({
    this.id,
    this.name,
    this.username,
    this.email,
    this.role,
    this.personaType,
    this.authProvider,
    this.status,
    this.subscriptionStatus,
    this.dailyChatLimit,
    this.remainingChats,
    this.badges = const [],
    this.shareIncomePublicly = false,
    this.profileVisibility,
    this.followerCount = 0,
    this.followingCount = 0,
    this.createdAt,
    this.updatedAt,
    this.userLoggedOutAt,
    this.hasSeenOnboarding = false,
    this.avatarUrl,
    this.profileImage,
    this.referralCode,
    this.referralCount = 0,
    this.referralRewards = 0.0,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      username: json['username'],
      personaType: json['personaType'],
      authProvider: json['authProvider'],
      status: json['status'],
      subscriptionStatus: json['subscriptionStatus'],
      dailyChatLimit: json['dailyChatLimit'],
      remainingChats: json['remainingChats'],
      badges: List<String>.from(json['badges'] ?? []),
      shareIncomePublicly: json['shareIncomePublicly'] ?? false,
      profileVisibility: json['profileVisibility'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      userLoggedOutAt:
          json['userLoggedOutAt'] != null
              ? DateTime.parse(json['userLoggedOutAt'])
              : null,
      avatarUrl: json['avatarUrl'],
      profileImage: json['profileImage'],
      referralCode: json['referralCode'],
      referralCount: json['referralCount'] ?? 0,
      referralRewards: (json['referralRewards'] ?? 0).toDouble(),
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final logger = Logger();
  // FirebaseAuth instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _isAuthenticating = false;
  UserInfo? _userInfo; // Add user info variable
  String? _token;
  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAuthenticating => _isAuthenticating;
  UserInfo? get userInfo => _userInfo; // Add getter for user info
  // First check if we have a token
  String? get token => _token;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(
        '📱 Initializing Auth - Token from SharedPreferences: ${token != null ? 'exists' : 'not found'}',
      );
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');

      if (_token != null && _token != '') {
        try {
          // Validate token by calling getUser API
          final response = await _apiService.getUser(token: _token as String);
          if (response.data['success']) {
            _userInfo = UserInfo.fromJson(response.data['user']);
          }
          _isAuthenticated = true;
          debugPrint('✅ Token validated successfully');
        } catch (e) {
          debugPrint('❌ Token validation failed: $e');
          _isAuthenticated = false;
          await prefs.remove('auth_token');
        }
      } else {
        debugPrint('⚠️ No token found in SharedPreferences');
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('❌ Error in _initializeAuth: $e');
      _isAuthenticated = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> getUser() async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.getUser(token: _token ?? '');
    _isAuthenticated = response.data['success'];

    // Update user info when we get user data
    if (response.data['success'] && response.data['user'] != null) {
      _userInfo = UserInfo.fromJson(response.data['user']);
    }

    _isLoading = false;
    notifyListeners();
    return response.data['success'];
  }

  Future<bool> refetchUser() async {
    final response = await _apiService.getUser(token: _token ?? '');
    logger.d('refetchUser response: $response');
    if (response.data['success'] && response.data['user'] != null) {
      _userInfo = UserInfo.fromJson(response.data['user']);
    }
    return response.data['success'];
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    final response = await _apiService.updateUser(_token ?? '', data);
    logger.d('updateUser response: $response');
  }

  Future<String> register(
    String token,
    UserCredential userCredential,
    String referralCode,
  ) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.register(
      token,
      userCredential,
      referralCode,
    );
    logger.d('register response: $response');

    _isLoading = false;
    notifyListeners();
    setToken(response.data['token']);
    await getUser();
    return response.data['token'];
  }

  void logout() {
    _isAuthenticated = false;
    _firebaseAuth.signOut();
    _apiService.logout();
    GoogleSignIn().signOut();
    // _userInfo = null; // Clear user info on logout
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token; // Set token in memory first
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token); // Wait for token to be saved
    notifyListeners();
  }

  String getReferralUrl() {
    // Replace with your actual app URL scheme
    return 'https://yourapp.com/register?ref=${userInfo?.referralCode}';
  }

  User? getCurrentUser() {
    logger.d(_firebaseAuth.currentUser);
    return FirebaseAuth.instance.currentUser;
  }

  // Sign in with Google
  Future<bool> signInWithEmail(String email) async {
    try {
      print('Sending sign in link to email: $email');
      await _firebaseAuth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          // Replace with your actual Firebase Dynamic Links domain
          url: 'https://yourapp.page.link/email-signin',
          handleCodeInApp: true,
          androidPackageName: 'com.skillpe.app',
          androidMinimumVersion: "1",
          androidInstallApp: true,
          iOSBundleId: 'com.skillpe.app',
        ),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      throw Exception(e);
    }
  }

  // Sign up with email
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Update the signInWithGoogle method
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _isAuthenticating = true;
      notifyListeners();

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope(
          'https://www.googleapis.com/auth/userinfo.email',
        );
        googleProvider.addScope(
          'https://www.googleapis.com/auth/userinfo.profile',
        );

        final UserCredential userCredential = await _firebaseAuth
            .signInWithPopup(googleProvider);
        if (userCredential.credential?.accessToken != null) {
          // Get new token from registration
          final token = await register(
            userCredential.credential!.accessToken!,
            userCredential,
            '',
          );

          // Important: Update token before any other API calls
          await setToken(token);

          // Add a small delay to ensure token is properly saved
          await Future.delayed(const Duration(milliseconds: 100));

          _isAuthenticated = true;
          notifyListeners();

          // Now get user info with new token
          await getUser();
          return userCredential;
        }
        return null;
      } else {
        final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
        if (gUser == null) {
          _isAuthenticating = false;
          notifyListeners();
          return null;
        }

        final GoogleSignInAuthentication gAuth = await gUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(
          credential,
        );

        // Get new token from registration
        final token = await register(
          gAuth.accessToken ?? '',
          userCredential,
          '',
        );

        // Important: Update token and wait for it to be saved
        await setToken(token);

        // Add a small delay to ensure token is properly saved
        await Future.delayed(const Duration(milliseconds: 100));

        _isAuthenticated = true;

        // Now get user info with new token
        await getUser();

        notifyListeners();
        return userCredential;
      }
    } catch (e) {
      logger.e('Error signing in with Google: $e');
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
    return null;
  }

  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'Exception: user-not-found':
        return 'No user found for this email. Please sign up.';
      case 'Exception: invalid-email':
        return 'Invalid email address. Please enter a valid email.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
