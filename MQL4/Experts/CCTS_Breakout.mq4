//+------------------------------------------------------------------+
//|                                               CCTS_Breakout.mq4  |
//|                                                Cool Cherry       |
//+------------------------------------------------------------------+

#property strict

// === Base Includes ===
#include "..\Include\CCTS\CCTS_BaseIncludes.mqh"

// EA Specific Includes
#include "..\Include\CCTS\Indicators\IndicatorSetBreakout.mqh"
#include "..\Include\CCTS\EaSetup\Breakout_Setup.mqh"
#include "..\Include\CCTS\EaSetup\Breakout_Signals.mqh"

//EA version & name
#define EA_NAME         "Breakout"
#define EA_VERSION      "1.0"

//+------------------------------------------------------------------+
//|Standard functions below                                          |
//+------------------------------------------------------------------+

//-- Asian session in GMT: 00:00-09:00
#define ASIA_START_HOUR   0
#define ASIA_END_HOUR     9

// London session in GMT: 08:00–16:59
#define LONDON_START_HOUR  8
#define LONDON_END_HOUR    17

// New York session in GMT: 13:00–21:59
#define NY_START_HOUR      13
#define NY_END_HOUR        22

#define ASIA_OFFSET     ( 9 * 3600)   // GMT+9 (Tokyo)
#define LONDON_OFFSET   ( 1 * 3600)   // GMT+1 for BST, use 0 for GMT in winter
#define NEWYORK_OFFSET  (-4 * 3600)   // GMT-5 for EST, use -4 for EDT in summer

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetCurrentSession()
  {
   int h = TimeHour(TimeGMT());
   if(h >= ASIA_START_HOUR   && h < ASIA_END_HOUR)
      return "Asian";
   if(h >= LONDON_START_HOUR && h < LONDON_END_HOUR)
      return "London";
   if(h >= NY_START_HOUR     && h < NY_END_HOUR)
      return "New York";
   return "";
  }

const string EA_TITLE =  EA_NAME  + "_" + "v" + EA_VERSION;

string orderComment_1 =  EA_TITLE + "_" + "Order_1";
string orderComment_2 =  EA_TITLE + "_" + "Order_2";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   eaTitle                 = EA_TITLE;
   tradeComment_1          = orderComment_1;
   tradeComment_2          = orderComment_2;
   digits                  = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
   double Sl               = 0;
   double Tp               = 0;
   double Tp_2             = 0;
   int    SlPoints         = 0;
   int    TpPoints         = 0;
   int    Tp_2Points       = 0;
   int    tradeSignalLong  = 0;
   int    tradeSignalShort = 0;
   int    exitSignalLong   = 0;
   int    exitSignalShort  = 0;
   bool   isNewBar         = NewBar(true);
   bool   isAfterNewBar    = AfterNewBar(true);
   int    spread           = (int)MarketInfo(currentSymbol, MODE_SPREAD);
   openOrders              = MyOpenOrders();
   allowableSlippage       = calculateSlippage(spread);
   MagicNumber             = AutoMagic();
   magicNumberString       = IntegerToString(MagicNumber);
   string sess             = GetCurrentSession();
   string sessInfo         = (StringLen(sess)>0) ? "Session: "+sess : "Out of session";

   PointValue();

   ATRValue                = iATR(currentSymbol, Period(), ATR_Period, 1);

   CalculateStandardSLTP(Sl, Tp, Tp_2, SlPoints, TpPoints, Tp_2Points);

   LotsVolume              = CalcLotsVolume(Sl, SlPoints);
   double point_Value      = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double dollarsRisk      = LotsVolume * Sl * point_Value;
   double dollarsAtRisk    = (int)MathRound(dollarsRisk);

   CreateFileIfMissing(magicNumberString, fileName);  // Set up file //TXT version
   InitializeDefaultValues(variables);              // Initialize default values

   ReadFromFile(fileName, variables);               // Load values from file //CSV version
   Print("Read from file in OnInit");

// === SETUP PHASE ===
   if(EnableV1)
      V1Setup();
   if(EnableC2)
      C2Setup();
   if(EnableC1)
      C1Setup();
   if(EnableBL2)
      BL2Setup();

