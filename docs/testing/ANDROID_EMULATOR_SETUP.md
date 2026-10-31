# PulsePatch Lite — Android Emulator Setup & Testing Guide

## 1. Selected Emulator & Source Evaluation

### GitHub Candidate Evaluation
In accordance with project testing guidelines, available open-source and GitHub Android runtime/emulator candidates were systematically evaluated:
1. **Waydroid / Anbox (GitHub)**: Highly capable containerized Android runtimes, but strictly Linux-kernel dependent (requires `ashmem`, `binder` kernel drivers). Not natively runnable on Windows 11 without nested WSL2 virtualization, which introduces GPU emulation bottlenecks and eliminates ADB direct bridging.
2. **BlissOS / Android-x86 (GitHub / SourceForge)**: Full desktop OS images distributed as bootable `.iso` files for bare-metal or VirtualBox/VMware installation. Not designed as an automated developer CLI emulator with integrated ADB bridging, Flutter devtools support, or snapshot lifecycle controls.
3. **Official Google Android Emulator (Android SDK / Google Git)**: The industry-standard, fully accelerated Android development runtime. Provides official x86_64 system images with hardware virtualization (WHPX / Intel HAXM), automatic ADB bridging, direct Flutter device recognition, and deterministic lifecycle control.

**Selected Runtime**: Official Google Android Emulator (v36.6.11.0, build 15507667) via Android SDK cmdline-tools.

---

## 2. Configuration & Virtual Device Profiles

### Primary Virtual Device: Pixel_API34
- **AVD Name**: `Pixel_API34`
- **Device Profile**: Google Pixel
- **Android Version**: Android 14.0 (API Level 34)
- **ABI / Arch**: `x86_64`
- **System Image**: `system-images;android-34;google_apis_playstore;x86_64`
- **Physical Resolution**: `1080 × 1920` px
- **Density**: `420 dpi` (Logical width: `411 × 731` dp)
- **RAM Allocation**: `2048 MB` - `4096 MB`
- **Internal Storage**: `6144 MB`
- **Graphics Acceleration**: `Auto` / `Host OpenGL / GLES` via Intel UHD 620

### Host System Requirements Verified
- **OS**: Windows 11 Pro 64-bit (Build 26300)
- **CPU**: Intel Core i7-8550U (4 Cores, 8 Threads, Intel VT-x enabled)
- **RAM**: 16 GB Physical RAM
- **GPU**: Intel UHD Graphics 620 (WDDM 31.0.101.2141)
- **Available Storage**: >35 GB on Drive C:, >90 GB on Drive E:

---

## 3. Operational CLI Commands

### 3.1 Start the Emulator
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_API34 -gpu auto -netdelay none -netspeed full
```

### 3.2 Discover Device Identifier
```powershell
adb devices
# Expected output:
# List of devices attached
# emulator-5554    device
```

### 3.3 Verify with Flutter
```powershell
flutter devices
# Shows: sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 14 (API 34) (emulator)
```

### 3.4 Launch Application
```powershell
flutter run -d emulator-5554
```

### 3.5 Capture Screenshots
```powershell
adb -s emulator-5554 shell screencap -p /sdcard/screen.png
adb -s emulator-5554 pull /sdcard/screen.png <destination_path>
```

### 3.6 Restart or Terminate Emulator
```powershell
adb -s emulator-5554 emu kill
```

---

## 4. Hardware & Bluetooth Testing Boundaries

> [!IMPORTANT]
> The standard Android Emulator does not provide physical Bluetooth Low Energy hardware. 
> 
> - **Emulator Scope**: Used for comprehensive UI/UX layout verification, responsive audits (multi-resolution), typography scaling, Arabic RTL/English LTR fidelity, navigation transitions, real-time chart rendering via bounded buffers, offline SQLite persistence, and UI smoke testing.
> - **Bluetooth Simulation**: During emulator sessions, the application utilizes the built-in `SimulatorHeartRateSource` or controlled synthetic test data fixtures. Test data is explicitly flagged as test fixtures in all reporting and never conflated with human clinical truth.
> - **Physical BLE Hardware**: Physical BLE GATT communication (ESP32-C3 / MAX30102 / Mi Smart Band 5) requires a physical Bluetooth transceiver and is reported independently.
