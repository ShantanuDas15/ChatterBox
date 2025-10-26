# Fix Applied: User Profile Pictures

## Root Cause Found ✅

The Google profile pictures were not showing because the **Flutter mobile app was not requesting the `profile` scope** during Google Sign-In.

### What Was Missing:

In `auth_service.dart`, the mobile configuration only had:

```dart
scopes: ['email']  // ❌ Missing 'profile' scope
```

It needed:

```dart
scopes: ['email', 'profile']  // ✅ Now includes profile scope
```

## Changes Made

### 1. **Fixed Google Sign-In Scope** ✅

**File**: `frontend/lib/core/services/auth_service.dart`

Changed the mobile GoogleSignIn configuration to request the `profile` scope:

```dart
_googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'], // Now requests profile data including photo
  clientId: kGoogleWebClientId,
  serverClientId: kGoogleWebClientId,
);
```

### 2. **Improved Avatar Widget** ✅

**File**: `frontend/lib/screens/chat/widgets/message_bubble.dart`

- Added proper error handling for network images
- Added loading indicator while image loads
- Improved fallback to initial letter if image fails
- Better visual feedback

### 3. **Added Debug Logging** ✅

Added logging to help troubleshoot:

- `ChatController.java` - logs user data when sending messages
- `AuthController.java` - logs photoUrl when user signs in
- `chat_message.dart` - logs photoUrl when parsing JSON
- `message_bubble.dart` - logs photoUrl when rendering

### 4. **Added Debug API Endpoints** ✅

**File**: `backend/src/main/java/com/chatterbox/controller/AuthController.java`

New endpoints to verify database state:

- `GET /api/v1/auth/debug/users` - List all users
- `GET /api/v1/auth/debug/user/{googleId}` - Get specific user details

## MongoDB and Images: Clarification

**MongoDB stores the URL, NOT the actual image.**

The `photoUrl` field contains a string like:

```
https://lh3.googleusercontent.com/a/ACg8ocL...
```

This is correct and efficient because:

- ✅ Images are already hosted by Google
- ✅ No need to store large binary data
- ✅ Automatic updates when user changes their profile picture
- ✅ Fast loading from Google's CDN

## Testing Steps

### Step 1: Restart Backend

```powershell
cd "c:\Java Projects\ChatterBox\backend"
.\mvnw.cmd clean spring-boot:run
```

### Step 2: Clear App Data & Reinstall

**Important**: You MUST log out and log back in for the new scope to take effect.

**Android**:

```powershell
cd "c:\Java Projects\ChatterBox\frontend"
flutter clean
flutter run

# Then in the app: Log out and log in again
```

**Or manually**: Settings > Apps > ChatterBox > Clear Data

### Step 3: Log In Again

1. Open the app
2. Log out (if logged in)
3. Log in with Google
4. **Grant permissions** when Google asks for profile access

### Step 4: Send a Message

1. Go to any channel
2. Send a message
3. **You should now see your Google profile picture!**

### Step 5: Verify in Backend Logs

Check your backend console for:

```
=== DEBUG: Google Sign In (Mobile) ===
GoogleId: 123456789...
Email: user@example.com
Name: John Doe
PhotoUrl: https://lh3.googleusercontent.com/a/...
======================================
```

The `PhotoUrl` should now have a valid URL!

### Step 6: Verify in Database

```powershell
# Check all users
curl http://localhost:8080/api/v1/auth/debug/users
```

You should see the `photoUrl` field populated.

## Expected Behavior After Fix

### ✅ With Profile Picture (Google Login):

```
┌─────────────────────────────────┐
│ [📷] Hello from Flutter!        │  ← Your Google photo
│      Sent by: John Doe          │
│      3:45 PM                    │
└─────────────────────────────────┘
```

### ✅ Without Profile Picture (STOMP Client):

```
┌─────────────────────────────────┐
│ [W] Hello from Web!             │  ← Initial letter fallback
│     Sent by: WebUser            │
│     3:46 PM                     │
└─────────────────────────────────┘
```

## Troubleshooting

### Problem: Still showing initial letter instead of photo

**Solution 1**: Make sure you logged out and logged back in

- The scope change requires re-authentication
- Old tokens don't have the profile scope

**Solution 2**: Check backend logs for photoUrl

```
PhotoUrl: https://lh3.googleusercontent.com/...  ← Should have URL
PhotoUrl: null  ← Problem: scope not granted
```

**Solution 3**: Verify Google Sign-In scopes were granted

- When you log in, Google should show: "ChatterBox wants to: View your email address, See your personal info"
- If it only shows email, the app isn't requesting profile scope

**Solution 4**: Check Flutter console for image errors

```
Error loading avatar image: ...
```

### Problem: Image loading spinner never stops

**Solution**: Check internet connection and Google URL accessibility

- The URL must be accessible from your device
- Try opening the URL in a browser: `https://lh3.googleusercontent.com/...`

### Problem: Old messages still don't have photos

**Expected**: This is normal!

- Messages sent before this fix won't have photoUrl
- They will show the initial letter (fallback)
- Only NEW messages will have profile pictures

## Remove Debug Logging (Optional)

Once everything works, you can remove the debug prints:

1. Remove `System.out.println` from `ChatController.java`
2. Remove `System.out.println` from `AuthController.java`
3. Remove `print()` from `chat_message.dart`
4. Remove `print()` from `message_bubble.dart`

Or keep them for future debugging!

## Summary

The fix was simple: **Add `'profile'` to the Google Sign-In scopes** for mobile platforms.

This allows the app to request and receive the user's profile picture URL from Google, which is then:

1. ✅ Saved to MongoDB (as a URL string)
2. ✅ Included in chat messages
3. ✅ Displayed in the MessageBubble widget

**The profile pictures should now work perfectly!** 🎉
