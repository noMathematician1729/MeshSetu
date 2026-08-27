# Physical BLE acceptance matrix

These checks cannot be closed by unit tests. Run on at least three Android BLE-capable phones with event mode visible and permissions granted. Record Android/OEM, app build, negotiated MTU, topology, timestamps, and sanitized metrics.

| Test | Setup | Pass condition |
|---|---|---|
| 1-hop SOS | Sender ↔ gateway, Wi-Fi/mobile data off on sender | Structured SOS arrives at gateway/control-room path with authenticated event data |
| 2-hop offline | Sender ↔ relay ↔ gateway, internet off except gateway | SOS reaches gateway; relay custody/reverse route metrics are present |
| 3-hop | Sender ↔ relay A ↔ relay B ↔ gateway | SOS reaches gateway within expiry and without duplicate UI incident |
| Broken original relay | Learn two candidates, power off first relay | Return response uses alternate/fallback route and does not claim delivery without sender receipt |
| Duplicate path | Two relays forward the same object | One persistence/display; duplicate metrics are bounded |
| Priority under load | Start voice transfer, inject P0 SOS | Structured SOS preempts lower-priority transfer on the real radio |
| Restart | Kill/restart gateway or relay process mid-response | Durable command/outbox resumes; response ID is not duplicated |
| Bluetooth toggle | Toggle Bluetooth off/on during route | Service recovers or reports blocked state; no fabricated delivery state |
| Low MTU | Force/observe negotiated MTU near minimum | Structured SOS remains actionable; oversized evidence defers cleanly |
| Gateway LAN outage | Disconnect gateway internet/LAN after command persistence | Local mesh retry remains; UI says queued/forwarding, not delivered |

## Procedure

1. Join all phones to the same signed event manifest and verify the authority key ID is identical.
2. Record sender ephemeral ID and response ID only in the protected test log; export only salted/anonymized evidence.
3. Run the scenario at least ten times for 1-hop and 2-hop. Run each failure scenario at least three times.
4. Disable all non-gateway internet links for offline cases. Do not use a simulator as a substitute for radio validation.
5. Confirm the server state reaches `RECEIPT_AT_DASHBOARD` only after the sender displays verified text and the gateway uploads the response-delivery receipt.
6. Attach parser output from `tools/meshsetu_log_parser.py` and note any manual intervention.

## Blocking failures

Any forged/tampered response displayed, wrong-site response accepted, sender delivery claimed before receipt, SOS starvation under load, silent loss across process restart, or raw sensitive data exported in metrics is a release blocker.
