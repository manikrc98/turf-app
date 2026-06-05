# TURF Cross-Platform App 🏆

This is the cross-platform version of the **TURF** application, built using **Flutter** to support both **Android** and **iOS** from a single codebase.

---

## 📂 Project Structure

The codebase is organized as follows:
*   `lib/models/`: Encapsulates all data structures (`TurfLoop`, `ClaimedLoop`, `WalkSessionSummary`, `TurfSessionState`, `SessionStatus`).
*   `lib/repositories/`: Implements JSON-file-based persistent storage (`HistoryRepository` and `ClaimedLoopRepository`), retaining 100% backward compatibility with the legacy native Android schema.
*   `lib/location/`: Contains the core mathematical loop detection logic (`LoopDetector`).
*   `lib/sensors/`: Integrates device hardware sensor streams (`StepCounterManager` and `CompassManager`).
*   `lib/providers/`: Manages live tracking state, GPS coordinates collection, haptic feedback, and data serialization (`TurfSessionProvider`).
*   `lib/screens/`: Contains UI files (`MapScreen`, `HistoryBottomSheet`, `SummaryBottomSheet`, and `MarkerGenerator` for canvas drawing of dynamic map cards).
*   `test/`: Houses mathematical unit tests for loop closure checks.

---

## ⚙️ Platform Permissions Configuration

To enable high-accuracy location tracking and physical step counting, you must add the following configuration permissions to the respective native folders:

### 🤖 Android Setup (`android/app/src/main/AndroidManifest.xml`)

Ensure the following permissions and features are declared in your manifest:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- GPS & Location Permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- Foreground Service (Android 9+) & Service Type (Android 10+) -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

    <!-- Step Counter Sensors & Haptics -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    <uses-permission android:name="android.permission.VIBRATE" />
    
    <uses-feature android:name="android.hardware.sensor.stepcounter" android:required="false" />

    <application ...>
        <!-- Google Maps API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="AIzaSyCTd5Kqot24CcIFGvuTyMxsrHb6V6ekxBA" />
            
        <!-- Background Service Runner -->
        <service
            android:name="com.pravera.flutter_background_service.BackgroundService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="location" />
    </application>
</manifest>
```

### 🍎 iOS Setup (`ios/Runner/Info.plist` & Xcode Target)

1. Open `ios/Runner/Info.plist` and add the following keys to declare usage purposes:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>TURF needs location access to map your active walking path in real time.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>TURF needs constant location tracking in the background to calculate completed loops even when the app is minimized.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>TURF requires background location access to verify completed loops during walks.</string>
<key>NSMotionUsageDescription</key>
<string>TURF requires access to your physical activity sensor (CoreMotion pedometer) to count your walk steps.</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>processing</string>
</array>
```

2. Open the project in Xcode, click on the **Runner** target, navigate to **Signing & Capabilities**, click **+ Capability**, and add **Background Modes**. Check the **Location updates** option.
3. Configure the Google Maps API Key in `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import GoogleMaps // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCTd5Kqot24CcIFGvuTyMxsrHb6V6ekxBA") // Configure key
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🚀 Running the Project

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run the mathematical unit tests:
   ```bash
   flutter test
   ```
3. Run the app on a connected physical device or simulator:
   ```bash
   flutter run
   ```
   *(Note: Since step counters, compasses, and background tracking cycles require physical hardware sensors, it is highly recommended to debug and test on a **physical iOS or Android device**).*
