# MeshSetu BLE reference boundary

MeshSetu uses its existing Flutter architecture and protocol wire format. The
RedGridLink implementation was consulted only as a behavioral reference for:

- serialized advertiser start/stop transitions and native failure reporting;
- service-filtered scanning with bounded reconnect attempts;
- negotiated-MTU-aware application fragmentation; and
- persistent foreground-service operation and diagnostics.

MeshSetu does not copy RedGridLink's domain model, sync engine, frame protocol,
encryption, or persistence implementation. The application continues to use
`MeshGatt`, `Hello`, `MeshFrame`, `MeshEnvelope`, `EventManifest`, AES-GCM
envelopes, and its own durable outbox/inbox state machine.

The reference project is MIT licensed with a Commons Clause. This note records
the behavioral provenance and the deliberate reimplementation boundary; no
substantive source reuse is intended.
