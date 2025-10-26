import 'package:flutter/foundation.dart' show kIsWeb;

// IMPORTANT: API Base URL - automatically selects based on platform

// Check if API_BASE_URL is provided via --dart-define (for production builds)
const String _envApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

// Automatically use the correct URL based on platform and environment
final String kApiBaseUrl = _envApiBaseUrl.isNotEmpty
    ? _envApiBaseUrl // Use production URL if provided
    : (kIsWeb
        ? "http://localhost:8080" // Web/Desktop development
        : "http://192.168.1.111:8080"); // Android/iOS physical device

// Alternative configurations for local development:
// For Android Emulator:
// const String kApiBaseUrl = "http://10.0.2.2:8080";

// For iOS Simulator:
// const String kApiBaseUrl = "http://localhost:8080";

// Google Web Client ID - loaded from environment variable at compile time
// This is passed using --dart-define during flutter run/build
// Example: flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-id-here
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '', // Empty string as default - will cause error if not set
);
