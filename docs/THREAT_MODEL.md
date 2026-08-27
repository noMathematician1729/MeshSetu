# MeshSetu SOS return-channel threat model

## Assets

- Sender safety messages and the authority response text.
- Event/site membership and the sender's fixed-width ephemeral destination ID.
- Authority private signing key and manifest-pinned public key.
- Durable response state, delivery receipts, route hints, and operator status.
- Availability of P0 SOS traffic under relay, MTU, restart, and network failure.

## Trust boundaries

1. **Authority signer → manifest:** the signer is trusted to issue response types; the active signed manifest is the sender's trust anchor.
2. **BLE transport:** relays, peers, GATT sessions, and gateways are untrusted transport participants. They may drop, replay, reorder, or modify bytes.
3. **Gateway HTTP bridge:** authenticated by a gateway credential, but not trusted for authority text. It must persist before injection and cannot claim sender delivery.
4. **Sender application:** the only component allowed to display authority text after cryptographic and event-scope checks.
5. **Control room operator:** authorized by bearer authentication and server-side response-type guards, but operator text still must be signed before entering the mesh.

## Threats and controls

| Threat | Control | Residual risk |
|---|---|---|
| Forged authority response | ECDSA P-256/SHA-256, exact body bytes, manifest key-ID pinning | Demo manifest enrollment is not a production ceremony |
| Modified operator text | Signature covers serialized body; sender verifies before display | A sender without the active manifest cannot verify and must remain silent |
| Replay of a valid response | Response ID dedupe in memory and durable inbox; expiry and event lookup | A replay within a valid window is harmless but can consume transport capacity |
| Wrong-site response | AEAD site scope, signed body/site match, active manifest site match | Shared site keys remain a pilot limitation |
| Wrong sender receipt | Server compares receipt event ID and sender ID with stored response destination | Gateway credentials still need production rotation |
| Stale route or route loop | Event-scoped TTL, candidate cap, ingress exclusion, hop limit, bounded fallback | Radio churn can still cause retries until expiry |
| Gateway process death | Command persisted before HTTP acknowledgement/injection; durable outbox and receipt rows | Cross-isolate DB contention needs device soak testing |
| Relay censorship/drop | Alternate candidates, fallback, custody retry, restart relearning | No mesh can guarantee delivery without a reachable path |
| Traffic analysis | Short-lived route state and no route graph persistence | BLE radio presence and packet timing remain observable |
| Sensitive logs | Metrics should contain kinds, bounded IDs, and no message text/GPS; peer identifiers must be salted/hashed before export | Current local debug logs still require deployment review |
| Operator overclaim | Timeline distinguishes signed, gateway queued, mesh forwarding, sender verified, dashboard receipt | UI must remain synchronized with server state |

## Fail-closed rules

- Never display unverified authority content.
- Reject non-P1363/incorrect-length signatures.
- Reject unknown key IDs, unknown event IDs, expired bodies, wrong sites, and oversized UTF-8 text.
- Do not upload or accept a receipt whose event ID or sender destination does not match the stored response.
- Treat a gateway command acknowledgement as queue acceptance, never as sender delivery.
- Preserve SOS scheduler priority over return-channel, voice, room, and telemetry traffic.

## Release gates

Before a field pilot, replace demo gateway authentication, complete signed manifest enrollment and key rotation/revocation, add salted peer hashing at export boundaries, review shared-site key isolation, and execute the physical BLE matrix in `docs/PHYSICAL_BLE_ACCEPTANCE.md`.
