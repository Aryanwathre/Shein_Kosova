# Zebra iOS App — TestFlight Handoff

This is the **Zebra** Flutter app (rebranded from "SH Kosova"). It needs to be built into a
**new signed `.ipa`** on macOS and uploaded to TestFlight.

## Key facts
- **App name (display):** Zebra
- **Bundle ID (unchanged):** `com.shein-ks.sheinKosova`
  → Uploads to the **existing** App Store Connect app record as a **new build**. Do NOT create a new app.
- **Version / build:** `1.0.9+47` (01-10-2026: payment method/status labels; 30-09-2026: colour chips, Full Name address, white brand headers, empty-description fix; earlier: brands, filters, statuses). iOS reads it from `pubspec.yaml` (Info.plist uses $(FLUTTER_BUILD_NAME)/$(FLUTTER_BUILD_NUMBER)); Codemagic also passes it explicitly. Must stay higher than the last uploaded build.
- **Backend API:** `https://api.zebra-ks.shop`
- A **new `.ipa` is required** — the previously uploaded build (41) has the old branding and cannot be reused.

## What was already done in this source
- App display name → Zebra (iOS Info.plist, Android manifest, app title)
- All app icons regenerated (iOS AppIcon set + Android mipmaps) — opaque, no transparency
- Launch/splash images regenerated (were missing)
- API domain switched to api.zebra-ks.shop
- In-app text (About / Privacy / Terms / share) rebranded to Zebra + @zebra-ks.shop
- Build number bumped to 42

## Build on a Mac (Xcode + Flutter installed)
```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
# Output: build/ios/ipa/*.ipa
```
Then upload the `.ipa` via **Transporter** (Mac App Store) or Xcode Organizer → App Store Connect → TestFlight.
Signing: use the team's Apple Distribution certificate + an App Store provisioning profile for
`com.shein-ks.sheinKosova` (or let Xcode "Automatically manage signing").

## Or build with no Mac (Codemagic CI)
A ready `codemagic.yaml` is included at the project root — see its header comments for the
App Store Connect API key + Codemagic setup. It builds on a cloud Mac and auto-uploads to TestFlight.

## After upload
App Store Connect → TestFlight → Internal Testing → add the client's Apple ID email as a tester.
