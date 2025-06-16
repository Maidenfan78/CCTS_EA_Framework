#!/usr/bin/env python3
import sys
import os
import time
import subprocess
import itertools
import psutil
import logging
from pathlib import Path
import pandas as pd
import joblib

"""
watch_and_train.py:
- Launches MT4 once.
- Polls for new or updated CSVs.
- Trains on initial detection and retrains on growth.
- Calls external generate_signals.py once per change.
"""

# ──────────────────────────────────────────────────────────────────
# Setup
THIS_FILE = Path(__file__).resolve()
# find repo root
parent = THIS_FILE
REPO_ROOT = None
while parent != parent.parent:
    if (parent / 'MQL4').is_dir():
        REPO_ROOT = parent
        break
    parent = parent.parent
if REPO_ROOT is None:
    logging.error('Could not locate MQL4 folder')
    sys.exit(1)

# paths
MT4_FILES_DIR    = REPO_ROOT / 'MQL4' / 'Files'
GENERATE_SCRIPT  = THIS_FILE.parent / 'generate_signals.py'
PYTHON_EXE       = 'python'
TERMINAL         = Path(r'E:\MT4_4.1_STD_1\terminal.exe')

# settings
SIGNALS_PREFIX   = 'signals_labeled_'
MIN_ROWS         = 100
POLL_INTERVAL    = 1.0  # seconds

# logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s: %(message)s')

# feature engineering stub
def prepare_features(df: pd.DataFrame) -> pd.DataFrame:
    # TODO: insert your feature pipeline
    return df

# training stub
def train_model(magic: str) -> bool:
    csv_path   = MT4_FILES_DIR / f'{SIGNALS_PREFIX}{magic}.csv'
    model_path = THIS_FILE.parent / f'model_{magic}.pkl'
    if not csv_path.exists():
        logging.error('CSV missing for training: %s', csv_path)
        return False
    try:
        df = pd.read_csv(
            csv_path,
            usecols=['Time','Open','High','Low','Close','Volume'],
            parse_dates=['Time']
        )
    except Exception as e:
        logging.error('Error reading CSV: %s', e)
        return False

    feats = prepare_features(df)
    if feats.empty:
        logging.error('No features for %s', magic)
        return False

    # TODO: actual model fitting
    models = {'model': None}
    try:
        joblib.dump(models, model_path)
        logging.info('Saved model_%s.pkl', magic)
    except Exception as e:
        logging.error('Error saving model: %s', e)
        return False

    return True

# launch MT4 once
def is_mt4_running():
    for proc in psutil.process_iter(['exe']):
        try:
            if proc.info['exe'] and Path(proc.info['exe']).resolve() == TERMINAL.resolve():
                return True
        except Exception:
            continue
    return False

if TERMINAL.exists():
    if not is_mt4_running():
        logging.info('Launching MT4')
        subprocess.Popen([str(TERMINAL), '/portable'])
    else:
        logging.info('MT4 already running')
else:
    logging.warning('MT4 terminal missing: %s', TERMINAL)

# watch loop
last_rows = {}
spinner   = itertools.cycle(['|','/','-','\\'])
logging.info('Watching for CSVs in %s', MT4_FILES_DIR)

while True:
    try:
        # scan files
        for csv_path in MT4_FILES_DIR.glob(f'{SIGNALS_PREFIX}*.csv'):
            magic = csv_path.stem.replace(SIGNALS_PREFIX, '')

            # count rows minus header
            try:
                rows = sum(1 for _ in csv_path.open()) - 1
            except Exception:
                continue

            # skip until threshold
            if rows < MIN_ROWS:
                continue

            prev = last_rows.get(magic)
            if prev is not None and rows == prev:
                # no change
                continue

            # initial or updated
            if prev is None:
                logging.info('New file %s with %d rows', magic, rows)
            else:
                logging.info('File %s grew %d->%d rows', magic, prev, rows)

            # train
            if train_model(magic):
                # generate signals
                ret = subprocess.run([PYTHON_EXE, str(GENERATE_SCRIPT), magic])
                if ret.returncode == 0:
                    logging.info('Generated signals for %s', magic)
                else:
                    logging.error('generate_signals failed: %s', magic)

            # update state
            last_rows[magic] = rows

        # spinner + wait
        ch = next(spinner)
        sys.stdout.write(f'Waiting {ch}\r')
        sys.stdout.flush()
        time.sleep(POLL_INTERVAL)

    except KeyboardInterrupt:
        logging.info('Stopped by user')
        break
