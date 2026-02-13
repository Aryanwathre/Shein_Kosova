# Firebase App Distribution Setup Guide

This document explains how to set up Firebase App Distribution for automated deployments via GitHub Actions.

## Prerequisites

1. A Firebase project with Firebase App Distribution enabled
2. An Android app registered in your Firebase project
3. A service account with appropriate permissions

## Required GitHub Secrets

You need to add the following secrets to your GitHub repository:

### 1. FIREBASE_APP_ID

This is your Firebase Android App ID.

**How to find it:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon)
4. Scroll down to "Your apps" section
5. Click on your Android app
6. Copy the "App ID" (looks like `1:1234567890:android:abcdef1234567890`)

**How to add it to GitHub:**
1. Go to your GitHub repository
2. Click on "Settings" → "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Name: `FIREBASE_APP_ID`
5. Value: Paste your Firebase App ID
6. Click "Add secret"

### 2. FIREBASE_SERVICE_CREDENTIALS

This is the JSON content of your Firebase service account key file.

**How to create it:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on the gear icon → "Project settings"
4. Go to the "Service accounts" tab
5. Click "Generate new private key"
6. Download the JSON file
7. Open the JSON file in a text editor and copy all its contents

**How to add it to GitHub:**
1. Go to your GitHub repository
2. Click on "Settings" → "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Name: `FIREBASE_SERVICE_CREDENTIALS`
5. Value: Paste the entire JSON content
6. Click "Add secret"

## Testing the Workflow

Once you've added the secrets:

1. Push a commit to the `main`, `master`, or `develop` branch
2. Go to the "Actions" tab in your GitHub repository
3. You should see the workflow running
4. After successful completion, check Firebase App Distribution for the new build

## Workflow Features

The workflow includes the following jobs:

- **Analyze**: Runs `flutter analyze` to check for code issues
- **Test**: Runs `flutter test` to execute all tests
- **Build**: Creates a release APK
- **Deploy**: Uploads the APK to Firebase App Distribution (only on push to main/master/develop)

## Tester Groups

By default, the APK is distributed to the "testers" group. To modify this:

1. Create tester groups in Firebase Console → App Distribution → Testers & Groups
2. Update the `groups` field in `.github/workflows/flutter-ci-cd.yml`

## Troubleshooting

### Build fails with "google-services.json not found"
Make sure `google-services.json` is present in `android/app/` directory and not ignored by `.gitignore`.

### Firebase deployment fails
- Verify that both secrets are correctly set
- Check that the service account has "Firebase App Distribution Admin" role
- Ensure your Firebase project has App Distribution enabled

### Tests fail
Run `flutter test` locally to debug test failures before pushing.