// === SIGNAL PHASE ===
   if(EnableBL2)
      BL2Signals();
   if(EnableC1)
      C1Signals();
   if(EnableC2)
      C2Signals();
   if(EnableV1)
      V1Signals();

   MetricsDisplayPanel(tradeSignalLong,tradeSignalShort,exitSignalLong,exitSignalShort,spread,SlPoints,TpPoints,Tp_2Points,dollarsAtRisk,sessInfo);

   Print(eaTitle, " EA initialized.");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   RemoveDisplayPanel();
   Print(eaTitle, " EA stopped.");
   WriteToFile(fileName, variables);
   LogTrade();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//---- prepare locals  ----
   double Sl               = 0;
   double Tp               = 0;
   double Tp_2             = 0;
   int    SlPoints         = 0;
   int    TpPoints         = 0;
   int    Tp_2Points       = 0;
   int    tradeSignalLong  = 0;
   int    tradeSignalShort = 0;
   int    exitSignalLong   = 0;
   int    exitSignalShort  = 0;
   bool   isNewBar         = NewBar(true);
   bool   isAfterNewBar    = AfterNewBar(true);
   int    spread           = (int)MarketInfo(currentSymbol, MODE_SPREAD);
   allowableSlippage       = calculateSlippage(spread);
   openOrders              = MyOpenOrders();
   double dollarsAtRisk    = 0;

//----------------------------------------
// Only process on new bar
//----------------------------------------
   if(IsTesting())
     {
      // back-test: fire immediately on the new bar
      if(!isNewBar)
         return;
     }
   else
     {
      // live/demo: wait your 1.39% delay after candle open
      if(!isAfterNewBar)
         return;
     }

//----------------------------------------
// SESSION FILTER
//----------------------------------------
   int  h        = TimeHour(TimeGMT());
   bool inAsia   = (h >= ASIA_START_HOUR   && h < ASIA_END_HOUR);
   bool inLondon = (h >= LONDON_START_HOUR && h < LONDON_END_HOUR);
   bool inNY     = (h >= NY_START_HOUR     && h < NY_END_HOUR);

   if(!IsDayAllowed())
      return;

// If *all* toggles are off, skip filtering entirely:
   if(!(!EnableAsianSession && !EnableLondonSession && !EnableNewYorkSession))
     {
      // otherwise require at least one enabled session to be active
      if(!((EnableAsianSession     && inAsia)
           ||(EnableLondonSession  && inLondon)
           ||(EnableNewYorkSession && inNY)))
        {
         return;  // outside your chosen session windows
        }
     }

   string sess     = GetCurrentSession();
   string sessInfo = StringLen(sess)>0 ? "Session: "+sess : "Out of session";

//----------------------------------------
// housekeeping & setup
//----------------------------------------
   RefreshRates();
   ATRValue                = iATR(currentSymbol, Period(), ATR_Period, 1);
   PointValue();
   ReadFromFile(fileName, variables);
   LogTrade();
   CalculateStandardSLTP(Sl, Tp, Tp_2, SlPoints, TpPoints, Tp_2Points);
   ManageTrade2(true);   // you can still pass true if you need the bar flag
   LotsVolume    = CalcLotsVolume(Sl, SlPoints);
   pointValue    = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE)
                   / SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   dollarsAtRisk = MathRound(LotsVolume * Sl * pointValue);

//----------------------------------------
// signals, display, exits
//----------------------------------------

// === SETUP PHASE ===
   if(EnableV1)
      V1Setup();
   if(EnableC2)
      C2Setup();
   if(EnableC1)
      C1Setup();
   if(EnableBL2)
      BL2Setup();

// === SIGNAL PHASE ===
   if(EnableBL2)
      BL2Signals();
   if(EnableC1)
      C1Signals();
   if(EnableC2)
      C2Signals();
   if(EnableV1)
      V1Signals();

   if(UseBL2AsExit)
      BL2ExitOn();
   if(UseC1AsExit)
      C1ExitOn();
   if(EnableEx1)
      FastExitIndicatorOn();
   if(EnableEx2)
      SlowExitIndicatorOn();

   if(!inLondon && !inNY)
      return;   // outside trading hours

   if(openOrders != 0)
      return;   // bail if any existing positions

//----------------------------------------
// entry logic
//----------------------------------------
   IndicatorStatus(tradeSignalLong, tradeSignalShort);

