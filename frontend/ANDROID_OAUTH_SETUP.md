# Android Google Sign-In Configuration Guide

## Your Debug SHA-1 Fingerprint

```
2F:72:43:93:75:70:DC:7D:6F:0C:9A:60:F4:68:0E:AC:17:2D:D7:AD
```

## Your Package Name

```
com.example.frontend
```

## Steps to Configure Android OAuth

### Step 1: Go to Google Cloud Console Credentials

1. Open: https://console.cloud.google.com/apis/credentials?project=853726513693
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**

### Step 2: Create Android OAuth Client ID

1. **Application type**: Select **Android**
2. **Name**: Enter `ChatterBox Android`
3. **Package name**: Enter `com.example.frontend`
4. **SHA-1 certificate fingerprint**: Enter `2F:72:43:93:75:70:DC:7D:6F:0C:9A:60:F4:68:0E:AC:17:2D:D7:AD`
5. Click **CREATE**

### Step 3: Note the Client IDs

After creation, you should have:

- ✅ **Web client ID**: `853726513693-0mo5v0s9g2sj15lg9ej65j8qjog2931u.apps.googleusercontent.com` (already have)
- ✅ **Android client ID**: Will be created (format: `xxxxx-xxxxxxx.apps.googleusercontent.com`)

**IMPORTANT**: For Android, you DON'T need to use the Android client ID in your code. Google Sign-In Android SDK automatically uses the package name + SHA-1 to authenticate.

### Step 4: Update Your Code

The `AuthService` needs the **Web client ID** as `serverClientId` for Android:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  clientId: kGoogleWebClientId, // For web/iOS
  serverClientId: kGoogleWebClientId, // For Android - sends to backend
);
```

### Step 5: Wait and Test

1. Wait 2-3 minutes for Google Cloud changes to propagate
2. Restart your Flutter app
3. Try signing in again

## Common Issues

### Error: ApiException 10 (DEVELOPER_ERROR)

**Cause**: SHA-1 fingerprint not registered or incorrect package name
**Solution**: Double-check the SHA-1 and package name in Google Cloud Console

### Error: ApiException 12502 (SIGN_IN_CANCELLED)

**Cause**: User cancelled the sign-in
**Solution**: This is normal user behavior

### Error: ApiException 7 (NETWORK_ERROR)

**Cause**: Network connectivity issue
**Solution**: Check internet connection

## For Production Release

When you're ready to publish:

1. Get your release keystore SHA-1:
   ```cmd
   keytool -list -v -keystore path\to\release.keystore -alias your-key-alias
   ```
2. Add the release SHA-1 to the same Android OAuth client in Google Cloud Console
3. Both debug and release SHA-1 can coexist in the same OAuth client

## URLs for Reference

- Google Cloud Console: https://console.cloud.google.com/apis/credentials?project=853726513693
- People API: https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=853726513693
