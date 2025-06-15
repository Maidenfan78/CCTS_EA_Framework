# generate_signals.py

import argparse
import joblib
import pandas as pd

from train_model import prepare_features


def generate_signals(model_path: str, data_path: str, output_path: str):
    models = joblib.load(model_path)
    df = pd.read_csv(data_path)
    features, _ = prepare_features(df)
    latest = features.iloc[-1:]

    preds = {
        name: int(models[name].predict(latest)[0])
        for name in models.keys()
    }

    with open(output_path, "w") as f:
        f.write(
            f"{preds['tradeSignalLong']},{preds['tradeSignalShort']},{preds['exitSignalLong']},{preds['exitSignalShort']}"
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate signals for the EA")
    parser.add_argument("data", help="CSV with latest OHLC data")
    parser.add_argument("--model", default="model.pkl", help="Trained model file")
    parser.add_argument(
        "--output",
        default="../Tester/Files/python_signals.csv",
        help="Where to write the signal file",
    )
    args = parser.parse_args()

    generate_signals(args.model, args.data, args.output)
    print(f"Signals written to {args.output}")

