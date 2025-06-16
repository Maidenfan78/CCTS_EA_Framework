#!/usr/bin/env python3
"""
Polls MT4 "Files" folder every second for new signals_labeled_<magic>.csv,
restarts MT4 if needed, retrains models, and regenerates python_signals_<magic>.csv.
Includes a spinner and status messages to show activity, and retrains whenever a file grows.
"""

import time, subprocess, sys, itertools
from pathlib import Path

# ──────────────────────────────────────────────────────────────────
# Locate repository root by finding the "MQL4" folder
THIS_FILE = Path(__file__).resolve()
parent = THIS_FILE
REPO_ROOT = None
while parent != parent.parent:
    if (parent / "MQL4").is_dir():
        REPO_ROOT = parent
        break
    parent = parent.parent
if REPO_ROOT is None:
    print("[watch_and_train] ERROR: Could not locate 'MQL4' folder")
    sys.exit(1)

# Paths
MT4_FILES_DIR   = REPO_ROOT / "MQL4" / "Files"
PYTHON_SCRIPTS  = REPO_ROOT / "MQL4" / "Include" / "CCTS" / "python"
TRAIN_SCRIPT    = PYTHON_SCRIPTS / "train_model.py"
GENERATE_SCRIPT = PYTHON_SCRIPTS / "generate_signals.py"

# Settings
PYTHON_EXE     = "python"
SIGNALS_PREFIX = "signals_labeled_"
MIN_ROWS       = 100     # minimum rows to trigger
POLL_INTERVAL  = 1.0     # seconds

# Verify paths exist
for p, name in [(MT4_FILES_DIR, "MT4 Files folder"),
                (TRAIN_SCRIPT, "train_model.py"),
                (GENERATE_SCRIPT, "generate_signals.py")]:
    if not p.exists():
        print(f"[watch_and_train] ERROR: {name} not found at {p}")
        sys.exit(1)

# Launch MT4
TERMINAL = Path(r"E:\MT4_4.1_STD_1\terminal.exe")
if TERMINAL.exists():
    print(f"[watch_and_train] Launching MT4: {TERMINAL} /portable")
    subprocess.Popen([str(TERMINAL), "/portable"])
else:
    print(f"[watch_and_train] WARNING: MT4 not found at {TERMINAL}")

# Track last seen row-count per magic
last_rows = {}
spinner = itertools.cycle(['|', '/', '-', '\\'])

print(f"[watch_and_train] Watching for signals_labeled_<magic>.csv in {MT4_FILES_DIR}...")
print(f"[watch_and_train] Polling every {POLL_INTERVAL}s, retraining when file rows >= {MIN_ROWS} and new.")

while True:
    try:
        for csv_path in MT4_FILES_DIR.glob(f"{SIGNALS_PREFIX}*.csv"):
            fname = csv_path.name
            magic = fname.replace(SIGNALS_PREFIX, "").replace(".csv", "")

            # Count rows
            try:
                with open(csv_path, 'r') as f:
                    rows = sum(1 for _ in f) - 1
            except Exception:
                continue

            # Only consider if enough rows
            if rows < MIN_ROWS:
                continue

            # Has this file grown since last processed?
            if magic in last_rows and rows <= last_rows[magic]:
                continue

            # New or grown file → retrain
            print(f"[watch_and_train] Detected {fname} growth: {last_rows.get(magic,0)}→{rows} rows → retraining…")
            ret = subprocess.run([PYTHON_EXE, str(TRAIN_SCRIPT), magic])
            if ret.returncode != 0:
                print(f"[watch_and_train] ERROR: train_model returned {ret.returncode}")
                last_rows[magic] = rows
                continue

            ret2 = subprocess.run([PYTHON_EXE, str(GENERATE_SCRIPT), magic])
            if ret2.returncode != 0:
                print(f"[watch_and_train] ERROR: generate_signals returned {ret2.returncode}")
            else:
                print(f"[watch_and_train] ✅ Completed for magic={magic}")

            # Update last seen rows
            last_rows[magic] = rows

        # Spinner + waiting status
        ch = next(spinner)
        sys.stdout.write(f"Waiting for new bar in MT4 {ch}    \r")
        sys.stdout.flush()

        time.sleep(POLL_INTERVAL)

    except KeyboardInterrupt:
        print("\n[watch_and_train] Stopped by user.")
        break
