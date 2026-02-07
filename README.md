# Lue

A lightweight macOS menu bar app for controlling Philips Hue lights. Built with SwiftUI, talks directly to the Hue Bridge — no cloud, no Home Assistant, no middleman.

## Features

- **Auto-discovery** — Automatically finds your Hue Bridge on the local network
- **Room selection** — Pick any room from your Hue Bridge on first launch
- **Room control** — Toggle all lights on/off with a single switch, adjust room brightness
- **Individual lights** — Expand to control each light separately with per-light brightness sliders
- **Scenes** — Expand to activate Hue scenes with one click
- **Real-time updates** — SSE event streaming keeps the UI in sync when lights change from other apps or switches
- **Debounced sliders** — Brightness changes update instantly in the UI, API calls are batched after dragging stops
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

3. Click the lightbulb icon in the menu bar — your bridge IP is discovered automatically

4. Press the **link button** on your Hue Bridge, then click **Pair**

5. Select the **room** you want to control

6. That's it — your configuration is stored in Keychain for future launches

Use the gear icon (bottom-right) to switch rooms, or the power icon (bottom-left) to quit.

## Architecture

```
┌──────────────────────┐     HTTPS (CLIP v2)      ┌──────────────────┐
│  Menu bar app        │ ◄──────────────────────► │  Hue Bridge      │
│  (SwiftUI + Swift 6) │     SSE (live events)     │  (local network) │
└──────────────────────┘                           └──────────────────┘
```

| Layer | File | Role |
|-------|------|------|
| App | `LightWidgetApp.swift` | `MenuBarExtra` entry point, three-state routing |
| Views | `Views/` | Popover UI — room selection, room header, scene picker, light rows, setup |
| ViewModel | `LightViewModel.swift` | `@MainActor @Observable` — bridges API to UI |
| Service | `HueBridgeService.swift` | Actor — REST calls + SSE streaming |
| Keychain | `KeychainService.swift` | Stores bridge IP, API key, and room configuration |
| Models | `Models/` | Hue API response models and room configuration |
| Utilities | `Utilities/` | Certificate trust delegate, debouncer |

## Project generation

The Xcode project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```
brew install xcodegen
xcodegen generate
```

> **Note:** XcodeGen overwrites the entitlements file. If regenerating, verify `LightWidget.entitlements` still contains `com.apple.security.network.client`.
