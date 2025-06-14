import argparse
import joblib
import pandas as pd
from sklearn.ensemble import GradientBoostingClassifier


def prepare_features(df: pd.DataFrame) -> (pd.DataFrame, pd.DataFrame):
    """Create simple technical features."""
    df = df.copy()
    df["return"] = df["Close"].pct_change().fillna(0)
    df["ma_fast"] = df["Close"].rolling(5).mean()
    df["ma_slow"] = df["Close"].rolling(20).mean()
    df["ma_diff"] = df["ma_fast"] - df["ma_slow"]
    df = df.dropna()
    features = df[["return", "ma_fast", "ma_slow", "ma_diff"]]
    return features, df


def train(df: pd.DataFrame) -> dict:
    features, df = prepare_features(df)
    targets = df[["tradeSignalLong", "tradeSignalShort", "exitSignalLong", "exitSignalShort"]]
    models = {}
    for column in targets.columns:
        model = GradientBoostingClassifier()
        model.fit(features, targets[column])
        models[column] = model
    return models


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train ML models for EA signals")
    parser.add_argument("data", help="CSV with OHLC data and target signals")
    parser.add_argument("--model", default="model.pkl", help="Output model file")
    args = parser.parse_args()

    data = pd.read_csv(args.data)
    models = train(data)
    joblib.dump(models, args.model)
    print(f"Saved models to {args.model}")

