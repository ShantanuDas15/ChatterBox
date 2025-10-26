# Frontend Deployment to Netlify

Deploy your Flutter Web frontend to Netlify.

---

## 🎯 Step 1: Prepare Flutter Web Build

### 1.1 Update API Base URL

Edit `frontend/lib/core/constants.dart`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

// Production API URL
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://chatterbox-backend.onrender.com', // Your Render URL
);

// Google Web Client ID
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '', // Will be set during build
);
```

### 1.2 Create Netlify Configuration

Create `netlify.toml` in the **frontend** directory:

```toml
[build]
  base = "frontend"
  command = "flutter build web --release --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID --dart-define=API_BASE_URL=$API_BASE_URL"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.24.5"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    X-Content-Type-Options = "nosniff"
```

### 1.3 Create Build Script

Create `frontend/build.sh`:

```bash
#!/bin/bash
set -e

echo "Installing Flutter..."
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
fi

export PATH="$HOME/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Enabling Flutter web..."
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building for web..."
flutter build web --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

echo "Build complete!"
```

Make it executable:
```bash
chmod +x frontend/build.sh
```

### 1.4 Update Web Index.html (Optional)

Edit `frontend/web/index.html` to update title and meta tags:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ChatterBox - Real-time Chat</title>
  <meta name="description" content="ChatterBox - A modern real-time chat application">
  <!-- Rest of the file... -->
</head>
```

### 1.5 Commit Changes

```bash
cd "c:\Java Projects\ChatterBox"
git add frontend/lib/core/constants.dart frontend/netlify.toml frontend/build.sh frontend/web/index.html
git commit -m "Add Netlify deployment configuration"
git push origin main
```

---

## 🚀 Step 2: Deploy to Netlify

### 2.1 Create Netlify Account

