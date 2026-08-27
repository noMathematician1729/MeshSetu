#!/usr/bin/env python3
"""Deterministic logical SOS return-channel simulator.

This is not a BLE or cryptography substitute. It exercises bounded route,
alternate/fallback, duplicate, and restart acceptance scenarios and emits the
same metric-shaped NDJSON consumed by meshsetu_log_parser.py.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass


@dataclass(frozen=True)
class SimulationConfig:
    hops: int = 2
    failed_relay: int | None = None
    duplicates: int = 0
    restart: bool = False


def simulate(config: SimulationConfig) -> list[dict]:
    if config.hops < 1 or config.hops > 6:
        raise ValueError("hops must be between 1 and 6")
    rows: list[dict] = []
    rows.append({"kind": "sos_submitted", "objectId": 1001, "value": 0})
    for hop in range(config.hops):
        rows.append({"kind": "reverse_route_learned", "objectId": 1001, "value": hop + 1})
    if config.restart:
        rows.append({"kind": "mesh_restart", "detail": "durable_state_reloaded"})
    rows.append({"kind": "sos_verified_at_gateway", "objectId": 1001, "value": config.hops})

    if config.failed_relay is None:
        rows.append({"kind": "response_forwarded", "objectId": 2001, "value": config.hops, "detail": "reverseCache"})
    else:
        rows.append({"kind": "target_send_failed", "objectId": 2001, "value": config.failed_relay})
        rows.append({"kind": "response_forwarded", "objectId": 2001, "value": config.hops, "detail": "alternateCache"})
    rows.append({"kind": "response_delivered", "objectId": 2001, "value": config.hops + 1})
    rows.append({"kind": "receipt_at_dashboard", "objectId": 2001, "value": config.hops + 2})
    for _ in range(config.duplicates):
        rows.append({"kind": "response_duplicate_drop", "objectId": 2001})
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hops", type=int, default=2)
    parser.add_argument("--failed-relay", type=int)
    parser.add_argument("--duplicates", type=int, default=0)
    parser.add_argument("--restart", action="store_true")
    args = parser.parse_args()
    config = SimulationConfig(args.hops, args.failed_relay, args.duplicates, args.restart)
    for row in simulate(config):
        json.dump(row, sys.stdout, separators=(",", ":"))
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
