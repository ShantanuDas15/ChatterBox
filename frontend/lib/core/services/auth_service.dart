import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:frontend/core/constants.dart'; // Import your constants

class AuthService {
  // Configure GoogleSignIn for both web and mobile platforms
  // Web doesn't support serverClientId, so we configure conditionally
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    if (kIsWeb) {
      // Web configuration - no serverClientId
      // Request 'openid' scope to get ID token on web
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'openid', 'profile'],
        clientId: kGoogleWebClientId,
      );
    } else {
      // Mobile (Android/iOS) configuration - with serverClientId
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ], // <-- ADDED 'profile' scope for photo access
        clientId: kGoogleWebClientId,
        serverClientId: kGoogleWebClientId, // For Android to get ID token
      );
    }
  }

  // This method handles the entire login flow
  Future<String?> signInWithGoogle() async {
    // Validate that the Google Client ID is configured
    if (kGoogleWebClientId.isEmpty) {
      print(
        'ERROR: Google Web Client ID not configured. '
        'Please run with: flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-id-here',
      );
      return null;
    }
    try {
      print('🔐 Starting Google Sign-In...');

      // 1. Trigger the native Google Sign-In popup
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        print('❌ User canceled sign-in');
        return null;
      }

      print('✅ Google user signed in: ${googleUser.email}');

      // 2. Get the Google ID Token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      print('🔑 ID Token: ${idToken != null ? "Received" : "NULL"}');
      print(
        '🔑 Access Token: ${googleAuth.accessToken != null ? "Received" : "NULL"}',
      );

      // Handle web-specific case where ID token might be null
      String? tokenToSend = idToken;

      if (idToken == null && kIsWeb && googleAuth.accessToken != null) {
        print('⚠️  Web platform: ID token is null, using access token instead');
        // On web, we might need to use access token
        tokenToSend = googleAuth.accessToken;
      }

      if (tokenToSend == null) {
        // Failed to get any token
        print('❌ Failed to get any token from Google');
        return null;
      }

      // 3. Send the Google token to your Spring Boot backend
      print('📤 Sending token to backend: $kApiBaseUrl/api/v1/auth/google');

      final response = await http.post(
        Uri.parse('$kApiBaseUrl/api/v1/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': tokenToSend,
          'isAccessToken':
              idToken == null, // Flag to indicate if it's an access token
        }),
      );
      print('📥 Backend response status: ${response.statusCode}');
      print('📥 Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        // 4. Get your internal JWT from the response
        final String internalToken = jsonDecode(response.body)['token'];
        print('✅ Received internal JWT token');
        return internalToken;
      } else {
        // Backend failed to verify or issue a token
        print('❌ Backend failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Any error during the process
      print("❌ Error during Google sign-in: $e");
      return null;
    }
  }

  // Method to sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
