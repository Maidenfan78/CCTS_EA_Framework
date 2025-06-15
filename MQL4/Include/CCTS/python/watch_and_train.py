# watch_and_train.py
"""
Watches MT4 "Files" folder for new/updated signals_labeled_<magic>.csv,
restarts MT4 if needed, retrains models, and regenerates python_signals_<magic>.csv.
Includes a spinner to show activity while waiting for new bars.
"""
from pathlib import Path
import time, subprocess, os, sys, glob
import itertools
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# ──────────────────────────────────────────────────────────────────
# Dynamically locate the repo root by finding the "MQL4" folder
THIS_FILE = Path(__file__).resolve()
parent = THIS_FILE
REPO_ROOT = None
while parent != parent.parent:
    if (parent / "MQL4").is_dir():
        REPO_ROOT = parent
        break
    parent = parent.parent
if REPO_ROOT is None:
    print(f"[watch_and_train] ERROR: Could not locate 'MQL4' folder upward from {THIS_FILE}")
    sys.exit(1)

# Paths derived from repo root
MT4_FILES_DIR   = REPO_ROOT / "MQL4" / "Files"
PYTHON_SCRIPTS  = REPO_ROOT / "MQL4" / "Include" / "CCTS" / "python"
TRAIN_SCRIPT    = PYTHON_SCRIPTS / "train_model.py"
GENERATE_SCRIPT = PYTHON_SCRIPTS / "generate_signals.py"

# Execution settings
PYTHON_EXE      = "python"                   # or full path to python.exe
SIGNALS_PREFIX  = "signals_labeled_"         # prefix for CSV files
DEBOUNCE_SEC    = 2                            # seconds to debounce events
MIN_ROWS        = 100                          # require at least this many rows before training

# Validate critical paths and fail gracefully
for name, path in [
    ("MT4 Files directory", MT4_FILES_DIR),
    ("Train script", TRAIN_SCRIPT),
    ("Generate script", GENERATE_SCRIPT)
]:
    if not path.exists():
        print(f"[watch_and_train] ERROR: {name} not found at {path}")
        sys.exit(1)

# Debounce tracker for file events
events_last = {}

class SignalsHandler(FileSystemEventHandler):
    def on_created(self, event):
        self.on_modified(event)

    def on_modified(self, event):
        fname = os.path.basename(event.src_path)
        now = time.time()
        prev = events_last.get(fname, 0)
        if now - prev < DEBOUNCE_SEC:
            return

        if fname.startswith(SIGNALS_PREFIX) and fname.endswith('.csv'):
            fullpath = event.src_path
            # count lines (minus header)
            try:
                with open(fullpath, 'r') as f:
                    rows = sum(1 for _ in f) - 1
            except PermissionError:
                # File is locked by MT4—skip this event
                print(f"[watch_and_train] Skipping {fname}: file locked (permission denied)")
                return
            except Exception as e:
                print(f"[watch_and_train] ERROR reading {fullpath}: {e}")
                return

            if rows < MIN_ROWS:
                print(f"[watch_and_train] Skipping {fname}: only {rows} rows (<{MIN_ROWS})")
                return

            print(f"[watch_and_train] Detected {fname} ({rows} rows) → retraining & regenerating signals…")
            # retrain
            ret = subprocess.run([PYTHON_EXE, str(TRAIN_SCRIPT)])
            if ret.returncode != 0:
                print(f"[watch_and_train] ERROR: train_model.py returned {ret.returncode}")
            # generate signals
            ret2 = subprocess.run([PYTHON_EXE, str(GENERATE_SCRIPT)])
            if ret2.returncode != 0:
                print(f"[watch_and_train] ERROR: generate_signals.py returned {ret2.returncode}")
            else:
                print("[watch_and_train] Completed retrain & generate.")
            events_last[fname] = now

if __name__ == '__main__':
    # Launch MT4 portable instance
    terminal_path = Path(r"E:\MT4_4.1\terminal.exe")
    if terminal_path.exists():
        print(f"[watch_and_train] Launching MT4: {terminal_path} /portable")
        subprocess.Popen([str(terminal_path), "/portable"])
    else:
        print(f"[watch_and_train] WARNING: MT4 terminal not found at {terminal_path}")

    # Start watcher
    observer = Observer()
    try:
        observer.schedule(SignalsHandler(), str(MT4_FILES_DIR), recursive=False)
    except Exception as e:
        print(f"[watch_and_train] ERROR: Failed to watch {MT4_FILES_DIR}: {e}")
        sys.exit(1)

    observer.start()
    print(f"[watch_and_train] Watching {MT4_FILES_DIR} for {SIGNALS_PREFIX}<magic>.csv...")

                # Spinner + status message for indicating waiting for a new bar
    spinner = itertools.cycle(['|', '/', '-', '\\'])
    status  = "Waiting for new bar in MT4"
    try:
        while True:
            ch = next(spinner)
            sys.stdout.write(f"{status} {ch}")
            sys.stdout.flush()
            time.sleep(0.1)
            sys.stdout.write("\r")  # carriage return to overwrite line
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

