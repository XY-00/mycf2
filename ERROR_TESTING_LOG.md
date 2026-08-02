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

---

## 8. Terminology Refactoring (Slot to Plant Nomenclature)
* **Issue**: The UI header displayed "Add Plant (Slot X)", which felt inappropriate and overly technical for end users.
* **Testing / Resolution**:
  * Updated the title string in `add_plant_screen.dart` from `'Add Plant (Slot ${widget.slotNumber})'` to `'Add Plant ${widget.slotNumber}'` for a cleaner, more intuitive user experience.

---

## 8. Plant List Identification Labeling (Plant 1, 2, 3)
* **Issue**: The plant profile list items lacked explicit numbering prefixes, making it difficult for users to distinguish between multiple active plants at a glance.
* **Testing / Resolution**:
  * Updated the title formatting string inside `_buildPlantList` in `plant_profile_screen.dart` from `'Plant: ${plant['name']}'` to `'Plant ${index + 1}: ${plant['name']}'`.
  * Ensured active and archived plant items clearly display their respective plant order index for improved usability and clarity.

---

## 9. Supabase Database Table Creation via SQL Migration Script
* **Issue**: Needed a programmatic and standardized way to provision the `plants` table in Supabase rather than relying solely on manual dashboard GUI configurations.
* **Testing / Resolution**:
  * Provided an explicit PostgreSQL script (`CREATE TABLE public.plants`) defining core attributes (`id`, `name`, `avatar`, `planted_date`, `status`, and `created_at`).
  * Enabled table policies to facilitate seamless testing and CRUD integration within the Flutter application.

---

## 10. State Preservation & Fixed Hardware Slot Binding
* **Issue 1**: Switching between bottom navigation tabs caused `PlantProfileScreen` to trigger `initState` repeatedly, resulting in unnecessary network loading delays.
* **Issue 2**: Plant numbering dynamically shifted upon deletion (e.g., deleting Plant 1 caused Plant 2 to become Plant 1), breaking the rigid mapping to physical soil moisture sensors and water pumps.
* **Testing / Resolution**:
  * Implemented `AutomaticKeepAliveClientMixin` with `wantKeepAlive = true` in `PlantProfileScreen` to cache screen state and eliminate reload latency during tab navigation.
  * Replaced index-based dynamic UI labeling with fixed database-backed slot/identifier tracking (`plant['id']` / `slot_number`), ensuring hardware bindings for sensors and pumps remain permanently locked to their respective plant slots regardless of deletions.

---

## 11. History Timeline Grouping & Terminology Refactoring
* **Issue**: The History tab lacked chronological categorization (by Year/Month), displayed redundant slot numbers, and included a delete button that was no longer required since users only wanted to view historical plant cards.
* **Testing / Resolution**:
  * Added an `action_type` field in Supabase to differentiate between `harvest` (Complete) and `delete` actions.
  * Rebuilt the History UI into an album-style hierarchical timeline grouped by `Year` and `Month` based on the `archived_at` timestamp.
  * Removed slot prefix numbering in History items, displaying solely the clean plant name alongside its specific lifecycle outcome label (`Complete` or `Delete`).
  * Removed the inline delete action button and enabled click-to-view navigation for historical plant cards.

---

## 12. Lifecycle Outcome Terminology Refactoring (Harvest to Complete)
* **Issue**: The terminology for successfully finished plants was inconsistently labeled as `harvest`, which did not match the user's explicit requirement of displaying `Complete`.
* **Testing / Resolution**:
  * Refactored all internal action identifiers and default values from `harvest` to `complete` across `plant_profile_screen.dart`.
  * Provided a SQL migration snippet to update legacy database rows, ensuring historical records accurately display the `Complete` status alongside `Delete`.

---

## 13. Modularization, Code Localization Purge & Detailed History Timeline
* **Issue**: The codebase contained mixed Chinese characters, and the History feature required structural isolation into a separate file (`plant_history_screen.dart`), explicit day-level date hierarchy in addition to year/month, and read-only detail views without active management action buttons.
* **Testing / Resolution**:
  * Purged all Chinese comments and strings from code files to maintain professional software standards.
  * Extracted the History timeline logic into `plant_history_screen.dart`, organizing archived records hierarchically by Year, Month, and specific Date.
  * Refactored `PlantDetailsScreen` with an `isHistoryView` parameter to cleanly hide the Edit, Complete, and Delete action buttons when viewing archived items.

---

