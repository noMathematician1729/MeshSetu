#!/usr/bin/env python3
"""Summarize MeshSetu NDJSON metrics without exporting peer identifiers."""
from __future__ import annotations

import argparse
import json
import statistics
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable


def records(lines: Iterable[str]):
    for line in lines:
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict) and isinstance(value.get("kind"), str):
            yield value


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    values = sorted(values)
    index = min(len(values) - 1, max(0, round((len(values) - 1) * fraction)))
    return values[index]


def summarize(rows: Iterable[dict]) -> dict:
    rows = list(rows)
    counts = Counter(row["kind"] for row in rows)
    latencies = [float(row["value"]) for row in rows if row["kind"] == "object_latency_ms" and isinstance(row.get("value"), (int, float))]
    terminal = sum(counts[k] for k in ("response_delivered", "response_expired", "reverse_route_miss"))
    delivered = counts["response_delivered"]
    return {
        "metric_records": len(rows),
        "metric_counts": dict(sorted(counts.items())),
        "object_latency_ms": {
            "count": len(latencies),
            "median": statistics.median(latencies) if latencies else None,
            "p95": percentile(latencies, 0.95),
        },
        "authority_response": {
            "signed_or_queued": counts["response_signed"] + counts["response_forwarded"],
            "forwarded": counts["response_forwarded"] + counts["fallback_forwarded"],
            "sender_verified": delivered,
            "receipt_at_dashboard": counts["receipt_at_dashboard"],
            "signature_rejected": counts["authority_signature_rejected"],
            "expired": counts["response_expired"],
            "route_misses": counts["reverse_route_miss"],
            "observed_terminal_delivery_ratio": delivered / terminal if terminal else None,
        },
        "privacy": {
            "raw_peer_ids_exported": False,
            "message_text_exported": False,
            "gps_exported": False,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", type=Path, help="NDJSON files; stdin when omitted")
    args = parser.parse_args()
    if args.files:
        rows = records(line for path in args.files for line in path.read_text().splitlines())
    else:
        rows = records(sys.stdin)
    json.dump(summarize(rows), sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
