# GitHub Actions Workflow Guide

## Overview

The Flutter CI/CD pipeline automatically runs on every push and pull request to ensure code quality and enable automated deployments.

## Workflow Triggers

### Automatic Triggers
- **Push Events**: Workflow runs when code is pushed to:
  - `main` branch
  - `master` branch
  - `develop` branch

- **Pull Request Events**: Workflow runs when a PR is opened or updated targeting:
  - `main` branch
  - `master` branch
  - `develop` branch

### Manual Trigger
- **Workflow Dispatch**: Can be manually triggered from GitHub Actions UI
  - Go to Actions → Flutter CI/CD → Run workflow

## Jobs Breakdown

### 1. Analyze Job 🔍
**Purpose**: Static code analysis to identify potential issues

**What it does**:
- Sets up Flutter and Java environment
- Installs project dependencies
- Runs `flutter analyze` command

**When it fails**:
- Code has syntax errors
- Code has linting issues
- Code violates analysis rules in `analysis_options.yaml`

**How to fix**:
```bash
flutter analyze
# Fix issues shown in the output
```

### 2. Test Job ✅
**Purpose**: Run all unit and widget tests

**What it does**:
- Sets up Flutter and Java environment
- Installs project dependencies
- Runs `flutter test` command

**Dependencies**: Runs after Analyze job completes

**When it fails**:
- Tests are failing
- Test setup is incorrect

**How to fix**:
```bash
flutter test
# Fix failing tests
```

### 3. Build Job 🔨
**Purpose**: Build release Android APK

**What it does**:
- Sets up Flutter and Java environment
- Installs project dependencies
- Builds release APK using `flutter build apk --release`
- Uploads APK as a GitHub Actions artifact

**Dependencies**: Runs after both Analyze and Test jobs complete

**When it fails**:
- Build configuration issues
- Missing dependencies
- Android build errors

**How to fix**:
```bash
flutter build apk --release
# Fix build errors shown in the output
```

### 4. Deploy Job 🚀
**Purpose**: Deploy APK to Firebase App Distribution

**What it does**:
- Downloads the APK artifact from Build job
- Deploys to Firebase App Distribution
- Notifies testers via Firebase

**Dependencies**: 
- Runs after Build job completes
- Only runs on **push events** (not pull requests)
- Only runs on `main`, `master`, or `develop` branches

**When it fails**:
- GitHub secrets are not configured
- Firebase App ID is incorrect
- Service account lacks permissions
- Firebase project is not set up

**How to fix**: See [FIREBASE_APP_DISTRIBUTION_SETUP.md](FIREBASE_APP_DISTRIBUTION_SETUP.md)

## Viewing Results

### In Pull Requests
When you create a PR, you'll see the workflow status:
- ✅ Green checkmark: All jobs passed
- ❌ Red X: One or more jobs failed
- 🟡 Yellow dot: Jobs are running

Click "Details" to see which job failed and view logs.

### In Actions Tab
1. Go to your repository
2. Click on "Actions" tab
3. Click on a workflow run to see details
4. Click on individual jobs to see logs

## Artifacts

After the Build job completes successfully:
1. Go to Actions → Click on the workflow run
2. Scroll to "Artifacts" section
3. Download `app-release` to get the APK file

This is useful if you want to test the APK manually before deployment.

## Common Issues

### Issue: "Analyze job failed"
**Solution**: Run `flutter analyze` locally and fix reported issues

### Issue: "Test job failed"
**Solution**: Run `flutter test` locally and fix failing tests

### Issue: "Build job failed with 'google-services.json not found'"
**Solution**: Ensure `android/app/google-services.json` exists and is not gitignored

### Issue: "Deploy job is skipped"
**Solution**: Deploy only runs on push to main/master/develop, not on PRs

### Issue: "Firebase deployment failed"
**Solution**: Check that GitHub secrets are properly configured. See [FIREBASE_APP_DISTRIBUTION_SETUP.md](FIREBASE_APP_DISTRIBUTION_SETUP.md)

## Performance

**Typical Run Times**:
- Analyze: ~2-3 minutes
- Test: ~2-3 minutes
- Build: ~5-8 minutes
- Deploy: ~1-2 minutes

**Total**: ~10-16 minutes for a complete workflow run

**Optimization Features**:
- Flutter SDK caching enabled
- Dependencies cached between runs
- APK built once and reused for deployment

## Customization

### Change Flutter Version
The workflow uses the latest stable Flutter version by default. To pin to a specific version, edit `.github/workflows/flutter-ci-cd.yml`:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.0'  # Add this line to pin a specific version
    channel: 'stable'
```

**Note**: Ensure the Flutter version you specify includes a Dart SDK version that meets the requirements in `pubspec.yaml` (currently ^3.8.1).

### Change Tester Groups
Edit the deploy job in the workflow file:
```yaml
groups: testers  # Change to your Firebase tester group name
```

### Add More Branches
Edit the workflow triggers:
```yaml
on:
  push:
    branches: [ main, master, develop, staging ]  # Add more branches
```

## Security Notes

- GitHub secrets are encrypted and never exposed in logs
- GITHUB_TOKEN permissions are limited to `contents: read`
- Service account credentials are stored securely
- APK artifacts are retained for 90 days by default

## Need Help?

- Check [FIREBASE_APP_DISTRIBUTION_SETUP.md](FIREBASE_APP_DISTRIBUTION_SETUP.md) for Firebase setup
- Check workflow logs in Actions tab for detailed error messages
- Review Flutter documentation at https://docs.flutter.dev
