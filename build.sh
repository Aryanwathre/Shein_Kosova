#!/bin/bash

# ----------------------------
# CONFIG
# ----------------------------
ANDROID_ID="com.shein_ks.sheinKosova"
IOS_ID="com.shein-ks.sheinKosova"

AUTO_INCREMENT_VERSION=true   # set false to increment ONLY build number

PUBSPEC="pubspec.yaml"

echo "======================================"
echo "   Flutter Multi-Build Script"
echo "   With Auto Version Increment"
echo "======================================"

# ----------------------------
# READ current version from pubspec.yaml
# ----------------------------
CURRENT_VERSION=$(grep '^version:' $PUBSPEC | awk '{print $2}')
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

echo "Current version: $VERSION_NAME+$BUILD_NUMBER"

# ----------------------------
# INCREMENT VERSION
# ----------------------------
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))

if [ "$AUTO_INCREMENT_VERSION" = true ]; then
    # increment patch version
    MAJOR=$(echo $VERSION_NAME | cut -d. -f1)
    MINOR=$(echo $VERSION_NAME | cut -d. -f2)
    PATCH=$(echo $VERSION_NAME | cut -d. -f3)
    PATCH=$((PATCH + 1))
    NEW_VERSION_NAME="$MAJOR.$MINOR.$PATCH"
else
    NEW_VERSION_NAME="$VERSION_NAME"
fi

NEW_VERSION="$NEW_VERSION_NAME+$NEW_BUILD_NUMBER"

echo "New version: $NEW_VERSION"

# Write new version to pubspec.yaml
sed -i '' "s/^version:.*/version: $NEW_VERSION/" $PUBSPEC

echo "Updated pubspec.yaml ✔️"


# ----------------------------
# UPDATE ANDROID PACKAGE NAME
# ----------------------------
echo "Updating ANDROID applicationId → $ANDROID_ID"

sed -i '' "s/applicationId \".*\"/applicationId \"$ANDROID_ID\"/" android/app/build.gradle


# ----------------------------
# UPDATE IOS BUNDLE ID
# ----------------------------
echo "Updating iOS bundle identifier → $IOS_ID"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $IOS_ID" ios/Runner/Info.plist

# Also update Xcode project build number
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD_NUMBER" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION_NAME" ios/Runner/Info.plist

echo "iOS version updated ✔️"


# ----------------------------
# CLEAN
# ----------------------------
echo "Running flutter clean..."
flutter clean

# ----------------------------
# BUILD MENU
# ----------------------------
echo ""
echo "Select build options (comma separated):"
echo "1) Android AAB"
echo "2) Android APK"
echo "3) iOS IPA"
echo "4) Xcode Archive"
echo "5) All"
echo ""

read -p "Choose options (e.g. 1,3,4): " choices

# Convert input into array
IFS=',' read -ra SELECTED <<< "$choices"

# Function to check if a number is selected
contains() {
    for v in "${SELECTED[@]}"; do
        if [[ "$v" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

# If 5 (ALL) is selected, override everything
if contains "5"; then
    SELECTED=("1" "2" "3" "4")
fi

echo ""
echo "Building selected targets..."
echo ""

# Run builds
if contains "1"; then
    echo "➡ Building Android AAB..."
    flutter build appbundle --build-name=$NEW_VERSION_NAME --build-number=$NEW_BUILD_NUMBER
fi

if contains "2"; then
    echo "➡ Building Android APK..."
    flutter build apk --build-name=$NEW_VERSION_NAME --build-number=$NEW_BUILD_NUMBER
fi

if contains "3"; then
    echo "➡ Building iOS IPA..."
    flutter build ipa --build-name=$NEW_VERSION_NAME --build-number=$NEW_BUILD_NUMBER
fi

if contains "4"; then
    echo "➡ Opening Xcode for archive..."
    open ios/Runner.xcworkspace
fi

echo ""
echo "======================================"
echo "Completed builds: ${SELECTED[*]}"
echo "Version: $NEW_VERSION"
echo "======================================"