// Populate custom-entry signals (or force Off when disabled)
   if(UseCustomEntries)
     {
      signals(
         tradeSignalLong,
         tradeSignalShort,
         exitSignalLong,
         exitSignalShort
      );
     }
   else
     {
      // both signal flags → "Off"
      tradeSignalLong  = 2;
      tradeSignalShort = 2;
     }

   MetricsDisplayPanel(tradeSignalLong,tradeSignalShort,exitSignalLong,exitSignalShort,spread,SlPoints,TpPoints,Tp_2Points,dollarsAtRisk,sessInfo);

   if(UseCustomExits)
     {
      if(exitSignalLong == 1 || exitSignalShort == 1)
         CustomExitOn(exitSignalLong, exitSignalShort);
     }


// 1) Custom entries have top priority
   if(UseCustomEntries)
     {
      if(tradeSignalLong  == 1 && CanEnterLong())
        { openTrades(ORDER_TYPE_BUY, Sl, Tp, Tp_2); return; }
      if(tradeSignalShort == 1 && CanEnterShort())
        { openTrades(ORDER_TYPE_SELL, Sl, Tp, Tp_2); return; }
     }
// 2) C1 entries next
   else
      if(UseC1Entries && EnableC1)
        {
         if((C1SignalCross == "Long"  || C1SignalCross == "Trending") &&
            CanEnterLong())
           { openTrades(ORDER_TYPE_BUY, Sl, Tp, Tp_2); return; }
         if((C1SignalCross == "Short" || C1SignalCross == "Trending") &&
            CanEnterShort())
           { openTrades(ORDER_TYPE_SELL, Sl, Tp, Tp_2); return; }
        }
      // 3) BL2 entries last
      else
         if(UseBL2Entries && EnableBL2)
           {
            if(BL2SignalCross == "Long"  && CanEnterLong())
              { openTrades(ORDER_TYPE_BUY, Sl, Tp, Tp_2); return; }
            if(BL2SignalCross == "Short" && CanEnterShort())
              { openTrades(ORDER_TYPE_SELL, Sl, Tp, Tp_2); return; }
           }


   MetricsDisplayPanel(tradeSignalLong,tradeSignalShort,exitSignalLong,exitSignalShort,spread,SlPoints,TpPoints,Tp_2Points,dollarsAtRisk,sessInfo);

   WriteToFile(fileName, variables);
  }
//------------------------------------------------------------------------------
//  Returns true if all the trend & vol filters would allow a LONG entry
bool CanEnterLong()
  {
   return
      (!UseATRFilter || withInATR == "Yes")  &&
      (!EnableBL2    || BL2Trend  == "Long") &&
      (!EnableC1     || (C1Trend  == "Long"      || C1Trend  == "Trending")) &&
      (!EnableC2     || C2Trend   == "Long") &&
      (!EnableV1     || (V1Volume == "High Long" || V1Volume == "High Long and High Short"));
  }

//------------------------------------------------------------------------------
//  Returns true if all the trend & vol filters would allow a SHORT entry
bool CanEnterShort()
  {
   return
      (!UseATRFilter || withInATR == "Yes")  &&
      (!EnableBL2    || BL2Trend  == "Short") &&
      (!EnableC1     || (C1Trend  == "Short"      || C1Trend  == "Trending")) &&
      (!EnableC2     || C2Trend   == "Short") &&
      (!EnableV1     || (V1Volume == "High Short" || V1Volume == "High Long and High Short"));
  }

// Helper function remains unchanged
void openTrades(ENUM_ORDER_TYPE orderType, double Sl, double Tp, double Tp_2)
  {

// Open orders
   if(openFirstOrder(orderType, Sl, Tp))
     {
      openSecondOrder(orderType, Sl, Tp_2);
      openOrders = MyOpenOrders();
     }
  }

//+------------------------------------------------------------------+
//|  Manage the 2nd trade after first hits TP                         |
//+------------------------------------------------------------------+
void ManageTrade2(bool newBar)
  {
   ReadFromFile(fileName, variables);
// Only manage the runner once—exactly one EA order left, and not yet moved

// Find the runner ("Order_2") and apply BE & trailing
   for(int i = OrdersTotal()-1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != MagicNumber)
         continue;
      if(StringFind(OrderComment(), "Order_2") < 0)
         continue;

      // Derive the side from the live order
      ENUM_ORDER_TYPE side = (OrderType() == ORDER_TYPE_BUY)
                             ? ORDER_TYPE_BUY
                             : ORDER_TYPE_SELL;

      // Move SL to breakeven (this will set variables.MovedToBE=true on success)
      if(UseBreakeven)
         MoveToBreakEven(side);

      // Then update your ATR trailing stop
      if(UseTrailingStop)
         UpdateTrailingStopATR(newBar);
      break;  // only one runner to manage
     }
  }

