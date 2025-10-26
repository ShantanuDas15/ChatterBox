# Backend Deployment to Render

Deploy your Spring Boot backend to Render with WebSocket support.

---

## 🎯 Step 1: Prepare Your Repository

### 1.1 Create a Render Configuration File

Create `render.yaml` in the **root** of your project:

```yaml
services:
  - type: web
    name: chatterbox-backend
    env: java
    buildCommand: cd backend && ./mvnw clean package -DskipTests
    startCommand: cd backend && java -jar target/*.jar
    envVars:
      - key: MONGODB_URI
        sync: false
      - key: GOOGLE_CLIENT_ID
        sync: false
      - key: GOOGLE_CLIENT_SECRET
        sync: false
      - key: JWT_SECRET
        sync: false
      - key: FRONTEND_URL
        value: https://your-app.netlify.app
      - key: PORT
        value: 8080
```

### 1.2 Update Backend CORS Configuration

Ensure your `backend/src/main/java/com/chatterbox/config/CorsConfig.java` allows your Netlify domain:

```java
configuration.setAllowedOrigins(Arrays.asList(
    "http://localhost:3000",
    "http://localhost:57971", // Flutter web dev
    System.getenv("FRONTEND_URL") // Netlify URL from env
));
```

### 1.3 Commit and Push

```bash
git add render.yaml backend/src/main/java/com/chatterbox/config/CorsConfig.java
git commit -m "Add Render deployment configuration"
git push origin main
```

---

## 🚀 Step 2: Deploy to Render

### 2.1 Create Render Account

1. Go to [https://render.com](https://render.com)
2. Sign up with GitHub
3. Authorize Render to access your repositories

### 2.2 Create New Web Service

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository: `ChatterBox`
3. Configure the service:

   **Basic Settings:**
   - **Name**: `chatterbox-backend`
   - **Region**: Choose closest to you
   - **Branch**: `main`
   - **Root Directory**: Leave empty
   - **Runtime**: `Java`

   **Build & Deploy:**
   - **Build Command**:
     ```bash
     cd backend && ./mvnw clean package -DskipTests
     ```
   - **Start Command**:
     ```bash
     cd backend && java -Dserver.port=$PORT -jar target/*.jar
     ```

   **Plan:**
   - Select **"Free"** (or paid if you prefer)

### 2.3 Set Environment Variables

Click **"Environment"** tab and add:

| Key | Value | Notes |
|-----|-------|-------|
| `MONGODB_URI` | `mongodb+srv://user:pass@...` | From your MongoDB Atlas |
| `GOOGLE_CLIENT_ID` | `853726...googleusercontent.com` | From Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | `GOCSPX-...` | From Google Cloud Console |
| `JWT_SECRET` | Generate new 256-bit secret | Use: `openssl rand -base64 32` |
| `FRONTEND_URL` | `https://your-app.netlify.app` | Update after Netlify deploy |
| `PORT` | `8080` | Render provides this automatically |

**⚠️ Important:** 
- Don't use your local development credentials
- Generate a new JWT secret for production
- Update FRONTEND_URL after deploying frontend

### 2.4 Deploy

1. Click **"Create Web Service"**
2. Render will:
   - Clone your repository
   - Run the build command
   - Start your application
3. Wait 5-10 minutes for first deployment
4. Monitor logs for any errors

### 2.5 Get Your Backend URL

Once deployed, your backend will be available at:
```
https://chatterbox-backend.onrender.com
```

Copy this URL - you'll need it for frontend configuration!

---

## 🔧 Step 3: Configure MongoDB Atlas

### 3.1 Allow Render's IP Addresses

1. Go to [MongoDB Atlas](https://cloud.mongodb.com)
2. Navigate to **Network Access**
3. Click **"Add IP Address"**
4. Options:
   - **Easy**: Add `0.0.0.0/0` (allow from anywhere)
   - **Secure**: Get Render's outbound IPs and add them individually

### 3.2 Test Connection

Check Render logs to verify MongoDB connection succeeded.

---

## 🔐 Step 4: Update Google OAuth

### 4.1 Add Authorized Redirect URIs

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **APIs & Services** → **Credentials**
3. Click your OAuth 2.0 Client ID
4. Under **Authorized redirect URIs**, add:
   ```
   https://chatterbox-backend.onrender.com/login/oauth2/code/google
   ```
5. Click **"Save"**

### 4.2 Add Authorized JavaScript Origins

Add:
```
https://chatterbox-backend.onrender.com
https://your-app.netlify.app
```

---

## ✅ Step 5: Verify Deployment

### 5.1 Test Health Endpoint

Open in browser:
```
https://chatterbox-backend.onrender.com/api/v1/health
```

Should return:
```json
{
  "status": "UP",
  "timestamp": "..."
}
```

### 5.2 Test WebSocket Endpoint

Use a WebSocket testing tool to connect to:
```
wss://chatterbox-backend.onrender.com/ws
```

### 5.3 Check Logs

In Render dashboard:
1. Click your service
2. Go to **"Logs"** tab
3. Verify:
   - ✅ Application started successfully
   - ✅ MongoDB connected
   - ✅ No errors

---

## 🐛 Troubleshooting

### Build Fails

**Error: Maven wrapper not executable**
```bash
# Fix locally and push:
git update-index --chmod=+x backend/mvnw
git commit -m "Make mvnw executable"
git push
```

**Error: Tests failing**
- Build command uses `-DskipTests` to skip tests
- Fix tests locally before deploying

### Application Won't Start

**Check environment variables:**
- All required vars set?
- MongoDB URI correct?
- Google credentials valid?

**Check logs for:**
- MongoDB connection errors
- Port binding issues
- Missing dependencies

### WebSocket Not Working

**CORS issues:**
- Update CorsConfig to allow your frontend URL
- Restart the service

**Connection refused:**
- Ensure WebSocket endpoint path is correct: `/ws`
- Check if port 8080 is being used

### Cold Starts (Free Tier)

On Render's free tier:
- ⏰ Service sleeps after 15 minutes of inactivity
- 🐌 First request after sleep takes 30-60 seconds
- 💡 Consider upgrading to paid tier for production

---

## 🔄 Automatic Deployments

Render automatically deploys when you push to `main` branch:

```bash
# Make changes
git add .
git commit -m "Update backend"
git push origin main

# Render automatically:
# 1. Detects push
# 2. Rebuilds application
# 3. Deploys new version
```

---

## 📊 Monitoring

### View Logs

1. Go to Render dashboard
2. Click your service
3. Click **"Logs"** tab
4. Real-time logs appear here

### View Metrics

Click **"Metrics"** tab to see:
- CPU usage
- Memory usage
- Response times
- Request counts

---

## 💰 Upgrade Options

Free tier limitations:
- Sleeps after 15 minutes inactivity
- 750 hours/month
- Limited CPU/RAM

**Starter Plan ($7/month):**
- Always on (no sleeping)
- Better performance
- More resources

---

## ✅ Backend Deployment Checklist

- [ ] `render.yaml` created and pushed
- [ ] Render account created
- [ ] Web service configured
- [ ] Environment variables set
- [ ] MongoDB Atlas network access configured
- [ ] Google OAuth redirect URIs updated
- [ ] Health endpoint responding
- [ ] WebSocket connection tested
- [ ] Logs checked for errors

---

**Next Step:** [Deploy Frontend to Netlify →](./DEPLOYMENT_FRONTEND.md)
