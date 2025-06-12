# 🧠 CCTS EA Framework – Modular Expert Advisor for MetaTrader 4 (MT4)

Welcome to the **CCTS\_EA\_Framework** by [Maidenfan78](https://github.com/Maidenfan78) – a **modular Expert Advisor system written in MQL4** for MetaTrader 4. Designed with reusability and clean architecture in mind, this framework makes it easy to build and test trading strategies, including breakout, ATR-based, pivot point, and ICT-style logic.

---

## 📁 Project Structure

```
MQL4/
├── Experts/
│   └── CCTS_Breakout.mq4           # Main Expert Advisor file
├── Include/
│   └── CCTS/
│       ├── CCTS_*.mqh              # Core utility modules (SL/TP, lots, logging, time, etc.)
│       └── EaSetup/
│           ├── Breakout_Setup.mqh  # Strategy-specific inputs
│           └── Breakout_Signals.mqh # Signal generation logic
```

---

## 🔧 Key Features

* 🔁 **Modular architecture** – Easily swap or extend signal logic per strategy
* 📏 **Risk Management** – Includes auto lot sizing, SL/TP handling, ATR-based trailing stops
* ⏱️ **Time Tools** – Broker time conversion and session filters
* 📒 **Trade Logging** – Built-in journaling for debugging and evaluation
* 🧩 **Support for multiple strategies** – e.g., ICT concepts, divergence, Renko, pivot-based entries

---

## 🧠 Strategy Logic

* **Signal Type**: Close-based breakout from recent range.

* **Trade Direction**:

  * **Long** if:

    * `Close[1] > Close[1 + CompareBarsAgo]`
    * AND `Close[1] > highest close in [RangeStart..RangeEnd]`
    * AND `Close[1] > lowest close in [RangeStart..RangeEnd]`
  * **Short** if inverse of above.

* **Exit Signal**:

  * Exit current trade if candle reverses the entry signal (same 3 conditions, but opposite direction).
  * Looks back 10 bars to detect last direction for context.

---

## ⚙️ Indicator Inputs

| Input Variable           | Description                                    |
| ------------------------ | ---------------------------------------------- |
| `CompareBarsAgo`         | How many bars back to compare current close    |
| `RangeStart`/`RangeEnd`  | Range of bars for high/low breakout comparison |
| `ATR_SL_Multiplier`      | 1.5x ATR for SL                                |
| `ATR_TP_Multiplier`      | 1.0x ATR for TP (first trade)                  |
| `ATR_TrailingStart`      | Trailing starts after 2.5x ATR profit          |
| `ATR_TrailingMultiplier` | Trail SL with 2.0x ATR buffer                  |

---

## ⏱ Time and Session Filters

* **Timeframes**: H4 or D1
* **Sessions**: Optional — Asian, London, NY
* **Days**: Sunday/Saturday disabled by default

---

## 💰 Trade Rules

* **Trades per signal**: 2 orders

* **TP for Trade 1**: 1x ATR

* **SL for both**: 1.5x ATR

* **Trade 2 behavior**:

  * No TP unless `Use_Tp_2 = true`
  * Breakeven if Trade 1 TP hits
  * Trailing stop after 2.5x ATR profit

* **Lot sizing**: Risk 1% per trade, calculated using:

  ```
  riskAmount / (StopLossPips * tickValue)
  ```

  → Total risk per signal = **2% of balance**

---

## 🚀 Getting Started

1. Clone or copy the repository to your terminal’s `MQL4/` directory.
2. Open MetaEditor from MetaTrader 4.
3. Compile the main EA:

   ```
   MQL4/Experts/CCTS_Breakout.mq4
   ```
4. Attach the compiled EA to a chart in MT4.

---

## 🖥️ Optional: Compile via Command Line

You can automate compilation with the included `compile.bat` script:

```bat
@echo off
set metaeditor_path="C:\Program Files (x86)\MetaTrader 4\metaeditor.exe"
set mq4_file="MQL4\Experts\CCTS_Breakout.mq4"
%metaeditor_path% /compile:%mq4_file%
pause
```

Make sure to adjust the path to `metaeditor.exe` as needed.

---

## 🔄 Future Enhancements

* Add exit indicator to close positions earlier if market moves unfavorably (before SL)

---

## ✅ Performance Targets

* **Win Rate Goal**: 55%+
* **Profit Factor**: 1.5+
* **Drawdown Limit**: Max 10%
* **Backtest Assets**: Majors/minors, indices, crypto, commodities
* **Backtest Period**: At least 3+ years for each symbol

---

## 📌 About This Project

**CCTS\_EA\_Framework** is developed and maintained by [Maidenfan78](https://github.com/Maidenfan78). The goal is to provide a clean, reusable structure for developing high-performance EAs on MetaTrader 4 using MQL4.

### Keywords for discoverability:

> MQL4 EA Framework, MetaTrader 4 Expert Advisor, Auto lot sizing MT4, Modular EA design, Money management MQL4, ATR trailing stop EA, ICT trading strategy EA, GitHub forex bot

---

## 📎 License

MIT License. Use and modify freely, but attribution is appreciated.
