#!/usr/bin/env python3
"""Generate EA signal files from labeled CSVs and trained models."""
import sys
import json
import logging
from pathlib import Path

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
    logging.error("Could not locate 'MQL4' folder upward from %s", THIS_FILE)
    sys.exit(1)

VENDOR = REPO_ROOT / "vendor"
sys.path.insert(0, str(VENDOR))

import pandas as pd
import joblib
from train_model import prepare_features

# Initialize logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

# Paths
MT4_FILES_DIR    = REPO_ROOT / "MQL4" / "Files"
PYTHON_MODEL_DIR = THIS_FILE.parent  # this 'python' folder


def main():
    # Parse magic argument
    if len(sys.argv) < 2:
        logging.error("No magic number passed.")
        sys.exit(1)
    magic = sys.argv[1]

    csv_file = f"signals_labeled_{magic}.csv"
    model_file = f"model_{magic}.pkl"
    out_file = f"python_signals_{magic}.csv"

    csv_path = MT4_FILES_DIR / csv_file
    model_path = PYTHON_MODEL_DIR / model_file
    out_path = MT4_FILES_DIR / out_file

    # Validate paths
    if not csv_path.exists():
        logging.error("Labeled CSV not found: %s", csv_path)
        sys.exit(1)
    if not model_path.exists():
        logging.error("Model file not found: %s", model_path)
        sys.exit(1)

    logging.info("Generating signals for magic %s from %s", magic, csv_file)

    # Load labeled CSV
    try:
        df = pd.read_csv(csv_path, usecols=["Time","Open","High","Low","Close","Volume"], parse_dates=["Time"])
    except pd.errors.EmptyDataError:
        logging.error("CSV is empty: %s", csv_path)
        sys.exit(1)
    except Exception as e:
        logging.error("Failed to read CSV: %s", e)
        sys.exit(1)

    # Compute features and select the latest row
    features = prepare_features(df)
    if features.empty:
        logging.error("Not enough data to compute features from %s", csv_file)
        sys.exit(1)
    latest_feat = features.iloc[-1:]

    # Load model
    try:
        models = joblib.load(model_path)
    except Exception as e:
        logging.error("Failed to load model: %s", e)
        sys.exit(1)

    # Predict
    preds = {}
    for name, model in models.items():
        val = int(model.predict(latest_feat)[0])
        if val not in (0, 1):
            logging.warning("Unexpected prediction for %s: %s", name, val)
        preds[name] = val

    # Write output CSV
    try:
        out_path.write_text(
            ",".join(str(preds[key]) for key in [
                "tradeSignalLong", "tradeSignalShort", "exitSignalLong", "exitSignalShort"
            ])
        )
        logging.info("Signals written to %s", out_file)
    except Exception as e:
        logging.error("Failed to write signals file: %s", e)
        sys.exit(1)

    # Optional: save metadata alongside signals
    meta = {
        "magic": magic,
        "timestamp": pd.Timestamp.now().isoformat(),
        "predictions": preds
    }
    meta_path = MT4_FILES_DIR / f"python_signals_{magic}_meta.json"
    try:
        meta_path.write_text(json.dumps(meta, indent=2))
        logging.info("Saved signal metadata: %s", meta_path.name)
    except Exception as e:
        logging.warning("Failed to write metadata: %s", e)


if __name__ == "__main__":
    main()
