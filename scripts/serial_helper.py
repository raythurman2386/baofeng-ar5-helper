#!/usr/bin/env python3
"""Baofeng AR-5 serial helper — STUB ONLY.

Future work may add optional serial read/write helpers for programming cables
attached at /dev/ttyUSB* or /dev/ttyACM*. This script intentionally does not
talk to any radio hardware.

Never auto-upload memory to the radio from this plugin or script.
"""

from __future__ import annotations

import sys


def main(argv: list[str]) -> int:
    print("baofeng-ar5 serial_helper: not implemented", file=sys.stderr)
    print(
        "This stub exists for a future optional serial R/W path. "
        "Use CHIRP for programming. Never auto-upload.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
