# generate_signals.py
"""
Auto-generate EA signal files named python_signals_<magic>.csv
from the latest signals_labeled_<magic>.csv and the corresponding model_<magic>.pkl.
"""
from pathlib import Path
import os, glob, joblib, pandas as pd
import sys
from train_model import prepare_features

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
    print(f"[generate_signals] ERROR: Could not locate 'MQL4' folder upward from {THIS_FILE}")
    sys.exit(1)

# Paths derived from repo root
MT4_FILES_DIR    = REPO_ROOT / "MQL4" / "Files"
PYTHON_MODEL_DIR = THIS_FILE.parent  # this 'python' folder
LABELED_PATTERN  = str(MT4_FILES_DIR / "signals_labeled_*.csv")
# ──────────────────────────────────────────────────────────────────

# Validate critical paths and fail gracefully
if not MT4_FILES_DIR.exists():
    print(f"[generate_signals] ERROR: MT4 Files directory not found at {MT4_FILES_DIR}")
    sys.exit(1)

if not PYTHON_MODEL_DIR.exists():
    print(f"[generate_signals] ERROR: Python model directory not found at {PYTHON_MODEL_DIR}")
    sys.exit(1)

# Find labeled files
files = glob.glob(LABELED_PATTERN)
if not files:
    print(f"[generate_signals] ERROR: No labeled CSV found at {MT4_FILES_DIR}")
    sys.exit(1)

# Main logic
def main():
    # 1) Most recent labeled CSV
    latest = max(files, key=os.path.getmtime)
    basename = os.path.basename(latest)
    # Extract magic
    try:
        magic = basename.split('_')[2].split('.')[0]
    except Exception:
        print(f"[generate_signals] ERROR: Unexpected filename format: {basename}")
        sys.exit(1)
    print(f"[generate_signals] Using labeled file {basename} (magic={magic})")

    # 2) Load OHLC from labeled
    df = pd.read_csv(latest, parse_dates=["Time"] if "Time" in open(latest).readline() else None)
    ohlc = df.loc[:, ["Time","Open","High","Low","Close","Volume"]]

    # 3) Features and select latest
    features = prepare_features(ohlc)
    if features.empty:
        print(f"[generate_signals] ERROR: Not enough feature rows from {basename}")
        sys.exit(1)
    latest_feat = features.iloc[-1:]

    # 4) Load corresponding model
    model_filename = f"model_{magic}.pkl"
    model_path = PYTHON_MODEL_DIR / model_filename
    if not model_path.exists():
        print(f"[generate_signals] ERROR: Model file not found: {model_path}")
        sys.exit(1)
    models = joblib.load(str(model_path))

    # 5) Predict
    preds = {name: int(model.predict(latest_feat)[0]) for name, model in models.items()}

    # 6) Write output CSV
    output_file = f"python_signals_{magic}.csv"
    output_path = MT4_FILES_DIR / output_file
    try:
        with open(output_path, "w") as f:
            f.write(
                f"{preds['tradeSignalLong']}"
                f",{preds['tradeSignalShort']}"
                f",{preds['exitSignalLong']}"
                f",{preds['exitSignalShort']}"
            )
        print(f"[generate_signals] Signals written to {output_file}")
    except Exception as e:
        print(f"[generate_signals] ERROR: Failed to write signals file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
