# ChatterBox Deployment - Quick Reference

## 🚀 Quick Start Commands

### 1. Commit Deployment Files

```powershell
cd "c:\Java Projects\ChatterBox"

# Add deployment files
git add render.yaml
git add frontend/netlify.toml
git add frontend/build.sh
git add frontend/lib/core/constants.dart
git add backend/src/main/java/com/chatterbox/config/CorsConfig.java

# Commit
git commit -m "Add deployment configuration for Render and Netlify"

# Push
git push origin main
```

### 2. Deploy Backend (Render)

1. Go to [render.com](https://render.com)
2. New → Web Service
3. Connect GitHub repo: `ChatterBox`
4. Settings:
   - Name: `chatterbox-backend`
   - Build: `cd backend && chmod +x mvnw && ./mvnw clean package -DskipTests`
   - Start: `cd backend && java -Dserver.port=$PORT -jar target/*.jar`
5. Environment Variables:
   ```
   MONGODB_URI=mongodb+srv://...
   GOOGLE_CLIENT_ID=...
   GOOGLE_CLIENT_SECRET=...
   JWT_SECRET=<generate new>
   FRONTEND_URL=https://your-app.netlify.app
   ```
6. Deploy

**Your backend URL**: `https://chatterbox-backend.onrender.com`

### 3. Deploy Frontend (Netlify)

1. Go to [netlify.com](https://netlify.com)
2. New site → Import from Git
3. Connect GitHub repo: `ChatterBox`
4. Settings:
   - Base: `frontend`
   - Build: `bash build.sh`
   - Publish: `frontend/build/web`
5. Environment Variables:
   ```
   GOOGLE_WEB_CLIENT_ID=...
   API_BASE_URL=https://chatterbox-backend.onrender.com
   FLUTTER_VERSION=3.24.5
   ```
6. Deploy

**Your frontend URL**: `https://your-app.netlify.app`

---

## 🔐 Environment Variables

### Backend (Render)

| Variable | Example | Where to Get |
|----------|---------|--------------|
| `MONGODB_URI` | `mongodb+srv://user:pass@cluster.mongodb.net/chatterbox` | MongoDB Atlas |
| `GOOGLE_CLIENT_ID` | `123456.apps.googleusercontent.com` | Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | `GOCSPX-xxxxx` | Google Cloud Console |
| `JWT_SECRET` | Generate: `openssl rand -base64 32` | Generate new for production |
| `FRONTEND_URL` | `https://your-app.netlify.app` | From Netlify after deploy |

### Frontend (Netlify)

| Variable | Example | Where to Get |
|----------|---------|--------------|
| `GOOGLE_WEB_CLIENT_ID` | `123456.apps.googleusercontent.com` | Google Cloud Console |
| `API_BASE_URL` | `https://chatterbox-backend.onrender.com` | From Render after deploy |
| `FLUTTER_VERSION` | `3.24.5` | Your Flutter version |

---

## 🔧 Post-Deployment Steps

### 1. Update Google OAuth

In [Google Cloud Console](https://console.cloud.google.com):

**Authorized JavaScript origins:**
```
https://chatterbox-backend.onrender.com
https://your-app.netlify.app
```

**Authorized redirect URIs:**
```
https://chatterbox-backend.onrender.com/login/oauth2/code/google
https://your-app.netlify.app
```

### 2. Update MongoDB Atlas

In [MongoDB Atlas](https://cloud.mongodb.com):
- Network Access → Add IP: `0.0.0.0/0` (allow all)
- Or get Render's IPs and whitelist them

### 3. Update Backend with Frontend URL

After Netlify deploy:
1. Go to Render dashboard
2. Update `FRONTEND_URL` environment variable
3. Service will auto-redeploy

---

## ✅ Verification Checklist

### Backend Health Check
```
https://chatterbox-backend.onrender.com/api/v1/health
```
Should return: `{"status":"UP",...}`

### WebSocket Test
Connect to: `wss://chatterbox-backend.onrender.com/ws`

### Frontend Test
1. Visit: `https://your-app.netlify.app`
2. Click "Sign in with Google"
3. Create a channel
4. Send a message
5. Verify real-time updates work

---

## 🐛 Common Issues & Fixes

### Backend won't start
```bash
# Check Render logs
# Verify: All environment variables set
# Verify: MongoDB Atlas allows connections
```

### Frontend build fails
```bash
# Check Netlify build logs
# Verify: build.sh has correct permissions
# Verify: FLUTTER_VERSION is set
```

### CORS errors
```bash
# Update backend/src/.../CorsConfig.java
# Add your Netlify URL
# Redeploy backend
```

### WebSocket connection fails
```bash
# Check browser console for errors
# Verify: wss:// (not ws://)
# Verify: JWT token is sent in connection
```

### Google Sign-In fails
```bash
# Verify: Authorized origins updated
# Verify: GOOGLE_WEB_CLIENT_ID matches
# Clear browser cache
```

---

## 📊 Monitoring

### Render Logs
```
Render Dashboard → Your Service → Logs
```

### Netlify Logs
```
Netlify Dashboard → Deploys → Click deploy → Logs
```

### Browser Console
```
Press F12 → Console tab
Check for errors
```

---

## 🔄 Making Updates

### Update Backend
```powershell
# Make changes
git add backend/
git commit -m "Update backend"
git push origin main

# Render auto-deploys from main branch
```

### Update Frontend
```powershell
# Make changes
git add frontend/
git commit -m "Update frontend"
git push origin main

# Netlify auto-deploys from main branch
```

---

## 💰 Free Tier Limits

### Render Free
- ⏰ Sleeps after 15 minutes inactivity
- 🐌 30-60s cold start
- 💾 750 hours/month

### Netlify Free
- 🌐 100GB bandwidth/month
- ⚡ 300 build minutes/month
- 🔄 Unlimited deploys

### MongoDB Atlas Free
- 💾 512MB storage
- ⚡ Shared cluster
- 🌐 Good for demos

---

## 🎯 Production Upgrades

### Render Starter ($7/month)
- No sleeping
- Better performance
- More resources

### Netlify Pro ($19/month)
- More bandwidth
- More build minutes
- Better support

### MongoDB Atlas M10+ ($57+/month)
- Dedicated cluster
- Better performance
- More storage

---

## 📚 Documentation Links

- [Main Deployment Guide](./DEPLOYMENT.md)
- [Backend Deployment Details](./DEPLOYMENT_BACKEND.md)
- [Frontend Deployment Details](./DEPLOYMENT_FRONTEND.md)

---

## 🆘 Need Help?

Check:
- Render logs
- Netlify logs
- Browser console (F12)
- GitHub Issues

Common errors are usually:
- Missing environment variables
- CORS configuration
- Google OAuth setup
- MongoDB network access