//---------------------------------------------------------------------------
// Returns "Off" if the input is empty, otherwise returns the input value
/// Helper: returns "Off" if flag==2, "YES" if flag==1, else "No"
string SignalState(int flag)
  {
   if(flag == 2)
      return "Turned Off";
   if(flag == 1)
      return "YES";
   return "No signal";
  }

/// Populates status flags and strings based on enabled/disabled indicators
void IndicatorStatus(int &tradeSignalLong, int &tradeSignalShort)
  {
// If custom entries disabled, mark signals as "Off"
   if(!UseCustomEntries)
     {
      tradeSignalLong  = 2;
      tradeSignalShort = 2;
     }

// If BL2 disabled, mark its outputs "Turned Off"
   if(!EnableBL2)
     {
      BL2SignalCross = "Turned Off";
      BL2Trend       = "Turned Off";
      withInATR      = "Turned Off";
     }

// If C1 disabled
   if(!EnableC1)
     {
      C1SignalCross = "Turned Off";
      C1Trend       = "Turned Off";
     }

// If C2 disabled
   if(!EnableC2)
     {
      C2SignalCross = "Turned Off";
      C2Trend       = "Turned Off";
     }

// If V1 disabled
   if(!EnableV1)
     {
      V1Volume      = "Turned Off";
     }
  }

