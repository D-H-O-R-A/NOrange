<div align="center">
  <img src="assets/images/logo.png" alt="NOrange Logo" width="120" height="120" />

  # NOrange

  **Cliente OpenVPN, Gateway Hotspot, Servidor Proxy HTTP/SOCKS5 y Utilidades de Red para Android.**

  Desarrollado por **[Diego Oris](https://diegooris.ch)**  
  [diegooris.ch](https://diegooris.ch) · [LinkedIn](https://br.linkedin.com/in/diegoorisderoa) · [Releases](./releases)

  [![Platform](https://img.shields.io/badge/Platform-Android-orange.svg)](https://flutter.dev)
  [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev)
  [![OpenVPN](https://img.shields.io/badge/Tunnel-OpenVPN%202.x-EA6000.svg)](https://openvpn.net)

  <p>
    <a href="README.md">🇧🇷 Português</a> •
    <a href="README.en.md">🇺🇸 English</a> •
    <b>🇪🇸 Español</b> •
    <a href="README.ru.md">🇷🇺 Русский</a>
  </p>
</div>

---

## 📦 Descargas (APKs de Release)

Instaladores compilados disponibles en la carpeta [`releases/`](./releases) y en la pestaña de [**Releases de GitHub**](../../releases):

| Archivo APK | Arquitectura | Recomendación |
| :--- | :--- | :--- |
| [**`NOrange-universal-release.apk`**](./releases/NOrange-universal-release.apk) | Universal (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | Compatible con cualquier dispositivo Android o emulador |
| [**`NOrange-arm64-v8a-release.apk`**](./releases/NOrange-arm64-v8a-release.apk) | `arm64-v8a` (64-bit) | Smartphones Android modernos (Snapdragon, Dimensity, Exynos) |
| [**`NOrange-armeabi-v7a-release.apk`**](./releases/NOrange-armeabi-v7a-release.apk) | `armeabi-v7a` (32-bit) | Dispositivos Android de 32-bit o heredados |
| [**`NOrange-x86_64-release.apk`**](./releases/NOrange-x86_64-release.apk) | `x86_64` | Emuladores Android (AVD, Android Studio, PC) |

---

## ⚙️ Características

### 1. Cliente OpenVPN y Servidores Públicos
- Conjunto de más de 50 nodos OpenVPN públicos globales (América, Europa, Asia y Oceanía) integrados mediante VPNGate.
- Telemetría en tiempo real por servidor: latencia (ping), velocidad reportada, conexiones activas, IP remoto y protocolo (TCP/UDP).
- Soporte para importación de archivos `.ovpn` personalizados y configuración manual de credenciales (Host, Puerto, Usuario/Contraseña).
- Selector de DNS integrado (Cloudflare `1.1.1.1`, Google `8.8.8.8`, AdGuard) con protección contra fugas.
- Reconexión automática (Failover) y Kill Switch nativo.

### 2. Hotspot VPN y Servidor Proxy Local
- **Compartir VPN:** Comparte el tráfico del túnel VPN a través de un punto de acceso Wi-Fi (Hotspot) con otros dispositivos de la red local.
- **Servidor Proxy HTTP y SOCKS5 Integrado:** Ejecuta un proxy local directamente en Android con puerto configurable y autenticación opcional (RFC 1929 / Basic Auth).
- **Monitor de Conexiones Activas:** Visualización en tiempo real de clientes conectados, hosts remotos, consumo de ancho de banda (subida/bajada) y registro de accesos.
- **Aislamiento de Interfaces:** Gestión para evitar conflictos entre el modo cliente VPN, el gateway hotspot y el proxy.

### 3. Monitoreo de Red e Inspección de Sockets
- **Inspección de Sockets Activos:** Consulta `/proc/net/tcp` y `/proc/net/tcp6` para mapear conexiones abiertas por paquete y UID de proceso.
- **Alertas de Conexiones en Segundo Plano:** Detección de conexiones persistentes abiertas en puertos no convencionales por aplicaciones en segundo plano.
- **Medición de Señal Wi-Fi (FSPL):** Cálculo estimado de atenuación de señal RSSI (dBm) y frecuencia (MHz) para estimar distancia aproximada a los puntos de acceso.
- **Control Rápido de Zona Wi-Fi:** Acceso directo para encender o apagar la zona portátil (tethering) desde la aplicación.

### 4. Split Tunneling, Mock GPS y Cámara Virtual
- **Split Tunneling por Aplicación:** Enrutamiento granular para definir qué aplicaciones deben usar el túnel VPN o la conexión directa.
- **Widget Flotante:** Controles en pantalla sobre cualquier app para activar o alternar túneles sin cambiar de ventana.
- **Ubicación GPS Simulada (Mock):** Integración con el proveedor de ubicación simulada de Android para pruebas y validaciones geográficas.
- **Cámara Virtual de Prueba:** Inyección de imagen estática o secuencias de vídeo en intents de captura de cámara (`IMAGE_CAPTURE`, `VIDEO_CAPTURE`, `FileProvider`) con controles de escala, proporción, rotación y perspectiva en tiempo real.
- **Modo Root (Priv-App):** Opción de ejecución con privilegios de sistema (`/system/priv-app`) o módulo Magisk/KernelSU para emuladores y entornos de investigación.

### 5. Notificación Persistente de Estado
- Notificación persistente en la barra de Android con estado del túnel, IP asignada, velocidad de subida/bajada en vivo y tiempo de conexión.
- Botones de acción rápida para desconectar o alternar servidor sin abrir la interfaz gráfica.

---

## 🛠️ Desarrollo y Compilación

Requisitos: Flutter SDK (>= 3.19), Android SDK, Java 17.

```bash
# Instalar dependencias
flutter pub get

# Iniciar en emulador Pixel 7
npm run start:android

# Compilar APK Universal de Release
npm run build:apk

# Compilar APKs divididos por ABI (arm64, armeabi-v7a, x86_64)
npm run build:apk:split
```

---

## 📄 Notas y Licencia

- Los servidores públicos precargados son provistos por voluntarios del proyecto académico VPN Gate (Universidad de Tsukuba). No use nodos públicos para transacciones bancarias ni credenciales confidenciales.
- Distribuido bajo la Licencia MIT. Desarrollado por [Diego Oris](https://diegooris.ch).
