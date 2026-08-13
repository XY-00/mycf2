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

## 18. Setting Screen Hardware Status Desynchronization Fix
* **Issue**: When the Raspberry Pi was powered off, the global backend correctly detected the disconnection, but the `SettingScreen` UI failed to reflect the change, remaining stuck on the "Connected" status.
* **Testing / Resolution**: 
  * Identified that `SettingScreen` was missing a registered state-update callback for `HardwareStatusManager.startMonitoring()`, causing its local UI state to remain desynchronized from the global connection flag.
  * Added `HardwareStatusManager.startMonitoring(() { if (mounted) setState(() {}); });` inside the `initState` of `SettingScreen`, ensuring real-time UI synchronization whenever the hardware status changes.

## 19. Setting Screen Real-Time Hardware Status Desynchronization Fix
* **Issue**: When the Raspberry Pi was powered off, the `SettingScreen` UI remained stuck on "Connected" and only updated to "Unconnected" when navigating away and back to the settings tab.
* **Testing / Resolution**: 
  * Identified that while global monitoring was active, the UI render tree in `SettingScreen` lacked an active state-invalidation trigger linked to the background polling loop.
  * Ensured `HardwareStatusManager.startMonitoring(() { if (mounted) setState(() {}); });` was correctly bound within the `initState` of `SettingScreen`, forcing real-time UI re-renders every 3 seconds as status updates occurred.

## 20. Real-Time Hardware Status Listener Decoupling & UI Synchronization Fix
* **Issue**: When staying on the `SettingScreen`, powering on or off the Raspberry Pi did not trigger real-time UI updates (Connected <-> Unconnected), requiring manual page navigation to force a rebuild.
* **Testing / Resolution**: 
  * Identified that `HardwareStatusManager.startMonitoring` contained strict initialization guards (`_isInitialized`) which blocked secondary screen registrations when called from `SettingScreen`.
  * Decoupled the central polling timer from individual screen updates by introducing a subscriber pattern (`_listeners` list, `addListener`, and `removeListener`) inside `HardwareStatusManager`.
  * Updated `SettingScreen` to register its local `setState` callback using `HardwareStatusManager.addListener` during `initState` and clean it up via `removeListener` during `dispose`, achieving seamless, real-time UI synchronization across state changes without page switching.

## 21. Hardware Reconnection Delay Analysis & Boot-Up Latency
* **Issue**: When powering on the Raspberry Pi, the "Connected" notification took significantly longer (around 30 seconds) compared to the rapid disconnection warning (~6 seconds).
* **Testing / Resolution**: 
  * Analyzed the hardware lifecycle and cloud synchronization flow. Confirmed that the delayed reconnection response is caused by the physical boot-up time, operating system initialization, and Wi-Fi reconnection sequence of the Raspberry Pi before it can successfully write a fresh heartbeat timestamp (`last_seen`) to the Supabase database.

## 22. Database Row Level Security (RLS) Configuration for IoT Hardware Ingestion
* **Issue**: Clarification was needed regarding whether Supabase RLS must be disabled (`RLS disabled`) for external IoT devices like the Raspberry Pi to successfully write DHT11 sensor logs without user authentication context.
* **Testing / Resolution**: 
  * Analyzed Supabase access control mechanisms for headless IoT hardware scripts lacking user tokens (`auth.uid()`).
  * Confirmed that maintaining `RLS disabled` on ingestion tables (`dht11_logs`) simplifies hardware data insertion for academic project prototypes, while alternative secure implementations require explicit table policies.
  * Established the standard Python-to-Supabase insertion workflow using the `supabase-py` client library to continuously sync real-time temperature and humidity metrics.

## 23. Defense Preparation: RLS Justification for IoT Data Ingestion
* **Issue**: Prepared a formal academic explanation for the project defense panel regarding the security and architectural rationale for disabling Row Level Security (RLS) on IoT sensor logging tables.
* **Testing / Resolution**: 
  * Formulated a structured defense response addressing headless IoT device limitations, lack of user session tokens, real-time data flow requirements for environmental monitoring, and prospective production-level hardening strategies (such as API gateway tokens or service roles).

