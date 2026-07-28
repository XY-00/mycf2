# myCF - Error Testing & Bug Fixing Documentation

This document records the error testing, debugging processes, and resolutions encountered during the development of the **myCF** application.

---

## 1. UI Layout & Typography Adjustments
* **Issue**: The text style for "Plant Name" inside the Plant Details card was defaulting to an unwanted italic style, making it inconsistent with the "Age" section.
* **Testing / Resolution**: 
  * Inspected the `TextStyle` properties in `plant_details_screen.dart`.
  * Explicitly set `fontStyle: FontStyle.normal` and standardized the font weights and icon alignment to match the layout of the age indicator.

---

## 2. Android Native Splash Screen & Dark Mode Background Fix
* **Issue**: When launching the app on an Android device, the native splash screen displayed a black background (especially noticeable or forced when the phone system was in Dark Mode), creating a jarring visual contrast before the Flutter engine loaded.
* **Testing / Resolution**:
  * Identified that Android handles pre-loading windows via native resource themes in `android/app/src/main/res/values/styles.xml` and `android/app/src/main/res/values-night/styles.xml`.
  * Updated both default and `values-night` configurations to override the `LaunchTheme` and `NormalTheme` window backgrounds, forcing them to `@android:color/white` instead of following system dark styles:
    ```xml
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@android:color/white</item>
    </style>
    ```
  * Enforced light mode globally in `main.dart` using `themeMode: ThemeMode.light` and identical light `darkTheme` settings.

---

## 3. iOS Icon Generation Path Error on Windows Development Environment
* **Issue**: Running `flutter pub run flutter_launcher_icons` on a Windows host machine threw a `PathNotFoundException` because it attempted to locate the default iOS asset bundle path (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`).
* **Testing / Resolution**:
  * Modified the `flutter_launcher_icons` configuration block in `pubspec.yaml` to explicitly disable iOS target generation since the current target build environment is Android/Windows:
    ```yaml
    flutter_launcher_icons:
      image_path: "assets/app_logo.png"
      android: true
      ios: false
      background_color: "#FFFFFF"
      adaptive_icon_background: "#FFFFFF"
    ```

---

## 4. Widget Naming and Navigation Refactoring (`AddPlantDialog` to `AddPlantScreen`)
* **Issue**: Transitioning the plant creation interface from a popup dialog (`AlertDialog`) to a full-screen dedicated view (`Scaffold`) caused compilation errors due to mismatched class references in `plant_profile_screen.dart`.
* **Testing / Resolution**:
  * Renamed the widget class from `AddPlantDialog` to `AddPlantScreen` in `add_plant_screen.dart`.
  * Replaced `showDialog` invocations in `plant_profile_screen.dart` with standard `Navigator.push` to properly handle full-screen route transitions and callback parameters.
  * Cleaned up minor typos (e.g., correcting `black8ates` to `Colors.black87`).

---

## 5. Add Plant Form Refactoring & Auto-Formatting Date Input
* **Issue 1**: The plant creation form required unnecessary fields (`Plant Strain` and `Plant Growth`) that needed to be removed to match the finalized UI design.
* **Issue 2**: Users had to manually type slashes (`/`) when entering dates, which was prone to formatting errors.
* **Testing / Resolution**:
  * Removed `_strainController` and `_growthController` from `add_plant_screen.dart`.
  * Implemented a custom `TextInputFormatter` (`DateInputFormatter`) extending `TextInputFormatter` to override `formatEditUpdate`, automatically inserting `/` at correct positions (`DD/MM/YYYY`) as digits are typed.
  * Retained the calendar popup picker for flexible alternative date selection.

---

## 6. Extended Date History Range (50-Year Span)
* **Issue**: The date selection restriction (starting from year 2020) was too restrictive for users wishing to record older historical plant logs.
* **Testing / Resolution**:
  * Updated both the `showDatePicker` dialog (`firstDate`) and manual input validation bounds in `add_plant_screen.dart` to dynamically calculate `DateTime(now.year - 50, now.month, now.day)`.
  * Enabled users to select or manually type plant creation dates up to 50 years in the past while maintaining the future-date restriction (`DateTime.now()`).

---

## 7. Keyboard Inset Background Shift Bug Fix
* **Issue**: When the soft keyboard popped up on the `AddPlantScreen`, the entire screen layout compressed and shifted the background image upwards.
* **Testing / Resolution**:
  * Set `resizeToAvoidBottomInset: false` on the `Scaffold` to prevent global layout resizing.
  * Wrapped the background `Image.asset` in a `Positioned.fill` inside an outer `Stack` so it remains anchored to the screen bounds.
  * Applied `viewInsets.bottom` padding directly to the scrollable content area, ensuring input fields smoothly avoid the keyboard while the background stays completely locked in place.

