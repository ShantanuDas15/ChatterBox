# Google Cloud Console Configuration Guide

## Error: redirect_uri_mismatch

This error occurs when the redirect URI in your Google Cloud Console doesn't match what your Flutter app is using.

## Fix Steps:

### Step 1: Enable Required APIs

**IMPORTANT: You must enable the Google People API first!**

1. Go to: https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=853726513693
2. Click the **ENABLE** button
3. Wait 1-2 minutes for the API to activate

### Step 2: Open Google Cloud Console

1. Go to: https://console.cloud.google.com/apis/credentials
2. Make sure you're in the correct project
3. Find your OAuth 2.0 Client ID in the list

### Step 3: Configure Your OAuth Client ID

Click on your client ID: **853726513693-0mo5v0s9g2sj15lg9ej65j8qjog2931u**

#### Add Authorized JavaScript Origins:

```
http://localhost
http://localhost:8080
http://localhost:3000
http://localhost:5000
http://localhost:8081
```

#### Add Authorized Redirect URIs:

```
http://localhost
http://localhost:8080
http://localhost:3000
http://localhost:5000
http://localhost:8081
http://localhost/auth/callback
http://localhost:8080/auth/callback
http://localhost:3000/auth/callback
http://localhost:5000/auth/callback
http://localhost:8081/auth/callback
```

### Step 4: Save and Wait

1. Click **SAVE** at the bottom of the page
2. Wait 1-2 minutes for Google's servers to update
3. Clear your browser cache (or use incognito mode)

### Step 5: Restart Your App

```cmd
cd frontend
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=853726513693-0mo5v0s9g2sj15lg9ej65j8qjog2931u.apps.googleusercontent.com
```

## Understanding the URLs

- **JavaScript Origins**: Where your app is hosted (without path)
- **Redirect URIs**: Where Google redirects after authentication

For Flutter web development:

- Flutter typically runs on a random port (e.g., `localhost:52xxx`)
- By adding multiple common ports, we ensure it works regardless of the port
- The `localhost` without port should cover most cases

## Production Configuration

When deploying to production, add:

- Your production domain as JavaScript origin: `https://yourdomain.com`
- Your production redirect URI: `https://yourdomain.com/auth/callback`

## Common Errors

### Error: "People API has not been used in project"

**Solution:** Enable the Google People API:

1. Visit: https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=853726513693
2. Click **ENABLE**
3. Wait 1-2 minutes and retry

### Error: "redirect_uri_mismatch"

**Solution:** Make sure you've added all the JavaScript origins and redirect URIs listed above.

## Troubleshooting

If you still get the error:

1. Check the exact error message for the redirect URI it's trying to use
2. Add that specific URI to Google Cloud Console
3. Try running in incognito/private browsing mode
4. Clear browser cache and cookies
5. Wait a few minutes after saving changes in Google Cloud Console

## Notes

- Changes can take 5-10 minutes to propagate globally
- Each client ID type (Web, Android, iOS) has different configurations
- Make sure you're editing the **Web application** client ID
- The client ID in this file is your **Web application** type
