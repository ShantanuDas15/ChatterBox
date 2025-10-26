# Configuration Guide

## Environment Variables Setup

This application requires the following environment variables to be set before running.

### Required Environment Variables

| Variable                | Description                      | Example                                          |
| ----------------------- | -------------------------------- | ------------------------------------------------ |
| `MONGODB_URI`           | MongoDB Atlas connection string  | `mongodb+srv://user:pass@cluster.mongodb.net/db` |
| `GOOGLE_CLIENT_ID`      | Google OAuth2 Client ID          | Get from Google Cloud Console                    |
| `GOOGLE_CLIENT_SECRET`  | Google OAuth2 Client Secret      | Get from Google Cloud Console                    |
| `JWT_SECRET`            | Secret key for JWT token signing | Generate with `openssl rand -base64 32`          |
| `FRONTEND_REDIRECT_URL` | Frontend URL for OAuth redirect  | `http://localhost:3000/auth/callback`            |

---

## Setup Instructions

### Option 1: Using Environment Variables (Recommended for Production)

#### Windows (Command Prompt)

```cmd
set MONGODB_URI=your_mongodb_uri
set GOOGLE_CLIENT_ID=your_client_id
set GOOGLE_CLIENT_SECRET=your_client_secret
set JWT_SECRET=your_jwt_secret
set FRONTEND_REDIRECT_URL=http://localhost:3000/auth/callback
```

#### Windows (PowerShell)

```powershell
$env:MONGODB_URI="your_mongodb_uri"
$env:GOOGLE_CLIENT_ID="your_client_id"
$env:GOOGLE_CLIENT_SECRET="your_client_secret"
$env:JWT_SECRET="your_jwt_secret"
$env:FRONTEND_REDIRECT_URL="http://localhost:3000/auth/callback"
```

#### Linux/Mac

```bash
export MONGODB_URI=your_mongodb_uri
export GOOGLE_CLIENT_ID=your_client_id
export GOOGLE_CLIENT_SECRET=your_client_secret
export JWT_SECRET=your_jwt_secret
export FRONTEND_REDIRECT_URL=http://localhost:3000/auth/callback
```

### Option 2: Using IntelliJ IDEA / Eclipse

1. Open Run/Debug Configurations
2. Add Environment Variables in the configuration panel
3. Add each variable with its value

### Option 3: Using .env file (Development Only)

1. Copy `.env.example` to `.env`
2. Fill in your actual values
3. **NEVER commit `.env` to version control**
4. Use a library like `spring-dotenv` to load the file

---

## Getting Credentials

### MongoDB Atlas

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a cluster
3. Click "Connect" → "Connect your application"
4. Copy the connection string
5. Replace `<password>` and `<database>` with your values

### Google OAuth2

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable "Google+ API"
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
5. Add authorized redirect URI: `http://localhost:8080/login/oauth2/code/google`
6. Copy Client ID and Client Secret

### JWT Secret

Generate a secure random key:

```bash
openssl rand -base64 32
```

---

## Security Notes

⚠️ **IMPORTANT**: Never commit sensitive credentials to version control!

- ✅ Use environment variables
- ✅ Keep `.env` in `.gitignore`
- ✅ Use different credentials for dev/staging/production
- ✅ Rotate credentials regularly
- ✅ Use secrets management tools in production (AWS Secrets Manager, Azure Key Vault, etc.)
- ❌ Don't hardcode credentials in `application.properties`
- ❌ Don't commit `application.properties` with real values
- ❌ Don't share credentials in chat or email

---

## Running the Application

After setting up environment variables:

```bash
cd backend
./mvnw spring-boot:run
```

Or in Windows:

```cmd
cd backend
mvnw.cmd spring-boot:run
```
