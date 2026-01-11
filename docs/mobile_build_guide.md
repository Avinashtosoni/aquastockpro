# Mobile App Build Guide

Since we made changes to native Android configuration (permissions and file sharing settings), the app needs a **full rebuild**. Hot restart will not work.

## How to Apply Fixes

1.  **Stop the App**: Stop the currently running debug instance.
2.  **Clean Build Cache**:
    Run the following command in the terminal:
    ```bash
    flutter clean
    ```
3.  **Get Dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the App**:
    Connect your phone and run:
    ```bash
    flutter run
    ```
    *Or if you handle builds via APK:*
    ```bash
    flutter build apk --release
    ```

## What Was Fixed?
- **Crash on Share/WhatsApp**: Fixed by adding `FileProvider` configuration.
- **Offline PDF Generation**: Added fallback fonts so bills generate even without internet.
- **Permissions**: Added storage permissions for improved compatibility.
