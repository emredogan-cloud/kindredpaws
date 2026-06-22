#!/usr/bin/env bash
# Summarize line coverage from coverage/lcov.info and enforce MIN_COVERAGE.
# Env: MIN_COVERAGE (default 60).
set -euo pipefail

LCOV="coverage/lcov.info"
MIN="${MIN_COVERAGE:-60}"

if [ ! -f "$LCOV" ]; then
  echo "No $LCOV found. Run: flutter test --coverage"
  exit 1
fi

python3 - "$MIN" "$LCOV" <<'PY'
import sys, pathlib
target = float(sys.argv[1])
p = pathlib.Path(sys.argv[2])
lf = lh = 0
for line in p.read_text().splitlines():
    if line.startswith("LF:"):
        lf += int(line[3:])
    elif line.startswith("LH:"):
        lh += int(line[3:])
pct = (lh / lf * 100) if lf else 0.0
print(f"Line coverage: {pct:.1f}%  ({lh}/{lf} lines)  threshold {target:.1f}%")
sys.exit(0 if pct + 1e-9 >= target else 1)
PY
