.# MeshSetu - Team -1x Devs.

Android-first, offline emergency communication over a BLE store-and-forward overlay.

MeshSetu lets a structured SOS travel from a citizen's phone to a control-room dashboard through one or more relay phones, with mobile data and Wi-Fi internet fully disabled. It is not Bluetooth SIG Mesh certification, not live voice streaming, and not a production enrollment/security ceremony — see [Non-goals](#non-goals).

The full product and architecture contract is [`context.md`](context.md) (frozen spec, v1.0, ~32 pages covering protocol, BLE transport, STT, triage, security, and a 48-hour build plan). This README summarizes what is actually implemented and verified in this repository, and calls out where the implementation diverges from that frozen spec.

## Repository layout

```text
mobile/        Flutter Android app (mesh transport, SOS, rooms, STT, gestures)
admin/server/  Node + TypeScript control-room API (Postgres, WebSocket, SMS fan-out)
admin/client/  React operator dashboard
context.md     Frozen product/architecture specification (v1.0)
```

## Architecture

### End-to-end flow

```text
[Phone A: citizen]
  Capture SOS / voice
      |
      v
  Local STT -> Deterministic triage rules
      |
      v
  Durable outbox (Drift) -> AES-GCM encrypt -> fragment
      |
   BLE GATT
      v
[Phone B: relay] -> [Phone C: relay] -> [Gateway phone]
                                            |
                                            v  local LAN, no internet required
                                  [Control-room API + dashboard]
```

- **Source phone**: persists the SOS draft before any inference runs (a manual SOS is never blocked on a model), runs on-device STT and deterministic safety-rule triage in parallel, then encrypts and authenticates the envelope once and fragments the ciphertext for the current GATT MTU.
- **Relay phone**: validates the frame header, deduplicates by object ID, and forwards toward the gateway with hop-count/TTL enforcement; the outbound scheduler guarantees SOS metadata is never starved by voice chunks or room chat.
- **Gateway phone**: participates in the mesh like any other peer, then bridges verified, reassembled incidents to the control-room API over the local network — no internet uplink required, only a shared LAN/hotspot between the gateway phone and the control-room host.
- **Control room**: Node/TypeScript API backed by Postgres, pushing live incident/room updates to the React dashboard over WebSocket and fanning out SMS to emergency contacts via Twilio (primary) or Fast2SMS (fallback for Indian numbers).

### Transport layer: BLE discovery + GATT

Discovery and data transfer are deliberately split, per `context.md` §7:

- **Advertising** is used only for peer discovery — a compact site fingerprint and protocol/service UUID, not application data.
- **GATT** carries all actual messages. Each phone runs both a GATT server (peripheral) and GATT client (central) role concurrently, with deterministic connection ownership to avoid two phones simultaneously trying to be central for each other.
- **MTU is negotiated, never assumed.** The client requests an MTU on connect; the effective fragment size is derived from whatever the platform actually reports back, not from a hardcoded value.
- If the effective MTU is too small for practical voice transfer within the configured expiry, the transport sends the structured SOS and marks voice `DEFERRED_MTU` rather than saturating the link — graceful degradation, not failure.

### Protocol layer: envelope, framing, relay

- **Application envelope** (`mobile/protocol/meshsetu.proto`): a protobuf-lite `MeshEnvelope` carries `event_id`, `site_id`, `room_id`, timestamps, `hop_count`/`hop_limit`, `Priority`, `PayloadType`, and an opaque `payload` (a serialized `StructuredSos`, `RoomMessage`, `VoiceManifest`, etc.). Metadata and voice are separate linked objects, so metadata can complete even if audio never does.
- **Object security before fragmentation** (`core/protocol/secure_envelope.dart`): the full envelope is serialized and AES-GCM encrypted/authenticated exactly once, then the ciphertext is fragmented — not encrypting per-frame, which would pay an AEAD tag on every tiny BLE write. Local key material is wrapped by the Android Keystore (`core/ble/device_key_store.dart`).
- **Transport framing** (`core/protocol/frame.dart`, `envelope_codec.dart`): a strict 16-byte frame header (version, frame type, priority, flags, 64-bit object ID, sequence number, chunk count) rides ahead of each fragment. Reassembly is bounded and tolerates out-of-order delivery.
- **Priority scheduling** (`core/protocol/outbound_scheduler.dart`): traffic classes rank `CONTROL_ACK` > `SOS_STRUCTURED` > `AUTHORITY_CONTROL` > `VOICE_EVIDENCE` > `ROOM_MESSAGE` > `TELEMETRY`. SOS structurally outranks voice and room traffic; the scheduler can preempt between chunks of a lower-priority object mid-transfer.
- **Relay engine** (`core/protocol/relay_engine.dart`): enforces hop limits and expiry, deduplicates by object ID via a recency cache, issues custody ACKs for completed objects, and supports NACK bitmaps for missing voice chunks with bounded, jittered retry.

