# train_model.py
"""
Find the most recent signals_labeled_<magic>.csv in MT4/Files,
train models on it, and save model_<magic>.pkl in the python folder.
"""
from pathlib import Path
import os, glob, joblib, pandas as pd
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.dummy import DummyClassifier
import sys

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
    print(f"[train_model] ERROR: Could not locate 'MQL4' folder upward from {THIS_FILE}")
    sys.exit(1)

# Paths derived from repo root
MT4_FILES_DIR    = REPO_ROOT / "MQL4" / "Files"
PYTHON_MODEL_DIR = THIS_FILE.parent  # this 'python' folder
LABELED_PATTERN  = str(MT4_FILES_DIR / "signals_labeled_*.csv")
# ──────────────────────────────────────────────────────────────────

# Validate paths before doing any work
if not MT4_FILES_DIR.exists():
    print(f"[train_model] ERROR: MT4 Files folder not found at {MT4_FILES_DIR}")
    sys.exit(1)

# Grab the list of label files
files = glob.glob(LABELED_PATTERN)
if not files:
    print(f"[train_model] ERROR: No signals_labeled_*.csv in {MT4_FILES_DIR}")
    sys.exit(1)


def prepare_features(df: pd.DataFrame) -> pd.DataFrame:
    df2 = df.copy()
    df2["return"]  = df2["Close"].pct_change().fillna(0)
    df2["ma_fast"] = df2["Close"].rolling(5).mean()
    df2["ma_slow"] = df2["Close"].rolling(20).mean()
    df2["ma_diff"] = df2["ma_fast"] - df2["ma_slow"]
    return df2.dropna()[["return","ma_fast","ma_slow","ma_diff"]]


def train(df: pd.DataFrame) -> dict:
    features = prepare_features(df)
    targets  = df.loc[features.index, [
        "tradeSignalLong","tradeSignalShort","exitSignalLong","exitSignalShort"
    ]]
    models = {}
    for col in targets.columns:
        y = targets[col]
        unique = y.unique()
        if len(unique) < 2:
            print(f"[train_model] WARNING: Only one class ({unique[0]}) for '{col}', using constant DummyClassifier.")
            clf = DummyClassifier(strategy='constant', constant=unique[0])
            clf.fit(features, y)
        else:
            clf = GradientBoostingClassifier()
            clf.fit(features, y)
        models[col] = clf
    return models


def main():
    # 1) locate latest labeled CSV
    latest = max(files, key=os.path.getmtime)
    magic  = Path(latest).stem.split("_")[2]
    print(f"[train_model] Training on {Path(latest).name} (magic={magic})")

    # 2) load data and prepare features
    df = pd.read_csv(latest, parse_dates=["Time"] if "Time" in open(latest).readline() else None)
    features = prepare_features(df)
    if features.empty:
        print(f"[train_model] ERROR: Not enough data to compute features from {latest}")
        sys.exit(1)

    # 3) train models
    models = train(df)

    # 4) save model_<magic>.pkl
    PYTHON_MODEL_DIR.mkdir(parents=True, exist_ok=True)
    model_filename = f"model_{magic}.pkl"
    model_path     = PYTHON_MODEL_DIR / model_filename
    joblib.dump(models, str(model_path))
    print(f"[train_model] Saved models to {model_path}")

if __name__ == "__main__":
    main()