## 14. History Descending Chronological Fix, UI Refactoring & Soft Green Theme
* **Issue**: The History timeline lacked strict reverse-chronological ordering (newest items showing at the top), and the Plant Details screen required a cleaner card background style using a very soft, soothing green tone instead of pure white or previous legacy colors.
* **Testing / Resolution**:
  * Implemented strict descending sort algorithms combined with database queries ordered by `archived_at` to ensure the most recently archived or deleted records permanently anchor to the top of the History list.
  * Extracted and refined the month-grouping and layout logic inside `plant_history_screen.dart` to maintain clean separation of concerns and remove redundant date strings.
  * Updated `PlantDetailsScreen` cards to utilize a gentle, eye-friendly very light green tint (`Color(0xFFF0F5F1)`), and adjusted the Growth History gallery header layout to wrap titles cleanly without overflow errors.

---

## 15. Precise Archival Date-Grouping, Date Validation & Avatar Fallback Fixes
* **Issue**: The History timeline grouped items too broadly by month rather than tracking their exact completion or deletion dates. Additionally, manual date inputs in `AddPlantScreen` lacked strict format validation (allowing impossible calendar days/months like "60"), history detail avatars defaulted incorrectly to sapling icons instead of custom or default emojis, and recent database resets required reliable test data replenishment.
* **Testing / Resolution**:
  * Refactored `plant_history_screen.dart` to implement a multi-level chronological grouping algorithm (Year $\rightarrow$ Month $\rightarrow$ Exact Day) based precisely on the `archived_at` timestamp, ensuring history items cleanly break down by exact completion/deletion dates (e.g., 3 July 2026, 15 July 2026).
  * Enhanced `AddPlantScreen` date-parsing and validation logic with an explicit `_parseAndValidateDate` method, introducing a reactive red inline error text (`Invalid date`) directly beneath the field to block invalid inputs and future dates.
  * Updated `HistoryPlantDetailsScreen` to accurately check avatar strings and properly render custom emojis or file paths instead of forcing default sapling graphics.
  * Populated Supabase with clean July test records across Active and History states using explicit user naming (`LEE XIN YI`) to restore full application functionality and continuity.

---

## 16. UI/UX Refinement for Analytic Dashboard Cards & Moisture Chart Calibration
* **Issue**: The `AnalyticScreen` dashboard suffered from poor visual hierarchy and color blending across the Visual Health Validation and Carbon Protection modules, reducing card legibility. Additionally, the moisture trend chart required precise 24-hour hourly increments (00 to 23), full monthly daily sequences (1 to 31), strict historical date boundaries (preventing future date selection), and precise data-point tooltip adsorption tied directly to active plant filters.
* **Testing / Resolution**:
  * Restructured `analytic_screen.dart` with clean white primary container cards (`Colors.white`) paired with soft, distinct inner background shades (`Color(0xFFF2F6F0)`) and subtle borders to eliminate color mixing and enhance readability.
  * Refactored `moisture_chart_card.dart` and `MultiPlantTrendPainter` to render exact chronological X-axis labels (hourly `00`–`23` for Daily, daily `1`–`31` for Monthly) without skipping intervals.
  * Integrated interactive touch-adsorption and tap handlers in `MoistureChartCard` to dynamically snap to and highlight exact plant-specific moisture data points with custom tooltips.
  * Updated historical date-picking logic to cap selections precisely at the current date (`DateTime.now()`), completely disabling future date selection while maintaining historical lookup capabilities.

---

## 17. Comprehensive UI/UX & Chart Calibration Testing and Resolution Log
* **Issue**: Multiple compilation, layout, and functional discrepancies occurred during development:
  1. *MoistureChartCard Compilation*: Unmatched parentheses/brackets (`(` / `)` / `]`) and `Column` parameter conflicts caused build errors.
  2. *Granularity Mismatch*: Daily view skipped hourly increments (showing every 3 hours), while Monthly view used non-contiguous localized date points instead of full sequential English day sequences (`1`–`31`).
  3. *Calendar Boundary Restrictions*: Hardcoded date limits prevented historical lookups prior to 2025 (e.g., 2023/2024), while failing to properly restrict future dates in certain pickers.
  4. *Visual Hierarchy Flaws*: The `AnalyticScreen` dashboard suffered from poor color blending and low contrast between primary containers and inner cards.
* **Testing / Resolution**:
  * Cleaned and normalized component tree nesting in `moisture_chart_card.dart`, enforcing strict bracket closure and fixed container height constraints (`height: 240`) to resolve compilation errors and layout collapse.
  * Rewrote `_getXLabels` and `_processDataForMode` logic in `MoistureChartCard` to map continuous 24-hour hourly points (`00`–`23`) for Daily mode and exact full-month sequences (`1`–`31`) for Monthly mode.
  * Expanded the calendar picker historical range (`2020`–`2030`) while strictly capping the maximum selectable date to `DateTime.now()` to disable future selections and enable full historical accessibility.
  * Standardized `analytic_screen.dart` with clean white primary cards (`Colors.white`) paired with distinct, soft inner card backgrounds (`Color(0xFFF2F6F0)`) and delicate borders to maximize legibility and achieve a clean, modern aesthetic.