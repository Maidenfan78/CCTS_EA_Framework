# 🧠 CCTS EA Framework – Modular Expert Advisor for MetaTrader 4 (MT4)

Welcome to the **CCTS_EA_Framework** by [Maidenfan78](https://github.com/Maidenfan78) – a **modular Expert Advisor system written in MQL4** for MetaTrader 4. Designed with reusability and clean architecture in mind, this framework makes it easy to build and test trading strategies, including breakout, ATR-based, pivot point, and ICT-style logic.

---

## 📁 Project Structure

MQL4/
├── Experts/
│ └── CCTS_Breakout.mq4 # Main Expert Advisor file
├── Include/
│ └── CCTS/
│ ├── CCTS_*.mqh # Core utility modules (SL/TP, lots, logging, time, etc.)
│ ├── EaSetup/
│ │ ├── Breakout_Setup.mqh # Strategy-specific inputs
│ │ └── Breakout_Signals.mqh # Signal generation logic
│ ├── Indicators/
│ │ ├── V1/ # Volume indicators (e.g., OBV with MA)
│ │ ├── Ex1/ # Exit indicators (e.g., Rex). The main exit indicator. Exit trades if they go south and hit stop loss.
│ │ ├── Ex2/ # Alternate exit indicators. Used as a slower exit. Optimise to use when runner trad is left
│ │ ├── BL2/ # Baseline trend filters
│ │ ├── C1/ # Confirmation indicator 1
│ │ ├── C2/ # Confirmation indicator 2
│ │ └── IndicatorSetBreakout.mqh # Indicators used by EA
│ └── python/ # Python integration scripts
│ ├── train_model.py # Train ML models
│ ├── generate_signals.py # Create signals for the EA
│ └── watch_and_train.py # Launch MT4 and monitor CSVs

yaml
Copy
Edit

---

The EA uses the following main files:

- `MQL4/Experts/CCTS_Breakout.mq4` – main Expert Advisor
- `MQL4/Include/CCTS/EaSetup/Breakout_Setup.mqh` – strategy inputs
- `MQL4/Include/CCTS/EaSetup/Breakout_Signals.mqh` – signal generation
- `MQL4/Include/CCTS/Indicators/IndicatorSetBreakout.mqh` – loads V1, Ex1, Ex2, BL2, C1 and C2 indicators
- `MQL4/Include/CCTS/ExportSignalsToCSV.mqh` – exports labeled OHLC+signal data
- `MQL4/Include/CCTS/PythonSignalReader.mqh` – reads `python_signals_<magic>.csv`

Core Modules:

- **CCTS_Config.mqh** – Shared inputs and variables
- **CCTS_BaseIncludes.mqh** – Central list of include files
- **CCTS_AutoLots.mqh** – Lot size utilities
- **CCTS_AutoMagic.mqh** – Creates symbol-based magic numbers
- **CCTS_CalculateDigitsPoints.mqh** – Retrieves digits, points, and pip values
- **CCTS_CalculateSlippage.mqh** – Calculates slippage allowances
- **CCTS_CalculateSLTP.mqh** – Standard SL/TP calculations
- **CCTS_CloseTrades.mqh** – Routines for closing open orders
- **CCTS_CountOrders.mqh** – Counts active orders for the EA
- **CCTS_LogActions.mqh** – Logs EA actions (open/close/trail)
- **CCTS_LogErrors.mqh** – Records error messages
- **CCTS_LogTrades.mqh** – Journals trade outcomes
- **CCTS_MoneyManagement.mqh** – Breakeven and trailing stop logic
- **CCTS_NewBar.mqh** – Detects new bars for timing
- **CCTS_OrderOpen.mqh** – Handles first and second order entries
- **CCTS_PersistentVariables.mqh** – Saves variables between restarts
- **CCTS_TimeUtils.mqh** – Timezone and session utilities

## 🔧 Key Features

* 🔁 **Modular architecture** – Easily swap or extend signal logic per strategy  
* 📏 **Risk Management** – Includes auto lot sizing, SL/TP handling, ATR-based trailing stops  
* ⏱️ **Time Tools** – Broker time conversion and session filters  
* 📒 **Trade Logging** – Built-in journaling for debugging and evaluation  
* 💾 **CSV Signal Export** – `ExportSignalsToCSV.mqh` records labeled bars for ML training  
* 🧩 **Support for multiple strategies** – e.g., ICT concepts, divergence, Renko, pivot-based entries  
* 🔊 **Volume & Exit Indicators** – Includes the V1 OBV with MA filter and Ex1 Rex early-exit logic  
* 🤖 **Python ML integration** – Models are trained in Python and signals are read from `python_signals_<magic>.csv`

---

## 🧠 Strategy Logic

**Signal Type**: Close-based breakout from recent range.

**Trade Direction**:
- **Long** if:
  - `Close[1] > Close[1 + CompareBarsAgo]`
  - AND `Close[1] > highest close in [RangeStart..RangeEnd]`
  - AND `Close[1] > lowest close in [RangeStart..RangeEnd]`
- **Short** if inverse of above.

**Exit Signal**:
- Exit current trade if candle reverses the entry signal (same 3 conditions, but opposite direction).
- Looks back 10 bars to detect last direction for context.

---

## ⚙️ Indicator Inputs

MQL4/Experts/CCTS_Breakout.mq4

yaml
Copy
Edit

Attach the compiled EA to a chart in MT4.

---

## 🖥️ Optional: Compile via Command Line

You can automate compilation with the included `compile.bat` script:

```bat
@echo off
set metaeditor_path="C:\Program Files (x86)\MetaTrader 4\metaeditor.exe"
set mq4_file="MQL4\Experts\CCTS_Breakout.mq4"
%metaeditor_path% /compile:%mq4_file%
pause
Make sure to adjust the path to metaeditor.exe as needed.

🐍 Python Signal Workflow
Run the EA with ExportSignalsToCSV.mqh included to produce signals_labeled_<magic>.csv in MQL4/Files.

Install the Python dependencies using:

bash
Copy
Edit
pip install -r requirements.txt
Or manually:

bash
Copy
Edit
pip install pandas scikit-learn joblib watchdog
Start the watcher which launches MT4 and retrains/generates signals automatically:

bash
Copy
Edit
python MQL4/Include/CCTS/python/watch_and_train.py
Edit the terminal_path inside the script to match your MT4 installation.

The script monitors MQL4/Files for signals_labeled_<magic>.csv. When a new file is detected it runs train_model.py and generate_signals.py.

generate_signals.py writes python_signals_<magic>.csv which the EA reads each tick.

🔄 Future Enhancements
???

✅ Performance Targets
Win Rate Goal: 55%+

Profit Factor: 1.5+

Drawdown Limit: Max 10%

Backtest Assets: Majors/minors, indices, crypto, commodities

Backtest Period: At least 3+ years for each symbol

📌 About This Project
CCTS_EA_Framework is developed and maintained by Maidenfan78. The goal is to provide a clean, reusable structure for developing high-performance EAs on MetaTrader 4 using MQL4.

Keywords for discoverability:
MQL4 EA Framework, MetaTrader 4 Expert Advisor, Auto lot sizing MT4, Modular EA design, Money management MQL4, ATR trailing stop EA, ICT trading strategy EA, GitHub forex bot

📎 License
This project is released under the MIT License. See the LICENSE file for the full text.