### Mesh Code / QR join

A short human code or QR scan (`mobile/lib/feature/join/`) imports an event manifest — site ID, allowed rooms, beacon map version, validity window, and a demo site key. Per `context.md` §9, the code is explicitly a bootstrap/namespace identifier, not a cryptographic root key; production manifests are meant to be signed and validated (expiry, signature, room scope) before activation.

### Rooms

Policy/ACL-scoped rooms (`mobile/lib/feature/rooms/`) — Public Alerts, a zone room, Medical, Responders — each with a `RoomPolicy` controlling read/post roles, max message size, TTL, and traffic class. Room membership gates visibility and forwarding, but an SOS is an event-level safety object: relay eligibility for an SOS never depends on ordinary room subscription, so a phone outside "Medical" still relays a medical SOS. Rooms support offline text and voice notes (`room_voice_*.dart`) with presence and lobby/chat UI.

### Voice evidence

Voice is an input/evidence mode, not a call feature (`mobile/lib/feature/voice/`, `feature/rooms/room_voice_*.dart`). A short, duration-capped clip is captured once; the same PCM buffer feeds on-device STT and a compressed, chunked voice object in parallel. The structured/transcribed SOS is always relayed ahead of the voice bytes. Voice is store-and-forward — bounded capture, bounded transfer, explicit transfer state (queued/transferring/complete/failed) — never continuous streaming.

### Offline speech-to-text

`sherpa_onnx_stt_engine.dart` implements `OfflineSttEngine`, an interface (`stt_engine.dart`) that keeps the STT implementation swappable and isolated from BLE/UI code, per `context.md` §2.6 and §12.1. A `fake_stt_engine.dart` backs tests so the rest of the pipeline doesn't depend on model weights. `stt_model_manager.dart` handles model asset install/verification. If the engine cannot support a calibrated confidence score, the UI shows "confidence unavailable" rather than a fabricated number (§12.7) — and STT failure never suppresses a manual or voice SOS; it degrades to raw audio + fallback triage.

### Triage

Deterministic, explainable, escalate-only (`mobile/lib/feature/triage/triage_engine.dart`, `admin/server/src/triage.ts`), per the hybrid design in `context.md` §13: safety-critical phrase rules can force a priority up, but nothing can suppress or downgrade a manual SOS. The optional small ML classifier described in the spec (§13.4–13.6) is not implemented — triage here is rules-only.

### Beacon-to-zone localization

`core/ble/sos_advertisement.dart` and `app/mesh_event_controller.dart` resolve nearby beacon observations to a logical zone with an explicit confidence/uncertainty label, not a claimed precise position — RSSI-based distance is inherently noisy around bodies and structures, so the spec (§14.2) and this implementation both prioritize "Zone B / approximate" over a fake sub-meter dot.

### Compact SOS advertisements

Two advertisement formats coexist (`core/ble/sos_advertisement.dart`, `app/sos_alert_notifications.dart`): a 14-byte v1 packet and a 20-byte v2 packet carrying a pseudonymous reporter UID. A receiver that never resolves the full detail still surfaces a readable compact notification rather than nothing.

### Control room

`admin/server/` (Express + TypeScript) backed by Postgres (`pg`) with a WebSocket server (`ws`) for live dashboard pushes and JWT-based operator auth. `admin/client/` is the React dashboard. This replaces the frozen spec's original FastAPI/Python sketch (§15.2) — noted as a deliberate implementation deviation in `context.md`, not an oversight. Gateway ingestion is currently protected by a shared demo key (`MESHSETU_GATEWAY_SECRET` / `x-meshsetu-gateway-key` header), which is explicitly a development credential.

### Persistence and background execution

The Drift (SQLite) database (`core/data/database.dart`) is the durable outbox/inbox, not just UI cache — every event moves through a state machine (`CREATED → READY → RELAYING → ACKED/EXPIRED`) so retries and process restarts don't silently lose an object (`core/data/outbox_sender.dart`). Active event mode runs a visible connected-device foreground service (`app/event_mode_*`), because Android's BLE background execution constraints make a hidden background service unreliable — this is an explicit, documented non-goal of the spec (§1.2), not a bug.

### Metrics

`core/protocol/protocol_metrics.dart` emits privacy-safe, newline-delimited protocol events (scan found, connected, frame tx/rx, object complete, ack, retry) tagged with event/peer IDs — never raw transcript text or audio bytes, per the logging policy in §17.4.

### Wire format reference

The application envelope (`meshsetu.proto`) and the transport frame are two different layers — do not confuse a protobuf-serialized `MeshEnvelope` with a BLE frame:

