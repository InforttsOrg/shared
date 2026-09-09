# Infortts Shared Core Architecture & System Guide (`infortts_shared`)

This repository defines the standardized architectural patterns, shared packages, and operational requirements mandatory across **all Infortts applications** (e.g. Meeseeks, Mitochondria, etc.).

---

## 🏛️ Key Architectural Principles

### 1. Universal Hugging Face CDN OTA Pattern
All apps distribute live executable update patches (`.apk`, `.bin`) via the public Hugging Face CDN dataset repository (`rttss/ota-patches`).

* **Manifest Location**: `https://huggingface.co/datasets/rttss/ota-patches/raw/main/<app_name>/manifest.json`
* **Binary Location**: `https://huggingface.co/datasets/rttss/ota-patches/resolve/main/<app_name>/<app_name>.apk`
* **Encryption**: Mandatory AES-256-CBC with HMAC-SHA256 integrity verification (`InforttsOtaDecryptor`).
* **5-Digit Version Scheme**: Version codes use the Mitochondria standard (`20207` -> `2.02.07`).
* **Engine**: Integrated via `InforttsCdnOtaEngine.initialize(appName: '...', encryptionKey: '...')`.

---

### 2. System Overlay Keyboard Safety
System overlay windows (Floating Bubbles, Side Panels, Heads-Up Displays) MUST NOT corrupt software input method editors (IME) or capture focus from underlying foreground applications.

* **Required `WindowManager.LayoutParams` Flags**:
  * `FLAG_NOT_FOCUSABLE`
  * `FLAG_NOT_TOUCH_MODAL`
  * `SOFT_INPUT_STATE_UNCHANGED`
* **Usage**: Prevents background soft keyboard dismissal/killing when overlays launch or update.

---

### 3. Live User Action Context Memory Engine
Real-time interaction memory buffer tracking live user actions across `TOUCH`, `DRAG`, `CHAT`, `SCREEN`, and `SYSTEM` events.

* **Dart Service**: `LiveContextService.instance` (rolling 40-event buffer).
* **Widget Tracking**: Wrap UI views with `LiveContextTracker(screenName: '...', child: ...)` to capture touch/drag gestures without consuming hit-tests.
* **LLM Prompt Injection**: Use `LiveContextService.instance.getFormattedContextPrompt()` inside prompt generators to provide real-time user intent to AI agents.

---

### 4. Host OS User Communication (`UserTalkTool` / `HostUserCommsClient`)
Enables AI services and client applications to speak directly to the underlying host Linux/macOS user.

* **Multi-Channel Delivery**:
  1. **TTS Voice Audio**: `spd-say`, `espeak-ng`, `espeak`, `festival`, `say` (macOS).
  2. **Native GUI Popups**: `notify-send`, `kdialog`, `zenity`, `osascript`.
  3. **Terminal Broadcasts**: `wall` and direct write to `/dev/pts/*`.
* **Flutter Client**: `HostUserCommsClient(baseUrl: 'https://<app>.infortts.site').speakToHostUser('Message')`.
* **Python Tool**: `meeseeks.tools.user_talk.UserTalkTool().speak(message)`.

---

### 5. Production Domain Routing & 5-Digit Versioning
* **Production API Standard**: `https://<app_name>.infortts.site`
* **Production Database**: PostgreSQL / SQLite state persistence on production infrastructure.
* **Build Codes**: `2.02.00+20207` (Major 2, Minor 02, Patch 07).

---

## 📦 Package Modules

| Module | Description |
|---|---|
| `cdn_ota_engine.dart` | AES-256 encrypted Hugging Face CDN OTA patch fetcher & installer |
| `live_context.dart` | Real-time user touch/drag/chat action context memory engine & widget tracker |
| `user_comms.dart` | Host OS user communication client (TTS, notifications, wall) |
| `theme.dart` & `brand.dart` | Infortts high-contrast minimalist design tokens and typography |
| `shell.dart` | Desktop & mobile layout scaffold wrappers |
| `notification_client.py` | Python client for system notifications & desktop alerts |

---

## 🚀 Quickstart Integration Checklist for New Infortts Apps

1. Add `infortts_shared` to `pubspec.yaml`:
   ```yaml
   dependencies:
     infortts_shared:
       path: ../shared
   ```
2. Initialize OTA Engine in `main()`:
   ```dart
   await InforttsCdnOtaEngine.initialize(
     appName: 'your_app',
     encryptionKey: 'YOUR_AES_256_KEY',
   );
   ```
3. Wrap main widget tree with `LiveContextTracker`:
   ```dart
   LiveContextTracker(
     screenName: 'MainScreen',
     child: MaterialApp(...),
   )
   ```
4. Configure system overlays with non-focus-stealing WindowManager flags in native Android code (`SOFT_INPUT_STATE_UNCHANGED` + `FLAG_NOT_FOCUSABLE`).
5. Route production backend calls to `https://<your_app>.infortts.site`.
