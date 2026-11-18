<div align="center">
  <img src="assets/images/logo.png" alt="NOrange Logo" width="120" height="120" />

  # NOrange

  **OpenVPN Client, Hotspot Gateway, HTTP/SOCKS5 Proxy Server and Network Utilities for Android.**

  Developed by **[Diego Oris](https://diegooris.ch)**  
  [diegooris.ch](https://diegooris.ch) · [LinkedIn](https://br.linkedin.com/in/diegoorisderoa) · [Releases](./releases)

  [![Platform](https://img.shields.io/badge/Platform-Android-orange.svg)](https://flutter.dev)
  [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev)
  [![OpenVPN](https://img.shields.io/badge/Tunnel-OpenVPN%202.x-EA6000.svg)](https://openvpn.net)

  <p>
    <a href="README.md">🇧🇷 Português</a> •
    <b>🇺🇸 English</b> •
    <a href="README.es.md">🇪🇸 Español</a> •
    <a href="README.ru.md">🇷🇺 Русский</a>
  </p>
</div>

---

## 📦 Downloads (Release APKs)

Compiled binaries available in the [`releases/`](./releases) directory and on the [**GitHub Releases**](../../releases) page:

| APK File | Architecture | Target |
| :--- | :--- | :--- |
| [**`NOrange-universal-release.apk`**](./releases/NOrange-universal-release.apk) | Universal (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | Compatible with any Android device or emulator |
| [**`NOrange-arm64-v8a-release.apk`**](./releases/NOrange-arm64-v8a-release.apk) | `arm64-v8a` (64-bit) | Modern Android devices (Snapdragon, Dimensity, Exynos) |
| [**`NOrange-armeabi-v7a-release.apk`**](./releases/NOrange-armeabi-v7a-release.apk) | `armeabi-v7a` (32-bit) | Legacy 32-bit Android devices |
| [**`NOrange-x86_64-release.apk`**](./releases/NOrange-x86_64-release.apk) | `x86_64` | Android emulators (AVD, Android Studio, PC) |

---

## ⚙️ Features

### 1. OpenVPN Client & Public Nodes
- Global pool with over 50 public OpenVPN servers (Americas, Europe, Asia, and Oceania) powered by VPNGate.
- Real-time telemetry per server: latency (ping), reported bandwidth, active sessions, remote IP, and protocol (TCP/UDP).
- Custom `.ovpn` configuration file imports and manual profile credentials (Host, Port, User/Password).
- Built-in DNS presets (Cloudflare `1.1.1.1`, Google `8.8.8.8`, AdGuard) with leak protection.
- Automatic failover reconnection and native Kill Switch support.

### 2. Hotspot VPN & Local Proxy Server
- **VPN Tethering:** Share encrypted VPN tunnel traffic over a local Wi-Fi Hotspot to other devices on the LAN.
- **Embedded HTTP & SOCKS5 Proxy Server:** Runs a local proxy directly on Android with configurable port and optional credentials (RFC 1929 / Basic Auth).
- **Active Connections Monitor:** Real-time visibility of connected clients, remote hosts, bandwidth consumption (upload/download), and live access logs.
- **Interface Isolation:** Conflict prevention between VPN client mode, hotspot gateway, and proxy server routines.

### 3. Network Monitoring & Socket Inspection
- **Active Socket Inspection:** Queries `/proc/net/tcp` and `/proc/net/tcp6` to track active sockets per package name and process UID.
- **Background Connection Alerts:** Identifies persistent outbound connections opened on non-standard ports by background applications.
- **Wi-Fi Signal Analysis (FSPL):** Calculates estimated free-space path loss and approximate distance from RSSI (dBm) and frequency (MHz).
- **Tethering Quick Toggle:** Direct in-app switch to toggle Android Wi-Fi hotspot state.

### 4. Split Tunneling, Mock GPS & Virtual Camera
- **Per-App Split Tunneling:** Route traffic through the VPN tunnel on a granular, per-application basis.
- **Floating Overlay Widget:** On-screen quick controls to toggle tunnel states and switch parameters without leaving active apps.
- **Mock GPS Location:** Integrates with Android Mock Location provider for testing and geographical simulations.
- **Virtual Camera for Testing:** Feeds static images or video sequences into Android camera capture intents (`IMAGE_CAPTURE`, `VIDEO_CAPTURE`, `FileProvider`) with live scaling, rotation, aspect ratio adjustment, and perspective offsets.
- **Root Mode (Priv-App):** Optional execution as a privileged system app (`/system/priv-app`) or Magisk/KernelSU module for test environments and emulators.

### 5. Persistent System Notification
- Ongoing notification tray banner showing tunnel status, assigned IP, real-time upload/download speeds, and elapsed session time.
- Direct notification action buttons to disconnect or cycle servers without opening the UI.

---

## 🛠️ Development & Build

Prerequisites: Flutter SDK (>= 3.19), Android SDK, Java 17.

```bash
# Install dependencies
flutter pub get

# Launch on Pixel 7 emulator
npm run start:android

# Build Universal Release APK
npm run build:apk

# Build Split-per-ABI Release APKs (arm64, armeabi-v7a, x86_64)
npm run build:apk:split
```

---

## 📄 Notes & License

- Pre-loaded public VPN servers are hosted by volunteers in the academic VPN Gate project (University of Tsukuba). Do not route sensitive personal data or financial credentials through untrusted public nodes.
- Distributed under the MIT License. Developed by [Diego Oris](https://diegooris.ch).
