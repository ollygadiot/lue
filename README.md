# Lue

A lightweight macOS menu bar app for controlling Philips Hue lights. Built with SwiftUI, talks directly to the Hue Bridge — no cloud, no Home Assistant, no middleman.

## Features

- **Room control** — Toggle all Werkkamer lights on/off with a single switch, adjust room brightness
- **Scenes** — Activate Hue scenes (Bright, Concentrate, Read, Relax, Energize, Nightlight)
- **Individual lights** — Expand to control each light separately with per-light brightness sliders
- **Real-time updates** — SSE event streaming keeps the UI in sync when lights change from other apps or switches
- **Menu bar native** — Lives in the menu bar with a lightbulb icon that reflects on/off state

## Requirements

- macOS 15+
- Philips Hue Bridge (CLIP v2 API)
- Xcode 16+ (to build)

## Setup

1. Clone and open in Xcode:
   ```
   git clone git@github.com:ollygadiot/lue.git
   cd lue
   open LightWidget.xcodeproj
   ```

2. Build and run (⌘R)

3. Click the lightbulb icon in the menu bar

4. Press the **link button** on your Hue Bridge, then click **Pair** in the setup view

5. That's it — your API key is stored in Keychain for future launches

## Architecture

```
┌──────────────────────┐     HTTPS (CLIP v2)      ┌──────────────────┐
│  Menu bar app        │ ◄──────────────────────► │  Hue Bridge      │
│  (SwiftUI + Swift 6) │     SSE (live events)     │  (local network) │
└──────────────────────┘                           └──────────────────┘
```

| Layer | File | Role |
|-------|------|------|
| App | `LightWidgetApp.swift` | `MenuBarExtra` entry point |
| Views | `Views/` | Popover UI — room header, scene picker, light rows, setup |
| ViewModel | `LightViewModel.swift` | `@MainActor @Observable` — bridges API to UI |
| Service | `HueBridgeService.swift` | Actor — REST calls + SSE streaming |
| Keychain | `KeychainService.swift` | Stores bridge IP and API key |
| Certs | `TrustAllCertsDelegate.swift` | Accepts the bridge's self-signed certificate |

## Project generation

The Xcode project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```
brew install xcodegen
xcodegen generate
```

> **Note:** XcodeGen overwrites the entitlements file. If regenerating, verify `LightWidget.entitlements` still contains `com.apple.security.network.client`.
