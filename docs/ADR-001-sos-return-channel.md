# ADR-001: Signed SOS return channel over the BLE relay overlay

- **Status:** Accepted for the Android-first pilot
- **Date:** 2026-08-25
- **Scope:** Sender → relay(s) → gateway → control room and the reverse authority path

## Decision

MeshSetu uses an additive protobuf return channel. An authority response is an `RESPONDER_UPDATE` envelope containing a signed `SignedResponderUpdate` wrapper. The authority signs the exact serialized `ResponderUpdateBody` bytes with ECDSA P-256/SHA-256 using a 64-byte IEEE P1363 signature. The active event manifest pins the authority `key_id` and public JWK; the sender resolves keys only from that active manifest.

The sender never trusts or displays response text until all of these checks pass: AEAD/site/expiry validation, response-body expiry and site match, key-ID and algorithm match, exact-body signature verification, UTF-8 length limit, and known local SOS event lookup. A verified sender receipt is the only server-side success signal.

Forward routing is destination-addressed by the sender's fixed-width ephemeral ID. Relays learn short-lived reverse-route candidates only after authenticated SOS validation and before object dedupe. The route cache is local, event-scoped, expiry-bounded, capped at two candidates, excludes ingress, and falls back to a bounded set of currently connected peers. Failed sends remain in the durable response outbox for retry.

## Why

Broadcasting authority traffic would create response storms, expose control traffic to unrelated peers, and make delivery status ambiguous. A route cache provides a useful reverse hint without persisting a device graph or making a stale BLE session authoritative. Signed bodies prevent a relay or gateway from changing operator text while AEAD protects transport custody and site scope.

The gateway is an ordinary mesh participant plus an HTTP bridge. It persists a command before injecting it into the mesh. Gateway command acknowledgement means only that the gateway accepted the signed response; it does not mean sender delivery. `RECEIPT_AT_DASHBOARD` is reached only after a response-delivery ACK from the sender is received and validated against the original event and destination ID.

## Rejected alternatives

1. **HMAC authority responses:** rejected because every verifier would need a shared signing secret and a compromised relay could forge authority text.
2. **Re-serialize decoded protobuf for verification:** rejected because protobuf field ordering/unknown-field preservation can change the signed bytes. Verification uses the wrapper's carried body bytes.
3. **Unbounded broadcast return traffic:** rejected because it violates bounded traffic and makes alternate routing/observability impossible.
4. **Claim success after gateway receipt:** rejected because it lies to the operator and sender when the final BLE return path is broken.

## Consequences

- Authority key provisioning and manifest rotation are security-sensitive operations.
- Route state is deliberately local and short-lived; process restart requires HELLO and SOS relearning.
- The current pilot still uses demo gateway credentials and a demo manifest ceremony; production enrollment and key rotation remain release gates.
- SOS priority remains above authority control, voice evidence, room traffic, and telemetry.
