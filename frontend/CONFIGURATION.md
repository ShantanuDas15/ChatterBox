# ChatterBox Frontend Configuration Guide

## Environment Variables Setup

### Step 1: Create your .env file

Copy the `.env.example` file to create your own `.env`:

```bash
copy .env.example .env
```

### Step 2: Add your Google Web Client ID

Open the `.env` file and replace the placeholder with your actual Google Web Client ID from Google Cloud Console:

```
GOOGLE_WEB_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com
```

**Important:** The `.env` file is already in `.gitignore` and will NOT be committed to your repository.

## Running the App

### Option 1: Using --dart-define (Recommended)

Run the app with the environment variable directly:

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-actual-client-id-here
```

### Option 2: Using a launch configuration (VS Code)

Create or update `.vscode/launch.json` in the frontend directory with:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Dev)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["--dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_ID_HERE"]
    }
  ]
}
```

Replace `YOUR_ID_HERE` with your actual Google Web Client ID.

### Option 3: Using a script file

Create a `run.cmd` file (already in .gitignore):

```cmd
@echo off
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-actual-client-id-here
```

## Building for Production

When building for release, include the environment variable:

```bash
flutter build apk --dart-define=GOOGLE_WEB_CLIENT_ID=your-actual-client-id-here
```

## Security Notes

- ✅ `.env` files are ignored by git
- ✅ Credentials are not hardcoded in source files
- ✅ Safe to commit all code to repository
- ⚠️ Never commit your actual Client ID to version control
- 💡 Team members need to create their own `.env` file from `.env.example`
