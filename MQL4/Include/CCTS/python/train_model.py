#!/usr/bin/env python3
"""
Train ML models on labeled MT4 data and save artifacts with metadata.
"""
import os
import sys
import json
import logging
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
MT4_FILES_DIR    = REPO_ROOT / "MQL4" / "Files"
PYTHON_MODEL_DIR = THIS_FILE.parent  # 'python' folder

# Constants
SEED = 42
CONFIG_PATH = THIS_FILE.parent / "config.json"

# Load hyperparameters from config.json if exists
if CONFIG_PATH.exists():
    with open(CONFIG_PATH) as f:
        config = json.load(f)
else:
    config = {
        "n_estimators": 100,
        "learning_rate": 0.1,
        "max_depth": 3
    }
    logging.info("Using default hyperparameters: %s", config)


def prepare_features(df: pd.DataFrame) -> pd.DataFrame:
    df2 = df.copy()
    df2['return']  = df2['Close'].pct_change().fillna(0)
    df2['ma_fast'] = df2['Close'].rolling(5).mean()
    df2['ma_slow'] = df2['Close'].rolling(20).mean()
    df2['ma_diff'] = df2['ma_fast'] - df2['ma_slow']
    return df2.dropna()[['return', 'ma_fast', 'ma_slow', 'ma_diff']]


def train(df: pd.DataFrame) -> dict:
    features = prepare_features(df)
    targets  = df.loc[features.index, [
        'tradeSignalLong', 'tradeSignalShort', 'exitSignalLong', 'exitSignalShort'
    ]]
    models = {}
    for col in targets.columns:
        y = targets[col]
        unique = y.unique()
        if len(unique) < 2:
            logging.warning("Only one class (%s) for '%s', using DummyClassifier.", unique[0], col)
            clf = DummyClassifier(strategy='constant', constant=unique[0], random_state=SEED)
        else:
            clf = GradientBoostingClassifier(
                n_estimators=config['n_estimators'],
                learning_rate=config['learning_rate'],
                max_depth=config['max_depth'],
                random_state=SEED
            )
        clf.fit(features, y)
        models[col] = clf
    logging.info("Trained models for: %s", list(models.keys()))
    return models


def main():
    if len(sys.argv) < 2:
        logging.error("No magic number passed.")
        sys.exit(1)
    magic = sys.argv[1]
    csv_file = f"signals_labeled_{magic}.csv"
    csv_path = MT4_FILES_DIR / csv_file
    if not csv_path.exists():
        logging.error("Labeled CSV not found: %s", csv_path)
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
