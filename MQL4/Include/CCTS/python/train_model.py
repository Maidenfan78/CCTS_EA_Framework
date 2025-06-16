#!/usr/bin/env python3
"""Train ML models on labeled MT4 data and save artifacts with metadata."""
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
    logging.error("Could not locate 'MQL4' folder upward from %s", THIS_FILE)
    sys.exit(1)

VENDOR = REPO_ROOT / "vendor"
sys.path.insert(0, str(VENDOR))

import pandas as pd
import joblib
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.dummy import DummyClassifier

# Initialize logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

# Paths
MT4_FILES_DIR    = REPO_ROOT / "MQL4" / "Files"
PYTHON_MODEL_DIR = THIS_FILE.parent  # 'python' folder

# Constants
SEED = 42
CONFIG_PATH = THIS_FILE.parent / "config.json"


def load_config() -> dict:
    """Return hyperparameter configuration."""
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH) as f:
            return json.load(f)
    default = {
        "n_estimators": 100,
        "learning_rate": 0.1,
        "max_depth": 3,
    }
    logging.info("Using default hyperparameters: %s", default)
    return default


config = load_config()


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

    logging.info("Loading data from %s", csv_path)
    try:
        df = pd.read_csv(csv_path, parse_dates=['Time'])
    except Exception as e:
        logging.error("Failed to read CSV: %s", e)
        sys.exit(1)

    features = prepare_features(df)
    if features.empty:
        logging.error("Not enough data to compute features from %s", csv_file)
        sys.exit(1)

    models = train(df)

    PYTHON_MODEL_DIR.mkdir(parents=True, exist_ok=True)
    model_filename = f"model_{magic}.pkl"
    model_path     = PYTHON_MODEL_DIR / model_filename
    joblib.dump(models, model_path)

    if not model_path.exists():
        logging.error("Model save failed: %s", model_path)
        sys.exit(1)

    # Save metadata
    meta = {
        "magic": magic,
        "timestamp": pd.Timestamp.now().isoformat(),
        "rows": len(df),
        "config": config,
        "class_counts": df[['tradeSignalLong', 'tradeSignalShort', 'exitSignalLong', 'exitSignalShort']]
                             .iloc[features.index].apply(pd.Series.value_counts).to_dict()
    }
    meta_path = PYTHON_MODEL_DIR / f"model_{magic}_meta.json"
    with open(meta_path, 'w') as f:
        json.dump(meta, f, indent=2)
    logging.info("Saved model and metadata: %s", model_filename)


if __name__ == '__main__':
    main()