- **`MeshEnvelope`** (application layer, encrypted as a whole): `event_id`, `site_id`, `room_id`, `created_at_ms`, `expires_at_ms`, `hop_count`, `hop_limit`, `Priority` (`P0_CRITICAL` … `P3_BULK`), `PayloadType` (`STRUCTURED_SOS`, `ROOM_MESSAGE`, `VOICE_MANIFEST`, `VOICE_OBJECT`, `ACK`, `RESPONDER_UPDATE`, `BEACON_OBSERVATION`), and an opaque `payload` holding the serialized sub-message for that type.
- **Frame header** (transport layer, 16 bytes, network byte order, rides ahead of every ciphertext fragment): `version` (1B) · `frame_type` (1B) · `priority` (1B) · `flags` (1B) · `object_id` (8B) · `sequence` (2B) · `chunk_count` (2B). Effective fragment payload size is `(negotiated_MTU - 3 ATT overhead - 16 header bytes)`, floored at 1 byte, recomputed per peer after MTU negotiation completes — never assumed from a constant.
- **Traffic class ranking** used by the outbound scheduler: `CONTROL_ACK` (0, highest) → `SOS_STRUCTURED` (1) → `AUTHORITY_CONTROL` (2) → `VOICE_EVIDENCE` (3) → `ROOM_MESSAGE` (4) → `TELEMETRY` (5, lowest). Lower rank always wins; ties break by creation time.
- **Relay dedupe**: a bounded recency cache keyed by `object_id`, pruned by expiry, prevents forwarding loops without needing a full routing table.

### Module dependency direction

Following `context.md` §4.2, dependencies flow one way so the STT/BLE isolation the spec requires is enforceable, not just conventional:

```text
UI/features -> repositories/use-cases -> core/protocol, core/data -> core/ble
                          |                        |
                          +-> feature/stt ---------+
                          +-> feature/triage -------+
```

`core/ble` never imports from `feature/stt` or `feature/triage`; the reverse dependency also does not exist. `OfflineSttEngine` and the triage engine are called from repository/use-case code, not from the transport layer, so either can be swapped, stubbed (`fake_stt_engine.dart`), or fail without touching BLE code.

### Beyond the frozen spec

Two features exist in this repository that are not part of the v1.0 contract:

- **Hardware SOS gestures** (`mobile/android/.../EmergencyGestureAccessibilityService.kt`, `app/emergency_gestures.dart`): volume-key patterns trigger a typed, cancelable SOS countdown via an Android Accessibility Service.
- **Emergency-contact SMS fan-out** (`admin/server/src/twilio_sms.ts`, `sms_delivery.ts`, `fast2sms.ts`): Twilio as the primary transport with a delivery ledger and idempotency, Fast2SMS as an Indian-number fallback.

## What's implemented

| Area | Where | Notes |
|---|---|---|
| Application envelope | `mobile/lib/core/generated/`, `mobile/protocol/meshsetu.proto` | Protobuf-lite envelope; regenerate from the `.proto` source. |
| Transport framing | `mobile/lib/core/protocol/frame.dart`, `envelope_codec.dart` | Strict 16-byte frame header, MTU-aware fragmentation, bounded out-of-order reassembly. |
| Priority scheduling | `mobile/lib/core/protocol/outbound_scheduler.dart` | SOS outranks voice and room traffic. |
| Relay engine | `mobile/lib/core/protocol/relay_engine.dart` | Hop limits, expiry, duplicate suppression, custody ACKs, NACK bitmaps, retry hooks. |
| Object security | `mobile/lib/core/protocol/secure_envelope.dart`, `core/ble/device_key_store.dart` | AES-GCM authentication before fragmentation; Android Keystore wraps local key material. |
| BLE transport | `mobile/lib/core/ble/` (`ble_discovery`, `gatt_server`, `gatt_peer_session`, `mesh_transport`) | Advertising discovery metadata, deterministic connection ownership, GATT server/client, MTU negotiation, serialized writes. |
| Mesh Code / QR join | `mobile/lib/feature/join/` | Manifest import via typed code or QR scan. |
| Rooms | `mobile/lib/feature/rooms/` | ACL/policy-scoped rooms, presence, lobby/chat, offline text and voice notes. |
| Voice evidence | `mobile/lib/feature/voice/`, `feature/rooms/room_voice_*.dart` | Bounded, compressed voice capture with a separate PCM path for STT; store-and-forward, not streaming. |
| Offline STT | `mobile/lib/feature/stt/sherpa_onnx_stt_engine.dart` | sherpa-onnx (int8 encoder) behind an `OfflineSttEngine` interface; a fake engine backs tests. |
| Triage | `mobile/lib/feature/triage/triage_engine.dart`, `admin/server/src/triage.ts` | Deterministic safety rules; escalate-only — cannot suppress a manual SOS. |
| Beacon-to-zone localization | `mobile/lib/core/ble/sos_advertisement.dart`, `app/mesh_event_controller.dart` | Approximate zone resolution with explicit uncertainty, not a precise position. |
| Control room | `admin/server/`, `admin/client/` | Node/TypeScript API + Postgres + WebSocket, React dashboard. Replaces the spec's original FastAPI sketch (see `context.md` note). |
| Persistence + foreground service | `mobile/lib/core/data/database.dart`, `core/data/outbox_sender.dart`, `app/event_mode_*` | Drift-backed durable outbox/inbox state machine; visible connected-device foreground service. |
| Metrics | `mobile/lib/core/protocol/protocol_metrics.dart` | Privacy-safe, newline-delimited protocol metrics; no raw transcript/audio. |
| Compact SOS advertisements | `mobile/lib/core/ble/sos_advertisement.dart`, `app/sos_alert_notifications.dart` | v1 (14B) / v2 (20B with pseudonymous UID) adverts; offline receivers keep a readable compact packet even without a resolved detail. |
| Hardware SOS gestures | `mobile/android/.../EmergencyGestureAccessibilityService.kt`, `app/emergency_gestures.dart` | Volume-key patterns trigger a typed, cancelable SOS countdown. Beyond the frozen spec. |
| Emergency-contact SMS | `admin/server/src/twilio_sms.ts`, `sms_delivery.ts`, `fast2sms.ts` | Twilio primary path with a delivery ledger and idempotency; Fast2SMS fallback. Beyond the frozen spec. |



