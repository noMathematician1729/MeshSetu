# MeshSetu return-channel observability

## Metric envelope

Mobile metrics are newline-delimited JSON with a `kind`, timestamp, optional bounded numeric value, object ID, peer hint, and detail. The local sink is for debugging and acceptance evidence; it is not an analytics feed. Do not add message text, reporter identity, GPS, keys, signatures, or raw packet bytes to metrics.

Before exporting metrics off-device, replace peer/session hints with a rotating, deployment-salted hash. Fixed-width ephemeral IDs are routing identifiers, not user identity, and should be retained only for the shortest event window needed to diagnose delivery.

## Return-channel vocabulary

| Metric | Meaning |
|---|---|
| `reverse_route_learned` | Authenticated SOS created/updated a bounded reverse candidate |
| `reverse_route_miss` | No eligible candidate/fallback; durable retry remains |
| `response_forwarded` | A cached or alternate route accepted a targeted write |
| `fallback_forwarded` | Bounded connected-peer fallback accepted a targeted write |
| `target_peer_miss` / `target_peer_stale` | Destination ID had no current session |
| `target_send_failed` / `target_send_mtu_rejected` | Targeted write failed or could not fit |
| `response_duplicate_drop` | Response ID replay was suppressed |
| `authority_signature_rejected` | Trust, cryptographic, event, or message guard failed |
| `response_delivered` | Sender verified and persisted the response |
| `response_expired` | Response/body/route/hop window ended |
| `custody_ack_received` | Ordinary mesh custody, not sender authority delivery |

## Dashboards and SLO-style summaries

Use `tools/meshsetu_log_parser.py` to compute:

- object latency median and P95 from `object_latency_ms` values;
- authority response attempts, forwarding, verified sender delivery, and receipt-at-dashboard counts;
- route misses, fallback usage, signature rejection, expiry, and targeted-send failures;
- a conservative delivery ratio based only on terminal observed outcomes.

The parser intentionally emits counts and quantiles, not raw peer identifiers. A successful gateway command or custody ACK must never be counted as sender delivery.

## Acceptance evidence

For every physical test, save the sanitized parser JSON alongside:

- topology and device roles;
- whether Wi-Fi/mobile data were disabled;
- MTU and Android versions;
- failure injection used;
- response/event expiry window;
- observed final state and whether a verified receipt reached the server.
