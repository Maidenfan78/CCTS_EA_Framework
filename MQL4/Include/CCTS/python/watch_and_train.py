#!/usr/bin/env python3
"""Watch for labeled CSVs and retrain models when new data arrives."""

import sys
import time
import subprocess
import logging
from pathlib import Path

from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler

# ──────────────────────────────────────────────────────────────────
# Locate repository root and vendor folder
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

VENDOR = REPO_ROOT / "vendor"
sys.path.insert(0, str(VENDOR))

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

# Paths
MT4_FILES_DIR = REPO_ROOT / "MQL4" / "Files"
PYTHON_SCRIPTS = REPO_ROOT / "MQL4" / "Include" / "CCTS" / "python"
TRAIN_SCRIPT = PYTHON_SCRIPTS / "train_model.py"
GENERATE_SCRIPT = PYTHON_SCRIPTS / "generate_signals.py"

# Settings
PYTHON_EXE = "python"
SIGNALS_PREFIX = "signals_labeled_"
MIN_ROWS = 100

# Verify paths exist
for p, name in [
    (MT4_FILES_DIR, "MT4 Files folder"),
    (TRAIN_SCRIPT, "train_model.py"),
    (GENERATE_SCRIPT, "generate_signals.py"),
]:
    if not p.exists():
        logging.error("%s not found at %s", name, p)
        sys.exit(1)

# Launch MT4
TERMINAL = Path(r"E:\MT4_4.1_STD_1\terminal.exe")
if TERMINAL.exists():
    logging.info("Launching MT4: %s /portable", TERMINAL)
    subprocess.Popen([str(TERMINAL), "/portable"])
else:
    logging.warning("MT4 not found at %s", TERMINAL)

processed = set()


def process_file(csv_path: Path):
    fname = csv_path.name
    magic = fname.replace(SIGNALS_PREFIX, "").replace(".csv", "")
    if magic in processed:
        return

    # wait a bit for file to finish writing
    time.sleep(0.5)
    try:
        with open(csv_path, "r") as f:
            rows = sum(1 for _ in f) - 1
    except Exception:
        return

    if rows < MIN_ROWS:
        return

    logging.info("New file detected: %s (%d rows)", fname, rows)
    ret = subprocess.run([PYTHON_EXE, str(TRAIN_SCRIPT), magic])
    if ret.returncode != 0:
        logging.error("train_model returned %s", ret.returncode)
        processed.add(magic)
        return

    ret = subprocess.run([PYTHON_EXE, str(GENERATE_SCRIPT), magic])
    if ret.returncode != 0:
        logging.error("generate_signals returned %s", ret.returncode)
        processed.add(magic)
        return

    logging.info("✅ Pipeline complete for magic=%s", magic)
    processed.add(magic)


class CSVHandler(PatternMatchingEventHandler):
    def __init__(self):
        super().__init__(patterns=[f"{SIGNALS_PREFIX}*.csv"], ignore_directories=True)

    def on_created(self, event):
        process_file(Path(event.src_path))

    def on_modified(self, event):
        process_file(Path(event.src_path))


def main():
    logging.info("Watching for new %s*.csv in %s", SIGNALS_PREFIX, MT4_FILES_DIR)
    observer = Observer()
    handler = CSVHandler()
    observer.schedule(handler, str(MT4_FILES_DIR), recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logging.info("Stopped by user")
    finally:
        observer.stop()
        observer.join()


if __name__ == "__main__":
    main()
