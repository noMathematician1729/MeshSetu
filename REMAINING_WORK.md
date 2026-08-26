# MeshSetu — Implemented vs. Remaining Work

Scope reference: `context.md` (frozen product/architecture spec, v1.0).
Status date: 22 August 2026. Verified against the code in this repository, not against plans.

Verification baseline at the time of writing:

- `flutter analyze` → No issues found
- `flutter test` → 212 passing
- `admin/server`: `npm test` → 17 passing, `npm run build` → clean `tsc`
- `admin/client`: `npm run build` → clean Vite build
- `flutter build apk --debug` → succeeds

---

## 1. Implemented (verified in code)

| Spec area | Where it lives | Notes |
|---|---|---|
| §6 Envelope + protobuf contracts | `mobile/lib/core/generated/`, `mobile/protocol/meshsetu.proto` | Protobuf-lite envelope; `.proto` retained as regeneration source. |
| §6.3 / §8.3–8.4 Framing, fragmentation, reassembly | `core/protocol/frame.dart`, `envelope_codec.dart` | 16-byte header, MTU-aware fragmentation, bounded out-of-order reassembly. |
| §8.2 Priority scheduling | `core/protocol/outbound_scheduler.dart` | SOS outranks voice/room traffic. |
| §8.5–8.6 Dedupe, TTL, relay | `core/protocol/relay_engine.dart` | Hop limits, expiry, duplicate suppression, custody ACK/NACK. |
| §2.4 / §16.3 AEAD before fragmentation | `core/protocol/secure_envelope.dart`, `core/ble/device_key_store.dart` | AES-GCM object auth; Android Keystore wrapping. |
| §7 BLE discovery + GATT transport | `core/ble/` (`ble_discovery`, `gatt_server`, `gatt_peer_session`, `mesh_transport`) | Advertise/scan, GATT server+client, MTU negotiation, serialized writes, scan pacing, health watchdog. |
| §9 Mesh Code / QR join | `feature/join/` | Manifest import, manual code and QR scan. |
| §10 Rooms + ACL/policy | `feature/rooms/` | Policy/ACL, authenticated room packets (v1+v2), presence, lobby/chat. |
| §11 Voice store-and-forward | `feature/voice/` | Opus clip capture via `record`, separate PCM path for STT, voice inbox + playback. |
| §12 Offline STT | `feature/stt/sherpa_onnx_stt_engine.dart` | sherpa-onnx zipformer (int8 encoder), behind `OfflineSttEngine`. Fake engine for tests. |
| §13 Triage (rules) | `feature/triage/triage_engine.dart`, `admin/server/src/triage.ts` | Deterministic safety rules; escalate-only, cannot suppress a manual SOS. |
| §14 Beacon → zone | `core/ble/sos_advertisement.dart`, `app/mesh_event_controller.dart` | Beacon observation → logical zone with explicit uncertainty. |
| §15 Gateway + control room | `feature/gateway/`, `admin/server/`, `admin/client/` | Node/TS API + React dashboard (replaces the spec's FastAPI sketch). |
| §17 Persistence + foreground service | `core/data/database.dart`, `core/data/outbox_sender.dart`, `app/event_mode_*` | Drift outbox/inbox state machine; connected-device foreground service. |
| §17.3 Metrics | `core/protocol/protocol_metrics.dart` | Privacy-safe newline-delimited metrics. |
| Compact CEAL SOS + identity resolution | `core/ble/sos_advertisement.dart`, `app/sos_alert_notifications.dart` | v1 (14B) / v2 (20B with pseudonymous UID) adverts; online receivers resolve expanded details, offline receivers keep a readable compact packet. |
| Hardware SOS gestures (beyond spec) | `android/.../EmergencyGestureAccessibilityService.kt`, `app/emergency_gestures.dart` | Six volume-key patterns → typed red-SOS countdown confirmation. |
| Emergency-contact SMS fan-out (beyond spec) | `admin/server/src/twilio_sms.ts`, `sms_delivery.ts`, `fast2sms.ts` | Twilio primary with delivery ledger + idempotency. |

---

## 2. Remaining work

### 2.1 Not implemented at all

| Item | Spec ref | Notes |
|---|---|---|
| **Zone density estimate** | §14.3 | No `estimateDensity` anywhere in the codebase. |
| **Zone precursor score** | §14.4 | No `precursorScore` / `ZoneSignals`. The dashboard has no precursor panel, so the "advisory, not auto-dispatch" separation the spec requires is undemonstrated. |
| **Triage ML classifier** | §13.4–13.6 | `TriageClassifier` is an interface with no implementation; no `.tflite`/ONNX triage model, no `ml/triage-training/`. Triage is rules-only today (honest, but the spec's optional classifier is absent). |
| **Responder update back into mesh** | §15.4 | Operator ACK exists; signed authority command flowing back into the mesh as a high-priority control event is not implemented. |
| **Log parser / packet simulator tooling** | §4.1 `tools/` | Metrics are emitted but there is no `log_parser.py` / `packet_simulator.py`. Judged metrics (median/P95 latency, delivery rate) must currently be computed manually. |
| **STT benchmark harness + report** | §12.5–12.6, §18.4 | No `SttBenchmarkCase` harness, no recorded model latency/keyword-recall table on real devices. |
| **Fourth product feature** | §1.2 | Intentionally unspecified. Extension point only — do not invent. |

### 2.2 Implemented but not production-hardened

| Item | Spec ref | Gap |
|---|---|---|
| **Shared-site crypto vs. per-role keys** | §10.2, §16.1, §22.1 | Restricted rooms do not yet use separate room keys, so the spec's "public attendee must not decrypt responder traffic" production requirement is unmet. |
| **Origin signature vs. mutable relay metadata** | §8.6 | Hop count is mutated inside the authenticated envelope (decrypt/re-encrypt by site members). The spec calls for an immutable origin-signed envelope wrapped in mutable relay metadata. |
| **Enrollment ceremony** | §1.2, §16.1 | No signed per-device provisioning; demo manifest path only. Device revocation absent. |
| **STT confidence calibration** | §12.7 | Engine does not emit a calibrated confidence; UI must continue to show "unavailable" rather than a fabricated number. |
| **Gateway auth** | §15.1 | Gateway upload is protected by a shared demo key. Needs real credentials + rotation before any field use. |
| **APK size / release build** | — | Debug APK is ~310 MB, dominated by unstripped multi-ABI `sherpa_onnx` native libs plus a 26 MB int8 encoder. Needs `--split-per-abi` / release build (and ideally on-demand model download) before distribution. |
| **Secrets rotation** | §16 | Credentials were pasted into a development chat during this project (Twilio, Postgres, Cloudinary, Gemini, signing secrets). **Rotate all of them.** |

### 2.3 Verification still owed (cannot be closed by unit tests)

These require physical BLE-capable Android phones and are explicitly demanded by §18 and §21:

1. **2-hop offline relay, 10+ consecutive trials** with mobile data and Wi-Fi disabled (§21.3).
2. **Priority preemption on real radio**: inject a P0 SOS mid voice-transfer and prove the structured SOS overtakes remaining audio chunks (§11.6, §18.3).
3. **Voice integrity path**: drop/alter a chunk and confirm incomplete state or integrity failure rather than silent bad playback (§11.6).
4. **Hardware gesture flow**: enable the Accessibility Service, trigger each of the six patterns from a closed UI, confirm the app foregrounds, the correct typed countdown appears, cancel prevents dispatch, and completion queues the structured SOS.
5. **Notification behavior on device**: confirm one alert per compact packet and that both compact and resolved notifications open their detail screens.
6. **STT on target devices**: model load time, inference latency, memory, thermals (§12.4).
7. **Battery delta** over a controlled active-event interval (§18.4).
8. **India SMS delivery to unverified numbers** — currently blocked by Twilio trial restrictions (error `21608`); Fast2SMS fallback is implemented but has never run because no API key was configured.

---

## 3. Cleanup performed in this pass

Removed (all recoverable from git history):

- **Legacy root Kotlin/Gradle project** — `app/`, `core-model/`, `core-protocol/`, `core-ble/`, `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradlew`, `gradlew.bat`, `gradle/`. Fully superseded by `mobile/lib/`; nothing referenced it and it had its own duplicate `meshsetu.proto`.
- **Stale process docs** — `GAT_work_done.md`, `gatt_issue.md`, `handoff.md`, `overview.md`, `report.md`, `checklist.md`.
- **Duplicate spec binary** — `MeshSetu_Technical_Development_Bible_Flutter.pdf` (598 KB; `context.md` is the live copy).
- **Broken `docker-compose.yml`** — mounted `working_dir: /app/backend`, a path that does not exist in this repo. `render.yaml` is the real deployment path.
- **Unused iOS scaffolding** — `mobile/ios/` had no Bluetooth/microphone/camera `Info.plist` strings, so the app could never have run there. Regenerate with `flutter create --platforms=ios .` if iOS is ever in scope.
- **Unreferenced generated file** — `mobile/lib/core/generated/meshsetu.pbjson.dart`.
- **Unused STT model weights** — fp32 encoder (87 MB), fp32 joiner, int8 decoder, `test_wavs/`, export script. Only the four files in `SherpaOnnxEnglishSttEngine._requiredFiles` remain; bundled model assets dropped from ~117 MB to ~28 MB.
- **Unrelated tooling / OS cruft** — `.github/modernize/java-upgrade`, `.DS_Store`, stray `.gradle/` and `.kotlin/` directories.

Also changed:

- `mobile/pubspec.yaml`: removed the blanket `assets/models/` declaration so unused files can no longer be bundled silently.
- `.gitignore`: rewritten for the Flutter + Node layout (dropped dead `core-*/bin/` rules).
- `readme.md`: added the real repository layout and control-room build commands.
- `RoomRepository`: `_localDisplayName` → public `localDisplayName` initializing formal, clearing the last analyzer lint.

**Deliberately kept:**

- `mobile/third_party/universal_ble` — load-bearing; `pubspec.yaml` pins it via `dependency_overrides`.
- `mobile/protocol/meshsetu.proto` — regeneration source for `lib/core/generated/`.
- `TESTING.md`, `context.md`, `render.yaml`.

No dependency was removed: every package in `mobile/pubspec.yaml`, `admin/server/package.json`, and `admin/client/package.json` was checked and is actually imported.
