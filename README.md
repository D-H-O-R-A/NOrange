<div align="center">
  <img src="assets/images/logo.png" alt="NOrange Logo" width="120" height="120" />

  # NOrange

  **Cliente OpenVPN, Hotspot Gateway, Servidor Proxy HTTP/SOCKS5 e Utilitários de Rede para Android.**

  Desenvolvido por **[Diego Oris](https://diegooris.ch)**  
  [diegooris.ch](https://diegooris.ch) · [LinkedIn](https://br.linkedin.com/in/diegoorisderoa) · [Releases](./releases)

  [![Platform](https://img.shields.io/badge/Platform-Android-orange.svg)](https://flutter.dev)
  [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev)
  [![OpenVPN](https://img.shields.io/badge/Tunnel-OpenVPN%202.x-EA6000.svg)](https://openvpn.net)
</div>

---

## 📦 Downloads (APKs de Release)

Instaladores compilados disponíveis na pasta [`releases/`](./releases) e na aba [**Releases do GitHub**](../../releases):

| Arquivo APK | Arquitetura | Indicação |
| :--- | :--- | :--- |
| [**`NOrange-universal-release.apk`**](./releases/NOrange-universal-release.apk) | Universal (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | Compatível com qualquer aparelho ou emulador |
| [**`NOrange-arm64-v8a-release.apk`**](./releases/NOrange-arm64-v8a-release.apk) | `arm64-v8a` (64-bit) | Smartphones modernos (Snapdragon, Dimensity, Exynos) |
| [**`NOrange-armeabi-v7a-release.apk`**](./releases/NOrange-armeabi-v7a-release.apk) | `armeabi-v7a` (32-bit) | Aparelhos 32-bit legados |
| [**`NOrange-x86_64-release.apk`**](./releases/NOrange-x86_64-release.apk) | `x86_64` | Emuladores Android (AVD, Android Studio, PC) |

---

## ⚙️ Funcionalidades

### 1. Cliente OpenVPN & Servidores Públicos
- Pool com mais de 50 nós OpenVPN públicos globais (Américas, Europa, Ásia e Oceania) integrados via VPNGate.
- Métricas em tempo real por servidor: latência (ping), velocidade informada, conexões ativas, IP e protocolo (TCP/UDP).
- Suporte a perfis `.ovpn` customizados e credenciais manuais (Host, Porta, Usuário/Senha).
- Seletor de DNS integrado (Cloudflare `1.1.1.1`, Google `8.8.8.8`, AdGuard) e proteção contra vazamento.
- Reconexão automática (Failover) e Kill Switch nativo.

### 2. Hotspot VPN & Servidor Proxy Local
- **Compartilhamento de VPN:** Repasse do tráfego tunelado via ponto de acesso Wi-Fi (Hotspot) para outros dispositivos da rede local.
- **Servidor Proxy HTTP & SOCKS5:** Executa um proxy server diretamente no dispositivo Android com porta configurável e autenticação opcional (RFC 1929 / Basic Auth).
- **Monitor de conexões:** Exibe clientes conectados, IPs, portas, consumo de banda (upload/download) e logs de requisições em tempo real.
- **Isolamento de interfaces:** Gerenciamento para evitar conflito entre o cliente VPN, o gateway do hotspot e o proxy.

### 3. Monitoramento de Rede & Conexões
- **Inspeção de Sockets:** Leitura de `/proc/net/tcp` e `/proc/net/tcp6` para mapear conexões ativas por aplicativo (com identificação de pacote e nome do processo).
- **Detecção de conexões em background:** Identificação de conexões persistentes abertas em portas não convencionais por apps em segundo plano.
- **Medição de sinal Wi-Fi (FSPL):** Estimativa de atenuação de sinal RSSI (dBm) e frequência (MHz) para cálculo aproximado de proximidade dos access points.
- **Controle de Roteador Wi-Fi:** Atalho para alternar o estado do tethering/hotspot diretamente no app.

### 4. Split Tunneling, Mock GPS & Câmera Virtual
- **Split Tunneling por App:** Seleção granular de quais aplicativos instalados devem trafegar pela VPN ou direto pela rede local.
- **Widget Flutuante:** Controle sobreposto para ativar/desativar túneis e alternar recursos sem sair do app em uso.
- **Mock de Localização GPS:** Suporte ao provedor de localização simulada do Android para testes e validações geográficas.
- **Câmera Virtual para Testes:** Injeção de imagem estática ou vídeo em chamadas de captura (`IMAGE_CAPTURE`, `VIDEO_CAPTURE`, `FileProvider`) com ajustes de proporção, escala, espelhamento e enquadramento em tempo real.
- **Modo Root (Priv-App):** Opção de execução com privilégios de sistema em `/system/priv-app` ou como módulo Magisk/KernelSU para ambientes de teste e emuladores.

### 5. Notificação Persistente de Status
- Notificação fixa na barra de status exibindo estado da conexão, IP atual, velocidade de download/upload e tempo conectado.
- Botões de ação rápida para desconectar ou alternar servidor sem abrir a interface.

---

## 🛠️ Desenvolvimento & Build

Requisitos: Flutter SDK (>= 3.19), Android SDK, Java 17.

```bash
# Instalar dependências
flutter pub get

# Iniciar no emulador Pixel 7
npm run start:android

# Compilar APK Universal de Release
npm run build:apk

# Compilar APKs divididos por ABI (arm64, armeabi-v7a, x86_64)
npm run build:apk:split
```

---

## 📄 Notas & Licença

- Os servidores públicos pré-carregados são fornecidos por voluntários da rede acadêmica VPN Gate (Universidade de Tsukuba). Recomenda-se não utilizar nós públicos para transações bancárias ou dados críticos de autenticação.
- Distribuído sob licença MIT. Desenvolvido por [Diego Oris](https://diegooris.ch).
