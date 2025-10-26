# Platform-Specific Configuration Summary

## What Was Fixed

The app now automatically detects the platform and configures itself accordingly:

### 1. **Auth Service** (`lib/core/services/auth_service.dart`)

- **Web**: Uses `clientId` only (no `serverClientId`)
- **Android/iOS**: Uses both `clientId` and `serverClientId`
- Automatically configured using `kIsWeb` check

### 2. **API Base URL** (`lib/core/constants.dart`)

- **Web**: Uses `http://localhost:8080`
- **Android Physical Device**: Uses `http://192.168.1.111:8080` (your PC's IP)
- Automatically selected using `kIsWeb` check

## Testing on Different Platforms

### Web (Chrome/Edge)

```cmd
flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=853726513693-0mo5v0s9g2sj15lg9ej65j8qjog2931u.apps.googleusercontent.com
```

### Android Device

```cmd
flutter run -d <device-id> --dart-define=GOOGLE_WEB_CLIENT_ID=853726513693-0mo5v0s9g2sj15lg9ej65j8qjog2931u.apps.googleusercontent.com
```

### Android Emulator

If using Android Emulator, temporarily change the API URL in `constants.dart`:

```dart
final String kApiBaseUrl = kIsWeb
    ? "http://localhost:8080"
    : "http://10.0.2.2:8080"; // For emulator
```

## Requirements Checklist

### Google Cloud Console Setup

- ✅ **Web OAuth Client ID**: `853726513693-0mo5v0s9g2sj15lg9ej65j8qjog2931u.apps.googleusercontent.com`

  - Authorized JavaScript origins: `http://localhost`, `http://localhost:8080`, etc.
  - Authorized redirect URIs: Same as origins

- ✅ **Android OAuth Client ID**: Created with

  - Package name: `com.example.frontend`
  - SHA-1: `2F:72:43:93:75:70:DC:7D:6F:0C:9A:60:F4:68:0E:AC:17:2D:D7:AD`

- ✅ **Google People API**: Enabled

### Backend Requirements

- ✅ Spring Boot running on port 8080
- ✅ Endpoint: `/api/v1/auth/google` accepting POST with `{ "idToken": "..." }`
- ✅ Returns: `{ "token": "your-jwt-token" }`

### Network Requirements

- **Web**: Backend must be accessible at `localhost:8080`
- **Android Device**:
  - Phone and PC must be on same WiFi
  - Backend must be accessible at `192.168.1.111:8080`
  - PC firewall must allow connections on port 8080

## Troubleshooting

### Web Issues

- **Error**: "serverClientId is not supported on Web"

  - **Fixed**: Now conditionally excludes `serverClientId` on web

- **Error**: "Connection refused"
  - **Solution**: Make sure Spring Boot is running on port 8080

### Android Issues

- **Error**: "ApiException: 10"

  - **Solution**: Make sure Android OAuth client with SHA-1 is added in Google Cloud Console

- **Error**: "Connection refused"
  - **Solution**: Check that phone and PC are on same WiFi and IP address is correct

## Your IP Address

Current PC IP: `192.168.1.111`

To update if your IP changes:

```cmd
ipconfig | findstr /i "IPv4"
```

Then update in `lib/core/constants.dart`
