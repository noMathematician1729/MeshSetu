# SOS return-channel operator runbook

## Normal response flow

1. Open the incident and confirm the incident is **verified** (`decrypt_status=verified`) and has an origin ephemeral ID.
2. Set the incident status before using a constrained response type: `HELP_DISPATCHED` requires `dispatched`; `INCIDENT_CLOSED` requires `resolved`.
3. Enter no more than 256 UTF-8 bytes. Select the response type and press **Sign and send response**.
4. The dashboard should show `SIGNED`, then `MESH_QUEUED`/`FORWARDING` as the gateway and relays work.
5. Do not tell a caller the message arrived until the timeline reaches `RECEIPT_AT_DASHBOARD`. That state requires the sender's verified response-delivery receipt.

## Gateway health

- `SIGNED` with no `MESH_QUEUED`: verify the gateway phone is in event mode, has the active site, and has a non-empty gateway URL/key. The command poller uses a long-poll endpoint and retries after network errors.
- `MESH_QUEUED` with no forwarding: keep the gateway and relay phones powered and within BLE range. Do not clear app storage; the response outbox is the retry boundary.
- `FORWARDING` with no receipt: inspect route/peer metrics and move a relay phone to restore a path. This is not sender delivery.
- `EXPIRED` or `FAILED`: create a new response only if the incident is still operationally relevant; never reuse an old response as proof of delivery.

## Recovery actions

1. Confirm the control-room API health endpoint.
2. Confirm the gateway phone can reach the API and has the configured gateway credential.
3. Restart event mode on the gateway phone. Its durable command/outbox rows and response IDs must survive the restart.
4. If BLE was toggled off, re-enable Bluetooth and the required permissions, then wait for HELLO relearning and a new authenticated SOS route observation.
5. If the original relay is broken, keep an alternate relay powered. The router caps reverse candidates and bounded fallback to prevent storms.
6. If the sender has not received the message before expiry, report **not delivered**; do not infer delivery from a gateway HTTP 200.

## Evidence to collect

- Response ID, event ID, response type, state timeline, and expiry.
- Sanitized metric counts: `response_forwarded`, `fallback_forwarded`, `reverse_route_miss`, `authority_signature_rejected`, `response_delivered`, and `target_send_failed`.
- Number of relay hops and approximate timestamps. Never copy authority message text, reporter GPS, raw BLE peer identifiers, or gateway secrets into an incident ticket.

## Emergency fallback

If the return channel is unavailable, keep the original SOS active, use the existing emergency-contact/SMS procedures, and communicate the limitation explicitly. The return channel is an additional signed control path, not a replacement for human emergency procedures.