//+------------------------------------------------------------------+
//|     DisplayPanel                                                 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                  Build the metrics text (return, don’t draw)     |
//+------------------------------------------------------------------+
string GetMetricsString(
   int    tradeSignalLong,
   int    tradeSignalShort,
   int    exitSignalLong,
   int    exitSignalShort,
   double spread,
   int    SlPips,
   int    TpPips,
   int    Tp_2Pips,
   double dollarsAtRisk,
   string extra_Info = ""
)
  {
// get true GMT
   datetime tGMT    = TimeGMT();
// shift into each zone
   datetime tLondon = tGMT + LONDON_OFFSET;
   datetime tNY     = tGMT + NEWYORK_OFFSET;
// if panel is off, bail with empty string
   if(!ShowDisplayPanel)
      return("");

   string metrics = "";

// Server Info and General Stats
   metrics += StringFormat("Broker: %s\n",      brokerName);
   metrics += StringFormat(
                 "Account Type: %s\n",
                 rawMode == 0 ? "Demo"    :
                 rawMode == 1 ? "Contest" :
                 rawMode == 2 ? "Real"    :
                 "unknown"
              );
   metrics += StringFormat("Account Leverage: 1:%d\n",acctLeverage);
   metrics += StringFormat("EA: %s\n",          eaTitle);
   metrics += StringFormat("Magic #: %d\n",     MagicNumber);
   metrics += StringFormat("Total trades chart: %d\n", openOrders);
   metrics += StringFormat("Total trades broker: %d\n", OrdersTotal());
   metrics += StringFormat("Spread: %.1f\n\n",  spread);

// Money Management
   metrics += "---- Money Management ----\n";
   metrics += StringFormat("Lot Size: %.2f\n", LotsVolume);
   metrics += StringFormat("Risk:    $%.2f\n", dollarsAtRisk);
   metrics += StringFormat("SL: %d pips, TP: %d pips\n", SlPips, TpPips);
   metrics += StringFormat("TP2: %d pips\n", Tp_2Pips);
   metrics += StringFormat("Moved to BE?: %s\n\n", variables.MovedToBE==1?"YES":"No");

// Signals
   metrics += "---- Trade Signals ----\n";
// Use SignalState to show Off/YES/No
   metrics += StringFormat("Custom Entry Long   : %s\n", SignalState(tradeSignalLong));
   metrics += StringFormat("Custom Entry Short  : %s\n", SignalState(tradeSignalShort));

// BL2 and ATR
   string atrStat = EnableBL2 ? withInATR : "Off";
   metrics += StringFormat("BL Within ATR: %s\n", atrStat);
   metrics += StringFormat("BL2 Signal: %s  | BL2 Trend: %s\n",
                           EnableBL2 ? BL2SignalCross : "Off",
                           EnableBL2 ? BL2Trend       : "Off");

// C1
   metrics += StringFormat("C1 Signal: %s  | C1 Trend: %s\n",
                           EnableC1 ? C1SignalCross : "Off",
                           EnableC1 ? C1Trend       : "Off");

// C2
   metrics += StringFormat("C2 Signal: %s  | C2 Trend: %s\n",
                           EnableC2 ? C2SignalCross : "Off",
                           EnableC2 ? C2Trend       : "Off");

// V1
   metrics += StringFormat("V1 Signal: %s\n\n", EnableV1 ? V1Volume : "Off");

// Exit Signals
   metrics += "---- Exit Signals ----\n";
   metrics += StringFormat("Custom Exit Long/Short : %s/%s\n",
                           exitSignalLong  == 1 ? "YES" : "No",
                           exitSignalShort == 1 ? "YES" : "No");


// Time Zones
   metrics += "---- Time Zones ----\n\n";
   metrics += StringFormat("Server Time:     %s\n",  TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
   metrics += StringFormat("GMT Time:        %s\n",  TimeToString(tGMT,          TIME_DATE|TIME_MINUTES));
   metrics += StringFormat("London Time:     %s\n",  TimeToString(tLondon,       TIME_DATE|TIME_MINUTES));
   metrics += StringFormat("New York Time:   %s\n",  TimeToString(tNY,           TIME_DATE|TIME_MINUTES));

   if(StringLen(extra_Info)>0)
      metrics +=  extra_Info + "\n";

   return(metrics);
  }

//+------------------------------------------------------------------+
//|           Draw the panel, return true if drawn                   |
//+------------------------------------------------------------------+
bool MetricsDisplayPanel(
   int    tradeSignalLong,
   int    tradeSignalShort,
   int    exitSignalLong,
   int    exitSignalShort,
   double spread,
   int    SlPips,
   int    TpPips,
   int    Tp_2Pips,
   double dollarsAtRisk,
   string extra_Info = ""
)
  {
// build the string
   string txt = GetMetricsString(tradeSignalLong,tradeSignalShort,exitSignalLong,exitSignalShort,spread,SlPips,TpPips,Tp_2Pips,dollarsAtRisk,extra_Info);
   if(StringLen(txt)==0)
      return(false);    // panel is disabled

// draw background
   ObjectCreate(0, "merticsBackground", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "merticsBackground", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "merticsBackground", OBJPROP_XDISTANCE, 0);
   ObjectSetInteger(0, "merticsBackground", OBJPROP_YDISTANCE, 13);
   ObjectSetInteger(0, "merticsBackground", OBJPROP_XSIZE, 210);  // Width
   ObjectSetInteger(0, "merticsBackground", OBJPROP_YSIZE, 430);  // Height
   ObjectSetInteger(0, "merticsBackground", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "merticsBackground", OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, "merticsBackground", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "merticsBackground", OBJPROP_ZORDER, 0);

// finally display
   Comment(txt);
   return(true);
  }
//+------------------------------------------------------------------+
//| Returns true if today is enabled for trading                     |
//+------------------------------------------------------------------+
bool IsDayAllowed()
  {
// 0=Sunday, 1=Monday, … 6=Saturday
   int dow = TimeDayOfWeek(TimeCurrent());
   switch(dow)
     {
      case 0:
         return AllowSunday;
      case 1:
         return AllowMonday;
      case 2:
         return AllowTuesday;
      case 3:
         return AllowWednesday;
      case 4:
         return AllowThursday;
      case 5:
         return AllowFriday;
      case 6:
         return AllowSaturday;
     }
   return false; // should never hit
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RemoveDisplayPanel()
  {
   int ObjectsAll = ObjectsTotal();
   int   i = 0;
   while(i < ObjectsAll)
     {
      ObjectDelete("metricsBackground");
      i++;
     }
   return (0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double OnTester()
  {
   double totalTrades = TesterStatistics(STAT_TRADES);
   double profitTrades = TesterStatistics(STAT_PROFIT_TRADES);

   if(totalTrades == 0)
      return 0;

   return (profitTrades / totalTrades);  // Win rate
  }


