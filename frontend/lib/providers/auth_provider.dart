import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/storage_service.dart';
import 'package:frontend/providers/auth_state.dart';
import 'package:frontend/core/services/auth_service.dart'; // <-- IMPORT THIS
import 'package:frontend/core/services/api_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:http/http.dart' as http;

// 1. Create a provider for our StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// 2. Create a provider for our AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 3. Update the AuthProvider
final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  // <-- 'ref' is added
  final storageService = ref.watch(storageServiceProvider);
  final authService = ref.watch(authServiceProvider); // <-- GET THE SERVICE
  return AuthProvider(ref, storageService, authService); // <-- Pass 'ref'
});

// 4. Provider for the ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  // Watch the auth state
  final authState = ref.watch(authProvider);

  // If we are authenticated, create an ApiService with the token.
  // Otherwise, create one with an empty token.
  if (authState.status == AuthStatus.authenticated && authState.token != null) {
    return ApiService(authState.token!);
  }
  // This will throw an error if we try to use it while not logged in,
  // which is what we want.
  return ApiService('');
});

class AuthProvider extends StateNotifier<AuthState> {
  final Ref _ref; // <-- ADD THIS
  final StorageService _storageService;
  final AuthService _authService; // <-- ADD THIS

  // Update the constructor
  AuthProvider(this._ref, this._storageService, this._authService)
    : super(AuthState()) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await _storageService.readToken();
    if (token != null) {
      // 1. Populate all providers FIRST
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      _ref.read(userNameProvider.notifier).state = decodedToken['name'];
      _ref.read(userIdProvider.notifier).state = decodedToken['sub'];
      _ref.read(userEmailProvider.notifier).state = decodedToken['email'];

      // Try to read cached photo URL first to avoid hitting Google's servers
      final cachedPhotoUrl = await _storageService.readPhotoUrl();
      if (cachedPhotoUrl != null) {
        _ref.read(userPhotoUrlProvider.notifier).state = cachedPhotoUrl;
      } else {
        // Fallback to JWT if no cached version
        _ref.read(userPhotoUrlProvider.notifier).state =
            decodedToken['picture'];
      }

      // Load cached photo data (base64)
      final cachedPhotoData = await _storageService.readPhotoData();
      _ref.read(userPhotoDataProvider.notifier).state = cachedPhotoData;

      // 2. Set state to authenticated LAST
      state = AuthState(status: AuthStatus.authenticated, token: token);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }
  // --- UPDATE THE login/logout METHODS ---

  /// Downloads the profile photo and caches it as base64
  Future<void> _cacheProfilePhoto(String photoUrl) async {
    try {
      // Optimize URL for smaller size (96x96 should be enough)
      final optimizedUrl = photoUrl.contains('googleusercontent.com')
          ? '${photoUrl.split('=')[0]}=s96-c'
          : photoUrl;

      final response = await http.get(Uri.parse(optimizedUrl));
      if (response.statusCode == 200) {
        // Convert to base64 and store
        final base64Image = base64Encode(response.bodyBytes);
        await _storageService.writePhotoData(base64Image);
        print('✅ Profile photo cached successfully');
      } else {
        print('⚠️ Failed to download profile photo: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error caching profile photo: $e');
      // Don't fail the login if photo caching fails
    }
  }

  Future<void> logIn() async {
    print('🔄 AuthProvider: logIn() called');

    // 1. Call the AuthService to sign in
    final token = await _authService.signInWithGoogle();

    if (token != null) {
      print('✅ AuthProvider: Token received, saving and updating state');
      // 2. If successful, save the token and update state
      await _storageService.writeToken(token);

      // 3. Populate all providers FIRST
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      _ref.read(userNameProvider.notifier).state = decodedToken['name'];
      _ref.read(userIdProvider.notifier).state = decodedToken['sub'];
      _ref.read(userEmailProvider.notifier).state = decodedToken['email'];

      // Cache the photo URL to avoid hitting Google's rate limits
      final photoUrl = decodedToken['picture'];
      if (photoUrl != null) {
        await _storageService.writePhotoUrl(photoUrl);
        // Download and cache the actual image data in the background
        _cacheProfilePhoto(photoUrl); // Fire and forget
      }
      _ref.read(userPhotoUrlProvider.notifier).state = photoUrl;

      // 4. Set state to authenticated LAST
      state = AuthState(status: AuthStatus.authenticated, token: token);

      print('✅ AuthProvider: State updated to authenticated');
    } else {
      print('❌ AuthProvider: No token received, staying unauthenticated');
      // 3. If failed (e.g., user canceled), set to unauthenticated
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logOut() async {
    await _authService.signOut(); // <-- Sign out from Google
    await _storageService.deleteToken(); // <-- Delete our token
    await _storageService.deletePhotoUrl(); // <-- Delete cached photo URL
    await _storageService.deletePhotoData(); // <-- Delete cached photo data

    // Clear the user's name and ID on logout
    _ref.read(userNameProvider.notifier).state = null;
    _ref.read(userIdProvider.notifier).state = null;
    _ref.read(userEmailProvider.notifier).state = null;
    _ref.read(userPhotoUrlProvider.notifier).state = null;
    _ref.read(userPhotoDataProvider.notifier).state = null;

    state = AuthState(status: AuthStatus.unauthenticated);
  }
}