1. Go to [https://netlify.com](https://netlify.com)
2. Click **"Sign up"**
3. Choose **"Sign up with GitHub"**
4. Authorize Netlify

### 2.2 Create New Site

1. Click **"Add new site"** → **"Import an existing project"**
2. Choose **"Deploy with GitHub"**
3. Select your repository: `ChatterBox`
4. Configure build settings:

   **Basic Settings:**
   - **Branch to deploy**: `main`
   - **Base directory**: `frontend`
   - **Build command**: `./build.sh`
   - **Publish directory**: `frontend/build/web`

### 2.3 Set Environment Variables

Before deploying, click **"Show advanced"** → **"New variable"**:

| Key | Value | Notes |
|-----|-------|-------|
| `GOOGLE_WEB_CLIENT_ID` | `853726...googleusercontent.com` | From Google Cloud Console |
| `API_BASE_URL` | `https://chatterbox-backend.onrender.com` | Your Render backend URL |
| `FLUTTER_VERSION` | `3.24.5` | Or your Flutter version |

### 2.4 Deploy

1. Click **"Deploy site"**
2. Netlify will:
   - Clone your repository
   - Install Flutter
   - Build your web app
   - Deploy to CDN
3. Wait 5-10 minutes for first deployment
4. Monitor build logs for errors

### 2.5 Get Your Frontend URL

Once deployed, your frontend will be available at:
```
https://random-name-123456.netlify.app
```

You can customize this in **Site settings** → **Change site name**:
```
https://chatterbox-app.netlify.app
```

---

## 🔧 Step 3: Update Backend Configuration

### 3.1 Update Backend CORS

Now that you have your Netlify URL, update the backend:

1. Go to Render dashboard
2. Click your backend service
3. Go to **Environment** tab
4. Update `FRONTEND_URL`:
   ```
   https://chatterbox-app.netlify.app
   ```
5. Click **"Save Changes"**
6. Service will automatically redeploy

### 3.2 Update Frontend Constants (If Needed)

If you didn't use environment variables, update `frontend/lib/core/constants.dart` manually:

```dart
const String kApiBaseUrl = 'https://chatterbox-backend.onrender.com';
```

Then commit and push:
```bash
git add frontend/lib/core/constants.dart
git commit -m "Update API URL for production"
git push origin main
```

---

## 🔐 Step 4: Update Google OAuth (Again)

### 4.1 Add Netlify URL to Authorized Origins

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **APIs & Services** → **Credentials**
3. Click your OAuth 2.0 Client ID
4. Under **Authorized JavaScript origins**, add:
   ```
   https://chatterbox-app.netlify.app
   ```

### 4.2 Add to Authorized Redirect URIs

Add (if not already added):
```
https://chatterbox-app.netlify.app
https://chatterbox-backend.onrender.com/login/oauth2/code/google
```

5. Click **"Save"**

---

## ✅ Step 5: Test Your Deployment

### 5.1 Open Your App

Visit: `https://chatterbox-app.netlify.app`

### 5.2 Test Login

1. Click **"Sign in with Google"**
2. Verify OAuth popup appears
3. Complete authentication
4. Should redirect to home screen

### 5.3 Test Features

- ✅ Create a channel
- ✅ Send a message
- ✅ See real-time updates (WebSocket)
- ✅ Browse channels
- ✅ View profile

### 5.4 Check Browser Console

Press F12 and check:
- ❌ No CORS errors
- ❌ No WebSocket connection errors
- ✅ API calls succeed
- ✅ WebSocket connected

---

## 🐛 Troubleshooting

### Build Fails on Netlify

**Flutter not found:**
- Verify `FLUTTER_VERSION` environment variable is set
- Check build logs for Flutter installation errors
- Ensure `build.sh` has correct permissions

**Dependencies fail:**
```bash
# Add to build.sh before flutter pub get:
flutter doctor
flutter config --enable-web
```

**Build timeout:**
- Netlify free tier has 300 minutes/month
- Large builds may timeout
- Consider upgrading or optimizing build

### App Loads But Shows Errors

**CORS errors in console:**
- Backend CORS not configured correctly
- Check backend allows your Netlify URL
- Verify `FRONTEND_URL` env var in Render

**WebSocket connection fails:**
- Check backend WebSocket endpoint accessible
- Verify wss:// protocol (not ws://)
- Check JWT token is being sent

**Google Sign-In fails:**
- Verify `GOOGLE_WEB_CLIENT_ID` is set correctly
- Check Google OAuth authorized origins
- Clear browser cache and retry

### API Calls Fail

**404 errors:**
- Backend API URL incorrect
- Check `API_BASE_URL` environment variable
- Verify backend is running (check Render)

**401 Unauthorized:**
- JWT token not being sent
- Token expired
- Backend JWT_SECRET changed

### Page Refreshes to 404

**Solution:** Already handled by `netlify.toml` redirect rule:
```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

If still happening:
- Verify `netlify.toml` is in `frontend/` directory
- Redeploy the site

---

## 🔄 Automatic Deployments

Netlify automatically deploys when you push to `main`:

```bash
# Make changes to frontend
cd frontend
# Edit files...

# Commit and push
git add .
git commit -m "Update frontend"
git push origin main

# Netlify automatically:
# 1. Detects push
# 2. Rebuilds application
# 3. Deploys to CDN
```

### Deploy Previews

Netlify creates preview deployments for pull requests:
1. Create a new branch
2. Make changes
3. Push and create PR
4. Netlify builds a preview
5. Test before merging

---

## 🎨 Custom Domain (Optional)

### Add Your Own Domain

1. Go to **Site settings** → **Domain management**
2. Click **"Add custom domain"**
3. Enter your domain: `chatterbox.yourdomain.com`
4. Follow DNS configuration instructions
5. Netlify provides free SSL certificate

---

## 📊 Monitoring & Analytics

### View Deploy Logs

1. Go to Netlify dashboard
2. Click **"Deploys"**
3. Click any deploy to see logs

### View Site Analytics

1. Click **"Analytics"** tab
2. See:
   - Page views
   - Unique visitors
   - Top pages
   - Bandwidth usage

### Enable Error Tracking (Optional)

Integrate with:
- Sentry
- LogRocket
- Rollbar

---

## 💰 Netlify Free Tier

Includes:
- ✅ 100GB bandwidth/month
- ✅ Unlimited sites
- ✅ 300 build minutes/month
- ✅ Automatic HTTPS
- ✅ Deploy previews
- ✅ Form handling
- ✅ Identity/authentication

---

## 🚀 Performance Optimization

### 1. Enable Netlify Edge

For faster global delivery:
1. Go to **Site settings** → **Build & deploy**
2. Enable **"Asset optimization"**
3. Enable:
   - CSS minification
   - JS minification
   - Image optimization

### 2. Add Cache Headers

Already configured in `netlify.toml`:
```toml
[[headers]]
  for = "/*.js"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### 3. Compress Assets

Flutter web builds are already optimized:
- Minified JavaScript
- Tree-shaking
- Code splitting

---

## ✅ Frontend Deployment Checklist

- [ ] Netlify account created
- [ ] Environment variables configured
- [ ] Build script created and executable
- [ ] netlify.toml configured
- [ ] Site deployed successfully
- [ ] Custom site name set
- [ ] Backend FRONTEND_URL updated
- [ ] Google OAuth origins updated
- [ ] Login tested
- [ ] WebSocket connection tested
- [ ] All features working
- [ ] No console errors

---

## 🎉 Success!

Your ChatterBox app is now live:
- **Frontend**: `https://chatterbox-app.netlify.app`
- **Backend**: `https://chatterbox-backend.onrender.com`

Share it with the world! 🌍

---

**Need help?** Check:
- [Netlify Documentation](https://docs.netlify.com)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Main Deployment Guide](./DEPLOYMENT.md)