## 24. Raspberry Pi DHT11 Sensor Ingestion Script Implementation
* **Issue**: Developed a dedicated Python background script to continuously read temperature and humidity metrics from the DHT11 sensor on the Raspberry Pi and insert them into the cloud `dht11_logs` table.
* **Testing / Resolution**: 
  * Integrated the `Adafruit_DHT` sensor library with the `supabase-py` client.
  * Implemented an infinite polling loop with 10-second intervals and built-in exception handling to ensure continuous, resilient data synchronization from the edge hardware to Supabase.

## 25. Unicode Encoding Error During File Save (`\udcb0` Surrogate)
* **Issue**: Clicking save in the Thonny IDE triggered a `UnicodeEncodeError` (`'utf-8' codec can't encode character '\udcb0'`), crashing the file saving handler due to unrecognized surrogate characters present in the editor content buffer.
* **Testing / Resolution**: 
  * Analyzed the traceback pointing to `codeview.py` during byte-encoding conversion.
  * Determined that invalid or corrupted character encodings (often introduced via copy-pasting from external sources) caused the UTF-8 encoder to reject the byte stream.
  * Resolved by isolating and removing the corrupted character/snippet from the source file and transferring clean text into a newly created editor instance.

## 26. Externally Managed Environment Error (`PEP 668`) During Pip Installation
* **Issue**: Executing `pip install supabase Adafruit_DHT` on the Raspberry Pi terminal triggered an `externally-managed-environment` error (`PEP 668`), preventing global package installation to protect system stability.
* **Testing / Resolution**: 
  * Analyzed the Linux distribution package management protection policy for system-wide Python environments.
  * Resolved the restriction by either establishing an isolated Python virtual environment (`python3 -m venv`) or utilizing the system override flag (`--break-system-packages`) for rapid prototype deployment.

## 27. Architectural Rationale for Python Virtual Environments (`venv`)
* **Issue**: Addressed conceptual questions regarding why isolated Python virtual environments (`venv`) are mandatory for IoT hardware scripts on Linux distributions.
* **Testing / Resolution**: 
  * Documented the core benefits of virtual environments: bypassing system-level PEP 668 package protection blocks, preventing cross-project dependency and version conflicts, and ensuring reliable software reproducibility across different deployment targets.

## 28. Deprecated Adafruit_DHT Wheel Build Failure and Migration to CircuitPython
* **Issue**: Installing the legacy `Adafruit_DHT` package via `pip` failed during the wheel building phase with `subprocess-exited-with-error` and `Could not detect if running on the Raspberry Pi or Beaglebone Black`, caused by incompatibility with modern Python versions (Python 3.13) and updated Linux kernel environments.
* **Testing / Resolution**: 
  * Identified that the original `Adafruit_Python_DHT` repository has been officially archived and deprecated by Adafruit in favor of CircuitPython libraries.
  * Resolved the build failure by abandoning the legacy package and migrating to the modern `adafruit-circuitpython-dht` and `board` libraries within the isolated virtual environment.
  * Refactored the Python ingestion script to utilize the `adafruit_dht.DHT11(board.D4)` interface with built-in `RuntimeError` tolerance for stable continuous logging.

## 29. Missing `swig` Build Dependency Error for `lgpio` Package
* **Issue**: Installing `adafruit-circuitpython-dht` (along with its Blinka hardware dependencies) failed during wheel building for `lgpio` with `error: command 'swig' failed: No such file or directory`.
* **Testing / Resolution**: 
  * Analyzed the compilation logs indicating that the SWIG (Simplified Wrapper and Interface Generator) tool and Python development headers were missing from the host environment, preventing C-extension wrapping.
  * Resolved by installing the required system packages via APT (`sudo apt install -y swig python3-dev`) and re-running the pip installation within the active virtual environment.
  
## 30. Missing System `lgpio` C Library Linker Error (`-llgpio`)
* **Issue**: Even after installing SWIG, the Python package installation failed during the `lgpio` wheel building phase with `/usr/bin/ld: cannot find -llgpio: No such file or directory`, indicating that the underlying C shared library was absent from the Linux system paths.
* **Testing / Resolution**: 
  * Analyzed the GCC linker error showing the missing `-llgpio` dependency required by the Python wrapper.
  * Resolved by installing the C development package via APT (`sudo apt install -y liblgpio-dev`) and re-executing the pip installation in the virtual environment.

