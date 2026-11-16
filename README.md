<div align="center">
  <img src="assets/images/logo.png" alt="NOrange Logo" width="128" height="128" />

  # NOrange — Stealth Tunnel, Hotspot VPN, Proxy & Tactical Privacy Suite

  **Suíte multiplataforma (Android & iOS) de Tunelamento OpenVPN (57+ Nós Globais), Hotspot VPN Compartilhável, Servidor Proxy HTTP/SOCKS5, Detector Anti-Spyware de WebSockets, Radar de Ondas Wi-Fi, Split Tunneling por App, Mock GPS Híbrido e Câmera Virtualizada em Tempo Real.**

  **Desenvolvido por [Diego Oris](https://diegooris.ch)**  
  🌐 Website: **[diegooris.ch](https://diegooris.ch)** • 💼 LinkedIn: **[linkedin.com/in/diegoorisderoa](https://br.linkedin.com/in/diegoorisderoa)**

  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-FF6B00?style=for-the-badge&logo=flutter&logoColor=white)](https://diegooris.ch)
  [![OpenVPN](https://img.shields.io/badge/Tunnel-OpenVPN%20%2B%20SOCKS5%20%2B%20HTTP-FF6B00?style=for-the-badge)](https://diegooris.ch)
  [![Nodes](https://img.shields.io/badge/Public%20VPN%20Nodes-57%2B%20Servers%20%2F%2034%20Countries-10B981?style=for-the-badge)](https://diegooris.ch)
  [![Author](https://img.shields.io/badge/Author-Diego%20Oris%20(diegooris.ch)-0A0A0D?style=for-the-badge&labelColor=FF6B00)](https://br.linkedin.com/in/diegoorisderoa)
</div>

---

## 📦 Download Direto dos Arquivos `.APK` (Release)

Os instaladores compilados em modo **Release** estão disponíveis diretamente na pasta [`releases/`](./releases) e na aba [**Releases do GitHub**](../../releases):

| Arquivo APK | Arquitetura | Tamanho Aprox. | Indicação |
| :--- | :--- | :---: | :--- |
| [**`NOrange-universal-release.apk`**](./releases/NOrange-universal-release.apk) | Universal (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | ~34.4 MB | Qualquer celular Android ou Emulador |
| [**`NOrange-arm64-v8a-release.apk`**](./releases/NOrange-arm64-v8a-release.apk) | `arm64-v8a` (64-bit) | ~14.8 MB | Celulares Android modernos (Snapdragon, Exynos, Dimensity, Tensor) |
| [**`NOrange-armeabi-v7a-release.apk`**](./releases/NOrange-armeabi-v7a-release.apk) | `armeabi-v7a` (32-bit) | ~14.1 MB | Dispositivos Android 32-bit ou legados |
| [**`NOrange-x86_64-release.apk`**](./releases/NOrange-x86_64-release.apk) | `x86_64` | ~15.1 MB | Emuladores Android (AVD / Android Studio) e PCs x86_64 |

---

## 🚀 Principais Recursos & Arquitetura

### 1. 🌍 Rede Global de 57+ VPNs Públicas (34 Países) & VPN Própria
- **Catálogo Global Instantâneo (57+ Nós em 34 Países)**: Servidores públicos pré-carregados e sincronizados com feeds VPNGate em países das **Américas** (Brasil, EUA, Canadá, Argentina, Chile, Colômbia, México), **Europa** (Suíça, Alemanha, Países Baixos, Reino Unido, França, Portugal, Espanha, Itália, Suécia, Noruega, Finlândia, Irlanda, Polônia, Romênia, Áustria, República Tcheca, Islândia), **Ásia-Pacífico** (Japão, Coreia do Sul, Singapura, Taiwan, Hong Kong, Tailândia, Vietnã, Índia, Indonésia, Austrália, Nova Zelândia) e **Oriente Médio & África** (Emirados Árabes, Turquia, África do Sul).
- **Telemetria Completa por Nó**: Exibe **Total de Conexões Ativas**, **Ping/Latência em ms**, **Velocidade (Mbps)**, **IP**, **Porta** e **Protocolo (`TCP`/`UDP`)**.
- **Smart Connect & Auto-Failover**: Sondagem TCP em tempo real para conectar ao servidor mais rápido em 1 toque, com comutação automática em caso de oscilação.
- **VPN Própria & DNS Criptografado**: Importe perfis `.OVPN` ou configure `IP/Host`, `Porta`, `Protocolo` e credenciais, além de presets DNS (Cloudflare `1.1.1.1`, Google `8.8.8.8`, AdGuard Anti-Tracker) e **Kill Switch**.

### 2. 📡 Hotspot VPN Compartilhável & Servidor Proxy Conectável (IP Público + Local)
- **IP de Conexão Pública (WAN) & IP Local/Hotspot**: Ao criar uma conexão VPN ou Proxy pelo celular, o NOrange detecta e exibe o **IP Público (`WAN IP:Porta`)** com geolocalização/ISP e o **IP Local (`Hotspot/Wi-Fi IP:Porta`)**, além de gerar perfis `.OVPN` clientes prontos para compartilhamento.
- **Autenticação Opcional**: Configure **Usuário e Senha** (HTTP Basic Auth / SOCKS5 RFC 1929) ou opere no modo **Sem Senha (Aberto)** em 1 toque.
- **Painel de Usuários Conectados & Inspeção de Tráfego em Tempo Real**:
  - Veja o **total de usuários conectados** e conexões simultâneas tanto na aba **Hotspot VPN** quanto na aba **Proxy**.
  - Inspecione em tempo real **o que cada usuário conectado está acessando** (domínios HTTPS `CONNECT`, hosts HTTP, upgrades `WebSocket` e IPs de destino).
  - Monitore o consumo individualizado de **Download**, **Upload** e **Total de Bytes** por cliente conectado, com log de requisições ao vivo.
- **Validação Inteligente de Conflitos Exclusivos**: Impede conflitos técnicos entre **Cliente VPN**, **Hotspot VPN / Gateway** e **Proxy**, exibindo um modal explicativo com opção de **Desligar Atual e Iniciar Novo** automaticamente.

### 3. 🛡️ Detector de Conexões WebSocket & Anti-Spyware + Controle do Roteador Wi-Fi
- **Detector de WebSockets Ativos & Anti-Spyware**:
  - Inspeciona a tabela de sockets ativos do kernel Android (`/proc/net/tcp` e `/proc/net/tcp6`) e conexões `WSS://` / `WS://`.
  - Identifica **qual aplicativo** está utilizando a conexão (com **Logo Real do App**, **Nome** e **Package Name**), **para onde** (Domínio/Host de destino) e **para qual IP:Porta remoto**.
  - **Heurística Anti-Spyware**: Alerta automaticamente sobre conexões persistentes em portas não-padrão ou de aplicativos operando em segundo plano sem estar visíveis na tela.
- **Ativar e Desativar Roteador Wi-Fi**: Detecta em tempo real quando o Roteador Wi-Fi / Hotspot está ativo e oferece botões diretos no aplicativo para **Ativar o Roteador Wi-Fi** ou, ao detectar que está ativo, **Desativar o Roteador Wi-Fi imediatamente**.
- **Radar de Proximidade Física por Ondas Wi-Fi (FSPL)**: Calcula a distância estimada em metros (`~m`) dos dispositivos e pontos de acesso ao redor via atenuação `RSSI (dBm)` e frequência (`MHz`).

### 4. 🧩 Split Tunneling por App (com Logos Reais), Mock GPS Híbrido & Câmera Virtualizada em Tempo Real
- **Split Tunneling por App com Logos Reais**:
  - Lista todos os aplicativos instalados no celular com o **ícone/logo original de cada app** e barra de pesquisa.
  - Permite deixar os aplicativos **pré-configurados** para iniciar na hora ou iniciar/alternar diretamente pelo **Widget Flutuante NOrange** sobre o aplicativo em foco.
- **Substituir Coordenadas do GPS (Modo Sem Opções Dev + Guia Passo a Passo)**:
  - **Modo Híbrido Sem Opções do Desenvolvedor**: Aplica automaticamente as coordenadas escolhidas nos cabeçalhos e contexto de geolocalização de rede sem exigir configuração prévia.
  - **Guia Passo a Passo Interativo**: Botão dedicado **"Passo a Passo: Como Ativar no Celular"** explicando como habilitar as Opções do Desenvolvedor (7 toques em *Número da versão*) e selecionar o **NOrange** como *App de local fictício*, com atalhos diretos para as telas do sistema.
- **Câmera Virtualizada em Tempo Real (Fotos, Vídeos, Lives e Apps de Câmera)**:
  - Substitui a captura da câmera pela imagem escolhida em fotos (`IMAGE_CAPTURE`), gravações (`VIDEO_CAPTURE`), transmissões ao vivo (lives) e aplicativos que utilizam a câmera no geral.
  - **Ajuste e Movimentação em Tempo Real**: Mova (arraste com 1 dedo), dê zoom (pinça com 2 dedos), alargue horizontal/verticalmente, gire 90° e espelhe a imagem **em tempo real** tanto dentro do app quanto sobre qualquer aplicativo de câmera através do **Widget Flutuante NOrange** e da **Projeção Ao Vivo na Tela (Live Viewfinder HUD)**.
  - **Transformação de Perspectiva 3D (Simulação de Rotação de Cabeça / Ângulo)**: Controles vetoriais dedicados para inclinar em 3D (*Olhar Esquerda*, *Olhar Direita*, *Olhar Cima*, *Olhar Baixo*), criando o efeito de movimento dinâmico da cabeça mesmo a partir de uma foto estática.
  - **Interceptação Direta para Navegadores e Aplicativos**: Suporta chamadas nativas de câmera (`IMAGE_CAPTURE`, `VIDEO_CAPTURE`, `GET_CONTENT`, `PICK`) com suporte integrado a `FileProvider` e sincronização automática com a galeria e emuladores.
  - **100% Ícones Vetoriais**: Todos os controles direcionais e geométricos utilizam ícones vetoriais nativos (`Canvas` no Android e `Icons` no Flutter), sem uso de setas em texto.

### 5. 🔔 Notificação Persistente de Controle Rápido (Estilo Windscribe)
- Notificação de alta prioridade na bandeja do Android exibindo telemetria em tempo real:
  - **Status do Túnel**: Conectado / Desconectado com país e IP.
  - **Velocidades em Tempo Real**: Download e Upload dinâmicos (KB/s ou MB/s).
  - **Duração do Túnel**: Cronômetro de tempo de conexão ativo.
  - **Ações Imediatas**: Botões nativos de ação para **Desligar** ou **Trocar Servidor** sem precisar abrir o app.

### 6. 📜 Transparência, Termos de Uso & Redes Públicas
- **Origem dos Nós Públicos**: Os servidores públicos integrados ao pool global do NOrange são fornecidos por voluntários da rede acadêmica **VPN Gate (Universidade de Tsukuba, Japão)**.
- **Aviso de Segurança & Privacidade**: Por se tratar de uma rede pública distribuída operada por voluntários acadêmicos em diversos países, o NOrange não controla nem garante a infraestrutura dos nós remotos. **Recomenda-se veementemente não utilizar VPNs públicas para transações bancárias, compras com cartão de crédito, acesso a credenciais pessoais ou serviços altamente sensíveis.** Utilize para navegação anônima, evasão de censura e proteção em redes Wi-Fi públicas.

---

## 🛠️ Comandos Rápidos (`package.json`)

```bash
# Iniciar o emulador Android (Pixel_7) e rodar o NOrange automaticamente
npm run start:android

# Compilar APK Universal de Release (e sincronizar em releases/)
npm run build:apk

# Compilar APKs divididos por ABI (arm64-v8a, armeabi-v7a, x86_64) e sincronizar em releases/
npm run build:apk:split

# Compilar todos os APKs (Universal + Splits por ABI) e atualizar releases/
npm run build:apk:all

# Instalar o APK de Release no emulador/dispositivo conectado
npm run install:apk:release
```

---

## 👨‍💻 Autor & Créditos

<div align="left">
  Desenvolvido por <strong>Diego Oris</strong> — Principal Software Engineer, Cybersecurity & Digital Product Architect.<br/><br/>
  🌐 <strong>Website Oficial:</strong> <a href="https://diegooris.ch">https://diegooris.ch</a><br/>
  💼 <strong>LinkedIn:</strong> <a href="https://br.linkedin.com/in/diegoorisderoa">https://br.linkedin.com/in/diegoorisderoa</a>
</div>