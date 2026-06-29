# Shein Kosova

A modern, high-performance e-commerce application built with **Flutter**, designed specifically for the Kosova market. This project provides a seamless shopping experience across **Android, iOS, and Web** platforms.

## 🚀 Project Overview

Shein Kosova is a full-featured e-commerce solution that connects users with a wide range of fashion and lifestyle products. It leverages a robust backend API to deliver real-time product updates, secure user management, and automated order processing.

### Key Features
- **Dynamic Product Discovery**: Browse products via categories, tags (New In, Deals, Trending), and a powerful search engine with advanced filtering.
- **Seamless Authentication**: JWT-based secure login and registration with a dedicated **Guest Mode** that allows users to explore the app without immediate sign-in.
- **Cart & Wishlist Management**: Persistent state management using the `Provider` pattern, allowing users to sync their favorite items and shopping bag across sessions.
- **Secure Checkout & Payments**: Integrated multi-step checkout process with shipping selection and a WebView-based secure payment gateway.
- **Smart Notifications**: Integrated **Firebase Cloud Messaging (FCM)** and **Local Notifications** for order status updates, marketing announcements, and global topic subscriptions (`all-users`).
- **Responsive Design**: A unified UI codebase optimized for mobile handsets, tablets, and desktop web browsers.
- **Dynamic Configuration**: App-wide settings, including theme colors and enabled payment methods, are fetched dynamically from the server at startup.

## 🛠 Tech Stack
- **Framework**: [Flutter](https://flutter.dev/) (latest stable)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**: [Http](https://pub.dev/packages/http) with a centralized `ApiServiceManager`
- **Backend/Cloud**: Firebase (Auth, Messaging, Core)
- **Storage**: Shared Preferences with a web-safe `StorageService` fallback
- **UI Components**: Google Fonts, Cached Network Image, Shimmer, Carousel Slider

## ⚙️ Setup Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter plugins.
- Firebase project set up for Android and iOS.

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Shein_Kosova
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Place your `google-services.json` in `android/app/`.
   - Place your `GoogleService-Info.plist` in `ios/Runner/`.
   - Ensure `firebase.json` is correctly configured in the root directory.

4. **Run the application:**
   - **Mobile:** `flutter run`
   - **Web:** `flutter run -d chrome`

5. **Building for Release:**
   - **Android:** `flutter build apk` or `flutter build appbundle`
   - **iOS:** `flutter build ios`
   - **Web:** `flutter build web`

## 📂 Project Structure
- `lib/constants/`: App routes, API endpoints, and theme definitions.
- `lib/models/`: Data models for products, categories, orders, and users.
- `lib/provider/`: State management logic for various app features.
- `lib/screen/`: All UI screens organized by feature (Auth, Home, Cart, etc.).
- `lib/services/`: Core service logic for API calls, storage, and notifications.
- `lib/widgets/`: Reusable UI components used across the project.