## 31. Module Not Found Error for Legacy `Adafruit_DHT` Library
* **Issue**: Running `dht11_uploader.py` triggered a `ModuleNotFoundError: No module named 'Adafruit_DHT'` because the script still attempted to import the legacy package instead of the newly installed CircuitPython drivers.
* **Testing / Resolution**: 
  * Identified code-level dependency mismatch resulting from earlier package migrations.
  * Resolved by fully updating the script imports to use `board` and `adafruit_dht` (`adafruit_dht.DHT11(board.D4)`), aligning the script with the newly compiled virtual environment dependencies.

## 32. Finalized CircuitPython DHT11 Inscription Script Integration
* **Issue**: The user's script contained legacy `Adafruit_DHT` imports and configuration structures, causing execution halts after migrating to the modern CircuitPython-based virtual environment.
* **Testing / Resolution**: 
  * Replaced the script base with the integrated `board.D4` and `adafruit_dht.DHT11` initialization sequence.
  * Embedded robust `RuntimeError` exception handling to manage common hardware sensor timeout glitches without terminating the main synchronization loop.

## 33. Module Not Found Error for `board` Package Due to Global Interpreter Execution
* **Issue**: Executing `dht11_uploader.py` triggered a `ModuleNotFoundError: No module named 'board'` because the script was executed via the system's global Python interpreter rather than the isolated virtual environment where CircuitPython dependencies were installed.
* **Testing / Resolution**: 
  * Identified the environment desynchronization between the terminal execution context and the project's virtual environment.
  * Resolved by explicitly sourcing the virtual environment (`source venv/bin/activate`) prior to script execution or re-configuring the Thonny IDE interpreter path to point directly to the project's `venv/bin/python3` binary.

## 34. GPIO Line Initialization Error (`unable to set line to input`)
* **Issue**: Running the Python sensor script raised a hardware-level `RuntimeError` stating `unable to set line 4 to input` due to lack of administrative permissions or resource conflicts on the Raspberry Pi GPIO pins.
* **Testing / Resolution**: 
  * Analyzed the underlying Linux hardware access constraints for user-space GPIO operations.
  * Resolved by executing the script via administrative privileges (`sudo venv/bin/python`) or by granting permanent user permissions via group additions (`sudo usermod -a -G gpio,i2c,spi,dialout`) followed by a system reboot.

## 35. GPIO Line Initialization Conflict & Migration to GPIO 17
* **Issue**: Encountered persistent `Unable to set line 4 to input` and `sysv_ipc.Error` issues because GPIO 4 was pre-allocated or conflicted with the Raspberry Pi system's internal OneWire/hardware bus services.
* **Testing / Resolution**: 
  * Re-routed the DHT11 sensor data wire from physical Pin 7 (GPIO 4) to physical Pin 11 (GPIO 17), a clean general-purpose I/O pin free from background system reservations.
  * Updated the Python script initialization string to `adafruit_dht.DHT11(board.D17)`.
  * Executed the script via the elevated virtual environment runtime (`sudo venv/bin/python`), successfully resolving hardware permission locks and enabling stable, real-time 3-second data synchronization to Supabase.

## 36. GPIO 4 Resource Lifecycle & Supabase Authentication Debugging Log
* **Issue 1 (Hardware/Driver Lock)**: Encountered recurring `Unable to set line 4 to input` errors when restarting or interrupting scripts via `Ctrl + C`, caused by leftover kernel-level file descriptor states in the `lgpio` driver.
  * **Testing & Resolution**: Implemented a self-healing pre-initialization cleanup routine using `lgpio.gpiochip_open(0)` and `lgpio.gpio_free(chip, 4)` at the entry point of the script, paired with a robust `KeyboardInterrupt` exception handler to ensure hardware resources are cleanly released upon exit.
* **Issue 2 (Cloud Synchronization Auth)**: Raised a `postgrest.exceptions.APIError` (HTTP 401: `Invalid API key`) during data insertion to Supabase.
  * **Testing & Resolution**: Verified and refreshed the project's public `anon` API key within the Supabase dashboard, ensuring the full JWT token string was correctly assigned to `SUPABASE_KEY`, which successfully restored authenticated real-time data uploads.

