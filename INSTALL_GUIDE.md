# DocScan Installation Guide

## Option A — Run from Source (Recommended for Developers)
## Option B — Build APK on Your Computer and Sideload

---

## OPTION A: Run from Source

### Prerequisites

1. Install Flutter SDK
   - Go to https://flutter.dev/docs/get-started/install
   - Choose your OS (Windows / macOS / Linux)
   - Follow the install guide completely
   - Run `flutter doctor` — fix any issues shown

2. Install Android Studio (for Android) or Xcode (for iOS/macOS)
   - Android Studio: https://developer.android.com/studio
   - Xcode (macOS only): Install from Mac App Store

3. Enable Developer Mode on your phone
   **Android:**
   - Settings → About Phone → tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"
   **iPhone (iOS 16+):**
   - Settings → Privacy & Security → Developer Mode → ON
   - Requires Apple Developer Account for device deployment

### Steps

```bash
# 1. Unzip the project
unzip docscan_flutter_project.zip
cd docscan_app

# 2. Get dependencies
flutter pub get

# 3. Connect your phone via USB cable

# 4. Verify Flutter sees your device
flutter devices

# 5. Run the app on your phone
flutter run

# OR build a release APK (Android only)
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

---

## OPTION B: Build APK — Step-by-Step for Non-Developers

### What You Need
- A Windows, Mac, or Linux computer
- An Android phone (iOS requires a Mac + Apple Developer account)
- USB cable

### Step 1: Install Flutter

**Windows:**
1. Download Flutter from https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your PATH environment variable:
   - Search "environment variables" in Windows start menu
   - Edit "Path" → New → `C:\flutter\bin`
4. Open Command Prompt and run: `flutter doctor`

**macOS:**
```bash
brew install flutter
flutter doctor
```

**Linux:**
```bash
sudo snap install flutter --classic
flutter doctor
```

### Step 2: Install Android Tools

1. Download Android Studio: https://developer.android.com/studio
2. Install it, open it, go to Tools → SDK Manager
3. Install Android SDK (API 33 or higher)
4. Accept all licenses: `flutter doctor --android-licenses`

### Step 3: Prepare Your Android Phone

1. On your phone: Settings → About Phone
2. Tap **Build Number** 7 times (you'll see "You are now a developer!")
3. Go back to Settings → Developer Options
4. Turn ON **USB Debugging**
5. Connect phone to computer with USB cable
6. On phone: tap **Allow** when asked to allow USB debugging

### Step 4: Build the App

```bash
# Open terminal / command prompt in the docscan_app folder

# Install dependencies
flutter pub get

# Build APK
flutter build apk --release
```

**Wait 3–5 minutes** for the build to complete.

### Step 5: Install APK on Your Phone

The APK will be at:
```
docscan_app/build/app/outputs/flutter-apk/app-release.apk
```

**Method 1 — USB (easiest):**
```bash
flutter install
```
This automatically installs the APK on your connected phone.

**Method 2 — File Transfer:**
1. Copy `app-release.apk` to your phone (via USB, email, Google Drive, etc.)
2. On your phone: Settings → Security → Enable **"Install unknown apps"**
3. Open the APK file on your phone and tap **Install**

---

## OPTION C: iOS Installation (Mac Only)

### Requirements
- Mac computer with Xcode 15+
- Apple Developer account (free or paid)
  - Free: Can install on your own device only (expires every 7 days)
  - Paid ($99/year): Can distribute and install indefinitely

### Steps

```bash
# 1. Install Xcode from Mac App Store
# 2. Install CocoaPods
sudo gem install cocoapods

# 3. In the project folder:
cd docscan_app
flutter pub get
cd ios && pod install && cd ..

# 4. Open in Xcode
open ios/Runner.xcworkspace

# 5. In Xcode:
#    - Select your Team (Apple ID) in Signing & Capabilities
#    - Connect iPhone via USB
#    - Select your iPhone as the target device
#    - Press the Play button (▶) to build and install
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `flutter: command not found` | Add Flutter to PATH, restart terminal |
| `No devices found` | Enable USB Debugging, try different USB cable |
| `Build failed: SDK not found` | Run `flutter doctor`, fix listed issues |
| `App install blocked` | Enable "Install unknown apps" in phone settings |
| `Gradle build failed` | Run `flutter clean` then `flutter pub get` again |
| `Pod install failed` (iOS) | Run `sudo gem install cocoapods` first |
| Phone says "Untrusted Developer" (iOS) | Settings → General → VPN & Device Management → Trust your Apple ID |

---

## Minimum Requirements

| Platform | Minimum |
|---|---|
| Android | Android 5.0 (API 21) or higher |
| iOS | iOS 13.0 or higher |
| RAM | 2 GB recommended |
| Storage | 50 MB for app + space for your scans |

---

## First Launch

1. Grant camera permission when asked
2. Grant photo library permission when asked
3. Complete the 3-screen onboarding
4. Tap the **Scan** button to scan your first document
5. Review, enhance, and export as PDF

---

## Note on ML Kit Scanner

The current build uses the device's standard camera/gallery picker.
For **automatic edge detection and perspective correction** (Adobe Scan quality),
follow the upgrade instructions in README.md to enable Google ML Kit Document Scanner.
This requires Google Play Services (standard on most Android phones;
not available on Huawei without GMS).
