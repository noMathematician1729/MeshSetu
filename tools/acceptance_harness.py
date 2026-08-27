#!/usr/bin/env python3
"""Run deterministic return-channel acceptance checks."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

from meshsetu_packet_simulator import SimulationConfig, simulate
from meshsetu_log_parser import summarize


def check(config: SimulationConfig) -> dict:
    rows = simulate(config)
    summary = summarize(rows)
    counts = summary["metric_counts"]
    assert counts.get("sos_verified_at_gateway") == 1
    assert counts.get("response_delivered") == 1
    assert counts.get("receipt_at_dashboard") == 1
    assert summary["privacy"]["raw_peer_ids_exported"] is False
    if config.failed_relay is not None:
        assert counts.get("target_send_failed") == 1
        assert counts.get("response_forwarded") == 1
    if config.duplicates:
        assert counts.get("response_duplicate_drop") == config.duplicates
    return summary


def main() -> int:
    cases = [
        SimulationConfig(hops=1),
        SimulationConfig(hops=2, failed_relay=0, duplicates=2, restart=True),
        SimulationConfig(hops=3),
    ]
    results = [check(case) for case in cases]
    # Also exercise the command-line parser as the operator will use it.
    simulator = Path(__file__).with_name("meshsetu_packet_simulator.py")
    parser = Path(__file__).with_name("meshsetu_log_parser.py")
    ndjson = subprocess.check_output([sys.executable, str(simulator), "--hops", "2", "--duplicates", "1"], text=True)
    parsed = subprocess.check_output([sys.executable, str(parser)], input=ndjson, text=True)
    command_summary = json.loads(parsed)
    assert command_summary["metric_counts"]["response_delivered"] == 1
    print(json.dumps({"ok": True, "cases": len(results), "cli_parser": command_summary}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
