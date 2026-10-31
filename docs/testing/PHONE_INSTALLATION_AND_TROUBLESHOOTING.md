# PulsePatch Lite — Physical Android Phone Installation & Troubleshooting Guide

**Document Identification:** GDE-PHONE-INSTALL-V2.1  
**Target Package:** `com.pulsepatch.lite.app`  
**Distribution Model:** Local Sideload / USB ADB Debugging / Direct APK Install  
**Date:** 2026-10-31  

---

## 1. Prerequisites & Phone Setup

### 1.1 Enable Developer Options
1. Open phone **Settings** > **About Phone**.
2. Locate **Build Number** (on HONOR/EMUI/MagicOS, tap "Build number" 7 times).
3. Enter device PIN/passcode when prompted until the toast reads: *"You are now in Developer mode!"*.

### 1.2 Enable USB Debugging
1. Go to **Settings** > **System & Updates** > **Developer Options**.
2. Toggle **USB Debugging** to `ON`.
3. (Optional but recommended on Xiaomi/Huawei/Honor): Enable **Install via USB** and disable "Verify apps over USB" for sideload testing.

### 1.3 Authorize Host Computer
1. Connect phone to the PC using a USB-C data cable (ensure it is a data cable, not charge-only).
2. Select **File Transfer / MTP** in the USB mode prompt on the phone.
3. On the phone screen, an authorization dialog will appear:
   - *"Allow USB debugging from this computer?"*
   - Check **"Always allow from this computer"** and tap **Allow**.

### 1.4 Verify Connection via Terminal
```bash
adb devices -l
```
Expected output:
```
List of devices attached
A9VUCP5A08407069       device product:NIC-LX2 model:NIC_LX2 device:HNNIC-M1 transport_id:2
```
If the status shows `unauthorized`, unlock the phone screen and tap **Allow** on the prompt. If `offline`, reconnect the USB cable.

---

## 2. Installing the Production Release APK

### 2.1 Standard Sideload / Reinstall
To install the verified release APK without wiping existing user sessions or local SQLite health records:
```bash
adb -s <DEVICE_SERIAL> install -r "e:\pulse patch\app\build\app\outputs\flutter-apk\app-release.apk"
```
For our verified Honor phone:
```bash
adb -s A9VUCP5A08407069 install -r "e:\pulse patch\app\build\app\outputs\flutter-apk\app-release.apk"
```
Successful output:
```
Performing Streamed Install
Success
```

### 2.2 Launching the Application
```bash
adb -s A9VUCP5A08407069 shell am start -n com.pulsepatch.lite.app/.MainActivity
```

### 2.3 Inspecting Active Process & Logs
```bash
adb -s A9VUCP5A08407069 shell "pidof com.pulsepatch.lite.app"
adb -s A9VUCP5A08407069 logcat --pid=$(adb -s A9VUCP5A08407069 shell pidof com.pulsepatch.lite.app)
```

---

## 3. App Check Considerations for Sideloaded APKs

When distributing PulsePatch Lite outside of Google Play (e.g. direct APK sideload or internal testing):
1. **Play Integrity vs Debug Provider:**
   - The production APK uses `AndroidPlayIntegrityProvider()`. If sideloaded on a device without Google Play Licensing recognition, Play Integrity calls will return an untrusted verdict.
   - **PulsePatch Resilience:** Cloud AI requests gracefully degrade to the on-device **Local Medical RAG** engine. All local features (BLE streaming, signal processing, PDF export, SQLite history) function **100% unimpeded** without App Check tokens.
2. **Testing Cloud AI via Debug Provider:**
   - For internal developer validation of cloud features without Play Store publication, build with `kDebugMode` or register the device debug token in the Firebase Console:
     ```
     Firebase Console > App Check > Apps > Android > Debug Tokens
     ```

---

## 4. Runtime Permissions Guide (Android 12 to 15)

PulsePatch Lite requires the following permissions for BLE sensor connectivity and local health alerts:

| Permission | Android Level | Purpose | User Prompt Behavior |
|---|---|---|---|
| `BLUETOOTH_SCAN` | Android 12+ (API 31+) | Discover nearby PulsePatch ESP32-C3 peripherals | Prompted on tapping "Start Scan" with `neverForLocation` flag |
| `BLUETOOTH_CONNECT` | Android 12+ (API 31+) | Connect to GATT server and subscribe to 12-byte telemetry | Prompted on tapping "Connect" |
| `ACCESS_FINE_LOCATION` | Android 6–11 (API 23–30) | Required by legacy Android for BLE scanning | Handled transparently by `permission_handler` |
| `POST_NOTIFICATIONS` | Android 13+ (API 33+) | Deliver abnormal HR alerts or measurement complete notifications | Prompted on first measurement launch |

To manually grant all permissions via ADB for automated test rigs:
```bash
adb -s A9VUCP5A08407069 shell pm grant com.pulsepatch.lite.app android.permission.BLUETOOTH_SCAN
adb -s A9VUCP5A08407069 shell pm grant com.pulsepatch.lite.app android.permission.BLUETOOTH_CONNECT
adb -s A9VUCP5A08407069 shell pm grant com.pulsepatch.lite.app android.permission.ACCESS_FINE_LOCATION
adb -s A9VUCP5A08407069 shell pm grant com.pulsepatch.lite.app android.permission.POST_NOTIFICATIONS
```

---

## 5. Common Installation & Runtime Troubleshooting

### Issue 1: `INSTALL_FAILED_UPDATE_INCOMPATIBLE`
- **Cause:** A previous debug or release build with a different signing key exists on the device.
- **Solution:** Backup local records if needed, then perform a clean reinstall:
  ```bash
  adb -s <SERIAL> uninstall com.pulsepatch.lite.app
  adb -s <SERIAL> install "app-release.apk"
  ```

### Issue 2: `INSTALL_FAILED_INSUFFICIENT_STORAGE`
- **Cause:** Device `/data` partition has less than 200 MB free storage.
- **Solution:** Check available space using `adb shell df -h /data` and clear cached files.

### Issue 3: `INSTALL_PARSE_FAILED_NO_CERTIFICATES`
- **Cause:** APK signing block corrupted or missing v2 signature scheme.
- **Solution:** Re-verify with `apksigner verify --verbose "app-release.apk"`. Our build uses APK Signature Scheme v2.

### Issue 4: OpenStreetMap Tiles Not Loading
- **Cause:** Device has no active Wi-Fi or cellular data, or tile server is unreachable.
- **Solution:** Ensure device internet connectivity is active. PulsePatch automatically falls back to curated local healthcare facilities when network is absent.

### Issue 5: Bluetooth Scanning Finds No Devices
- **Cause:** ESP32-C3 peripheral is unpowered, not advertising, or phone Bluetooth is disabled.
- **Solution:**
  1. Confirm phone Bluetooth is enabled in Quick Settings.
  2. Verify ESP32-C3 serial monitor outputs: `[INFO] BLE Advertising started as 'PulsePatch Lite'`.
  3. Ensure device distance is within 5 meters.
