# MeshSetu

Android-first, offline emergency communication over a BLE store-and-forward overlay.

## Repository layout

```text
mobile/        Flutter Android app (mesh transport, SOS, rooms, STT, gestures)
admin/server/  Node + TypeScript control-room API (Postgres, SMS fan-out)
admin/client/  React operator dashboard
context.md     Frozen product/architecture specification
REMAINING_WORK.md  Implemented vs. outstanding scope against context.md
```

## Build and test

The Flutter build targets Android SDK 36. Use a Flutter SDK compatible with the Dart constraint in `mobile/pubspec.yaml`.

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Control room:

```bash
cd admin/server && npm ci && npm test && npm run build
cd admin/client && npm ci && npm run build
```

Install `mobile/build/app/outputs/flutter-apk/app-debug.apk` on physical BLE-capable Android phones. Tap **Start event mode** to request permissions and start the visible connected-device foreground service. The foreground task owns scanning and relay processing, so leaving the screen does not stop the mesh; use **Stop event mode** to shut it down.

## Current transport slice

- Protobuf-lite application envelope and strict 16-byte transport frames.
- MTU-aware fragmentation, bounded out-of-order reassembly, duplicate suppression, and expiry.
- AES-GCM object authentication before fragmentation; Android Keystore helper for local key wrapping.
- Priority scheduling and store-and-forward relay with hop limits, custody ACKs, NACK bitmaps, and retry hooks.
- BLE advertising discovery metadata, deterministic connection ownership, GATT server/client, MTU negotiation, and serialized writes.
- Approximate beacon-to-zone resolution with explicit uncertainty.
- Privacy-safe newline-delimited protocol metrics and a deterministic lossy-frame test hook.

The phone implementation is an application-layer BLE overlay. It is not Bluetooth SIG Mesh certification, live voice streaming, or a production enrollment/security ceremony. Room persistence, the control-room backend, audio/Opus, STT, triage, and QR UX attach through the frozen interfaces described in `context.md`.
+5