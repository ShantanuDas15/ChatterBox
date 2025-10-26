# ChatterBox Deployment Guide

Complete guide to deploy ChatterBox with:
- **Backend**: Render (Spring Boot + WebSocket)
- **Frontend**: Netlify (Flutter Web)

---

## 📋 Prerequisites

Before deploying, ensure you have:

1. ✅ GitHub account with ChatterBox repository
2. ✅ [Render account](https://render.com) (free tier available)
3. ✅ [Netlify account](https://netlify.com) (free tier available)
4. ✅ MongoDB Atlas cluster (already configured)
5. ✅ Google OAuth credentials (already configured)

---

## 🚀 Deployment Steps

### Part 1: Deploy Backend to Render
See: [DEPLOYMENT_BACKEND.md](./DEPLOYMENT_BACKEND.md)

### Part 2: Deploy Frontend to Netlify
See: [DEPLOYMENT_FRONTEND.md](./DEPLOYMENT_FRONTEND.md)

---

## 📊 Quick Overview

| Component | Platform | URL Pattern | Cost |
|-----------|----------|-------------|------|
| Backend API | Render | `https://chatterbox-api.onrender.com` | Free (with limitations) |
| Frontend | Netlify | `https://chatterbox-app.netlify.app` | Free |
| Database | MongoDB Atlas | Cloud-hosted | Free (512MB) |

---

## 🔧 Environment Variables Overview

### Backend (Render):
```
MONGODB_URI=mongodb+srv://...
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
JWT_SECRET=...
FRONTEND_URL=https://chatterbox-app.netlify.app
```

### Frontend (Netlify):
```
GOOGLE_WEB_CLIENT_ID=...
VITE_API_BASE_URL=https://chatterbox-api.onrender.com
```

---

## ⚙️ Post-Deployment Configuration

After both are deployed:

1. **Update Google OAuth Redirect URIs:**
   - Add: `https://chatterbox-api.onrender.com/login/oauth2/code/google`
   - Add: `https://chatterbox-app.netlify.app`

2. **Update MongoDB Atlas Network Access:**
   - Add Render's IP addresses (or allow all: `0.0.0.0/0`)

3. **Test WebSocket Connection:**
   - Use browser dev tools to verify WebSocket connects to your backend

---

## 🐛 Common Issues

### Backend won't start:
- Check Render logs for errors
- Verify all environment variables are set
- Ensure MongoDB Atlas allows connections from Render

### Frontend can't connect to backend:
- Check CORS settings in backend
- Verify API URL in frontend constants
- Check browser console for errors

### WebSocket not connecting:
- Ensure backend WebSocket endpoint is accessible
- Check for CORS issues
- Verify JWT token is being sent correctly

---

## 💰 Cost Considerations

### Free Tier Limitations:

**Render Free:**
- ⏰ Spins down after 15 minutes of inactivity
- 🐌 Cold starts take 30-60 seconds
- 💾 750 hours/month
- ⚡ Limited CPU/RAM

**Netlify Free:**
- 🌐 100GB bandwidth/month
- ⚡ Instant deploys
- 🔄 300 build minutes/month
- 📁 Unlimited sites

**MongoDB Atlas Free:**
- 💾 512MB storage
- 🔄 Shared cluster
- ⚡ Good for development/demo

---

## 🔄 CI/CD Setup (Optional)

Both Render and Netlify support automatic deployments:

1. **Push to GitHub** → Automatic deployment
2. **Pull Request** → Preview deployment (Netlify)
3. **Merge to main** → Production deployment

---

## 📚 Additional Resources

- [Render Documentation](https://render.com/docs)
- [Netlify Documentation](https://docs.netlify.com)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

---

## ✅ Deployment Checklist

- [ ] MongoDB Atlas configured
- [ ] Google OAuth credentials created
- [ ] Backend deployed to Render
- [ ] Frontend deployed to Netlify
- [ ] Environment variables set
- [ ] Google OAuth redirect URIs updated
- [ ] CORS configured correctly
- [ ] Test login functionality
- [ ] Test WebSocket connection
- [ ] Test creating channels
- [ ] Test sending messages

---

**Ready to deploy?** Start with [Backend Deployment →](./DEPLOYMENT_BACKEND.md)