## Build and test

The Flutter build targets Android SDK 36. Use a Flutter SDK compatible with the Dart constraint in `mobile/pubspec.yaml` (Flutter 3.47 / Dart 3.12 is the verified toolchain).

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Debug builds use Bluetooth SIG's testing company ID. A release build requires MeshSetu's assigned 16-bit BLE Company Identifier and fails before compilation without it:

```bash
flutter build apk --release --dart-define=MESHSETU_BLE_COMPANY_ID=0x1234
```

Control room:

```bash
cd admin/server && npm ci && npm test && npm run build
cd admin/client && npm ci && npm run build
```

`admin/server` expects `DATABASE_URL` (Postgres) and, for SMS fan-out, `TWILIO_*` or Fast2SMS credentials — see `admin/server/src/twilio_sms.ts` and `fast2sms.ts` for the exact variables. Without a database it falls back to in-memory state for local testing (see the test files' `DATABASE_URL = ''` pattern).

Install `mobile/build/app/outputs/flutter-apk/app-debug.apk` on physical BLE-capable Android phones. Tap **Start event mode** to request permissions and start the visible connected-device foreground service. The foreground task owns scanning and relay processing, so leaving the screen does not stop the mesh; use **Stop event mode** to shut it down.

The debug APK bundles offline STT model assets and is sideload-only (not suitable for Play distribution as-is).

### Control-room smoke test

From `admin/server/`:

```bash
npm run dev
```

The default demo key is `change-me`; set `MESHSETU_GATEWAY_SECRET` before starting the server to use a different one for a shared demo. Verify the HTTP contract in another terminal:

```bash
curl -i http://127.0.0.1:8000/health
curl -i http://127.0.0.1:8000/api/events

curl -i -X POST http://127.0.0.1:8000/api/events \
  -H 'content-type: application/json' \
  -H 'x-meshsetu-gateway-key: change-me' \
  -d '{"event_id":"smoke-1","priority":"p0Critical","incident_type":"medical","transcript":"dashboard smoke test"}'
```

The POST must return HTTP 200; a POST without the gateway-key header must return HTTP 401. To run the dashboard against it locally:

```bash
cd admin/client
VITE_API_BASE_URL=http://127.0.0.1:8000 npm run dev
```

### Multi-phone offline mesh trial

The automated suite uses synthetic BLE links, so it cannot prove radio behavior. For a physical trial, use at least three Android phones (source, relay, gateway):

1. Start the control-room backend on a laptop and find its LAN address (`ipconfig` / `ifconfig`).
2. On the gateway phone, open the gateway screen, point it at `http://<laptop-lan-ip>:8000`, set the dashboard key to match `MESHSETU_GATEWAY_SECRET`, and enable gateway mode.
3. Start event mode and join the same event manifest on all phones.
4. Disable mobile data and Wi-Fi internet uplink on every phone; keep the gateway phone and laptop on an isolated local Wi-Fi/hotspot with no internet.
5. Place the relay phone physically between the source and gateway phones.
6. Send a structured SOS from the source phone and confirm the dashboard eventually shows incident, priority, transcript, room, hop count, latency, and voice transfer state.
7. While a voice clip is still transferring, inject a second SOS and confirm it overtakes the remaining voice chunks (§11.6, §18.3 priority preemption proof).
8. Kill and relaunch the app on the relay phone mid-transfer to confirm the durable outbox resumes rather than silently losing the object.

+1
