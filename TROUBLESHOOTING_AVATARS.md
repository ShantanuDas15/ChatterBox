# Troubleshooting User Avatars

## Issue

Google profile pictures are not displaying in the chat. The fallback initial letter (e.g., "W") shows correctly, but the actual profile photo doesn't load.

## MongoDB Can Store Image URLs (Not Images)

**Important**: MongoDB stores the **URL** to the profile picture, NOT the actual image file. The `photoUrl` field contains a string URL like `https://lh3.googleusercontent.com/a/...` which points to Google's servers where the actual image is hosted.

This is the correct approach because:

1. Profile images are already hosted by Google
2. Storing URLs is efficient and saves database space
3. Images update automatically if the user changes their Google profile picture

## Verification Steps

### Step 1: Restart Backend Server

**CRITICAL**: You must restart the Spring Boot backend after adding the `photoUrl` field to User.java for the changes to take effect.

```powershell
cd "c:\Java Projects\ChatterBox\backend"
.\mvnw.cmd spring-boot:run
```

### Step 2: Check Backend Logs

When you log in, check the backend console for debug output:

```
=== DEBUG: Google Sign In (Mobile) ===
GoogleId: 123456789...
Email: user@example.com
Name: John Doe
PhotoUrl: https://lh3.googleusercontent.com/a/...
======================================
```

**What to look for**:

- Is `PhotoUrl` printed?
- Is it `null` or does it have a URL?
- If it's `null`, the problem is with Google Sign-In configuration

### Step 3: Verify Database Storage

After logging in, check if the photoUrl was saved to MongoDB:

**Option A: Using the Debug API**

```powershell
# List all users
curl http://localhost:8080/api/v1/auth/debug/users

# Check specific user (replace with your Google ID)
curl http://localhost:8080/api/v1/auth/debug/user/YOUR_GOOGLE_ID
```

**Option B: Using MongoDB Compass or Shell**

```javascript
// Connect to your MongoDB and run:
use chatterbox
db.users.find().pretty()
```

Look for the `photoUrl` field in the user document. It should contain a URL like:

```json
{
  "_id": "...",
  "username": "John Doe",
  "email": "user@example.com",
  "googleId": "123456789...",
  "photoUrl": "https://lh3.googleusercontent.com/a/..."
}
```

### Step 4: Check Message Sending

When you send a message, check the backend logs:

```
=== DEBUG: Sending message ===
GoogleId: 123456789...
Sender Username: John Doe
Sender PhotoUrl: https://lh3.googleusercontent.com/a/...
==============================
```

### Step 5: Check Frontend Reception

In your Flutter app debug console, look for:

```
=== DEBUG: ChatMessage.fromJson ===
senderName: John Doe
senderPhotoUrl: https://lh3.googleusercontent.com/a/...
===================================

=== DEBUG: MessageBubble ===
senderName: John Doe
senderPhotoUrl: https://lh3.googleusercontent.com/a/...
============================
```

## Common Issues & Solutions

### Issue 1: PhotoUrl is null in AuthController

**Cause**: Google Sign-In might not be requesting the profile scope.

**Solution**: Check your Google Sign-In configuration:

**For Android** (`android/app/src/main/AndroidManifest.xml`):
Make sure you're requesting the profile scope.

**For iOS** (`ios/Runner/Info.plist`):
Check OAuth configuration.

**For Flutter** - In your login code, ensure you're requesting the profile scope:

```dart
// In your Google Sign-In code
final GoogleSignInAccount? googleUser = await GoogleSignIn(
  scopes: ['email', 'profile'], // <-- Make sure profile is included
).signIn();
```

### Issue 2: PhotoUrl is empty string in database

**Cause**: Google returned an empty string instead of null.

**Solution**: Already handled in the code - we check for both `null` and empty strings:

```dart
message.senderPhotoUrl != null && message.senderPhotoUrl!.isNotEmpty
```

### Issue 3: Old messages don't have photoUrl

**Cause**: Messages sent before implementing this feature won't have photoUrl.

**Solution**:

1. Delete old messages from the database, OR
2. Update the MessageBubble to handle null gracefully (already done - shows initial)

### Issue 4: Network image not loading

**Cause**: Flutter might have issues loading the image from Google's servers.

**Solution**: Add error handling to the avatar:

```dart
CircleAvatar(
  radius: 18,
  backgroundImage: message.senderPhotoUrl != null && message.senderPhotoUrl!.isNotEmpty
      ? NetworkImage(message.senderPhotoUrl!)
      : null,
  onBackgroundImageError: (exception, stackTrace) {
    print('Error loading image: $exception');
  },
  child: message.senderPhotoUrl == null || message.senderPhotoUrl!.isEmpty
      ? Text(message.senderName[0].toUpperCase())
      : null,
)
```

### Issue 5: CORS or network security issues

**Cause**: Flutter might be blocking the image URL.

**For Android**: Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

**For Web**: No action needed, Google URLs work fine.

## Testing Procedure

1. **Clear app data** (to force re-login):

   - Android: Settings > Apps > ChatterBox > Clear Data
   - iOS: Uninstall and reinstall

2. **Log out from the app** (if logout is implemented)

3. **Restart backend server** (to ensure all code changes are loaded)

4. **Log in with Google**

5. **Check backend logs** for the debug output

6. **Send a test message**

7. **Verify the avatar appears**

## Quick Test Commands

```powershell
# Terminal 1: Start backend with logs visible
cd "c:\Java Projects\ChatterBox\backend"
.\mvnw.cmd spring-boot:run

# Terminal 2: Test debug endpoints
curl http://localhost:8080/api/v1/auth/debug/users

# Terminal 3: Start Flutter app
cd "c:\Java Projects\ChatterBox\frontend"
flutter run
```

## Expected Result

After following these steps, you should see:

1. ✅ Google profile picture in CircleAvatar for your own messages (on the right)
2. ✅ Google profile picture in CircleAvatar for other users' messages (on the left)
3. ✅ Fallback to initial letter for STOMP client messages (which have no photoUrl)

## Remove Debug Logging (After Fixing)

Once everything works, remove the debug `System.out.println` and `print()` statements from:

- `ChatController.java`
- `AuthController.java`
- `chat_message.dart`
- `message_bubble.dart`
