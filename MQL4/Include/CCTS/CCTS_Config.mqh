//+------------------------------------------------------------------+
//|                                                  CCTS_Config.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property link      "https://www.CoolCherry.com"
#property strict

#ifndef __CCTS_CONFIG_MQH__
#define __CCTS_CONFIG_MQH__

extern string RiskHeader              = "-------------------------- Risk Setting Input --------------------------";
input double  RiskPercent             = 1.0;         // Percentage of account balnce to risk

extern string TpSlHeader              = "-------------------------- TP & SL Settings --------------------------";
input double  ATR_SL_Multiplier       = 1.5;         // Stoploss ATR multiplier
input double  ATR_TP_Multiplier       = 1.0;         // Take profit ATR multiplier
input double  ATR_TP_Multiplier_2     = 4.0;         // 2nd trade ATR mulltiplier if enabled

extern string TSLHeader               = "-------------------------- Trailing Stoploss Settings --------------------------";
input double  ATR_TrailingStart       = 2.5;         // ATR multiplier for when to initiate trailing stop
input double  ATR_TrailingMultiplier  = 2.0;         // ATR multiplier for trailing stoploss

extern string TradeControlHeader      = "-------------------------- Trade Control Settings--------------------------";
input bool    UseTrailingStop         = true;        // Enable/Disable trailing stop
input bool    UseBreakeven            = true;        // Enable/Disable breakeven code
input bool    Use_Tp_2                = false;       // Enable/Disable 2nd take profit or let second trade run

extern string DispPanleHeader         = "-------------------------- Display Panel Settings--------------------------";
input bool    EnablePrintLogs         = true;        // Enable/Disable logs
input bool    ShowDisplayPanel        = true;        // Enable/Diable display panel

// Global Variables

const string  currentSymbol           = Symbol();     // Chart symbol

string        eaTitle;

bool          AutoMagic               = TRUE; //Generate Magic Number based on Symbol and Long/Short params

string        magicNumberString;

string        tradeComment_1;
string        tradeComment_2;

int           MagicNumber       = AutoMagic;

const string  brokerName       = AccountCompany();
const long    rawMode          = AccountInfoInteger(ACCOUNT_TRADE_MODE);

const int     acctLeverage     = AccountLeverage();
string        MetricsDisplayPanel        = "";
double        pointValue;
int           ATR_Period       = 14;
double        ATRValue         = 0;
int           digits;            // The Digits of the symbol. Decimal places
int           openOrders;
int           allowableSlippage;               // Slippage
double        LotsVolume;                      // Final order size
int           tradeDirection;

//Persistent variables for CCTS_PersistentVariables.mqh
string                fileName;         //Store name of CSV file for persistent vaiables

// Define the PersistentVariables struct CSV file for persistent vaiables
struct PersistentVariables
  {
   bool              Hit95Target;
   bool              ContinuationEnabled;
   string            LastTradeOrderType;
   string            LastTradeBaselineTrend;
   string            LastTradeEx2Exit;
   bool              MovedToBE;
   bool              TrailingStopAdjusted;
   double            oldAtrValue;
   double            orderOpenPrice;
   bool              Hit95Logged;
   bool              stopLossHit;
   bool              baseLineFlipped;

  };

// Initialize default values for the struct CSV file for persistent vaiables
void InitializeDefaultValues(PersistentVariables &Variables)
  {
   variables.Hit95Target            = false;
   variables.ContinuationEnabled    = false;
   variables.LastTradeOrderType     = "Waiting for signal";
   variables.LastTradeBaselineTrend = "Waiting for signal";
   variables.LastTradeEx2Exit       = "Waiting for signal";
   variables.MovedToBE              = false;
   variables.TrailingStopAdjusted   = false;
   variables.oldAtrValue            = ATRValue;
   variables.orderOpenPrice         = OrderClosePrice();
   variables.Hit95Logged            = false;
   variables.stopLossHit            = false;
   variables.baseLineFlipped        = false;

  }

PersistentVariables variables; // Declare global struct instance CSV file for persistent vaiables

bool customExitBuy;  // did we just exit buy?
bool customExitSell;  // did we just exit sell?

//////////BL2
//string         BL2Entries;
//string         Baseline2;
string         BL2SignalCross;
string         BL2Trend;
string         withInATR;
double         currentBase2Line1;
double         currentBase2Line2;
double         currentBase2Line3;
double         currentBase2Line4;
double         currentBase2Line5;
double         previousBase2Line1;
double         previousBase2Line2;
double         previousBase2Line3;
double         previousBase2Line4;
double         previousBase2Line5;
double         lineTwoBarsAgoBase2Line1;
double         lineTwoBarsAgoBase2Line2;
double         lineTwoBarsAgoBase2Line3;
double         lineTwoBarsAgoBase2Line4;
double         lineTwoBarsAgoBase2Line5;

//////////C1
//string         C1Entries;
double         lineTwoBarsAgo1C1;
double         lineTwoBarsAgo2C1;
double         lineTwoBarsAgo3C1;
double         lineTwoBarsAgo4C1;
double         lineTwoBarsAgo5C1;
double         lineTwoBarsAgo6C1;
double         previousLine1C1;
double         previousLine2C1;
double         previousLine3C1;
double         previousLine4C1;
double         previousLine5C1;
double         previousLine6C1;
double         currentLine1C1;
double         currentLine2C1;
double         currentLine3C1;
double         currentLine4C1;
double         currentLine5C1;
double         currentLine6C1;
string         C1Signal;
string         C1SignalCross;
string         C1Trend;

///////////C2

double         currentLine1C2;
double         currentLine2C2;
double         currentLine3C2;
double         currentLine4C2;
double         currentLine5C2;
double         currentLine6C2;
double         previousLine1C2;
double         previousLine2C2;
double         previousLine3C2;
double         previousLine4C2;
double         previousLine5C2;
double         previousLine6C2;
string         C2Signal;
string         C2SignalCross;
string         C2Trend;

////////// V1
string         V1Volume;
double         currentLine1V1;
double         currentLine2V1;
double         currentLine3V1;
double         currentLine4V1;
double         currentLine5V1;
double         currentLine6V1;
double         currentLine7V1;
string         V1Signal;

////////// Ex1
double         previousLine1Ex1;
double         previousLine2Ex1;
double         previousLine3Ex1;
double         previousLine4Ex1;
double         previousLine5Ex1;
double         previousLine6Ex1;
double         currentLine1Ex1;
double         currentLine2Ex1;
double         currentLine3Ex1;
double         currentLine4Ex1;
double         currentLine5Ex1;
double         currentLine6Ex1;
string         Ex1SignalCross;
string         Ex1Trend;
string         Ex1Signal;

////////// Ex2
double         previousLine1Ex2;
double         previousLine2Ex2;
double         previousLine3Ex2;
double         previousLine4Ex2;
double         previousLine5Ex2;
double         previousLine6Ex2;
double         currentLine1Ex2;
double         currentLine2Ex2;
double         currentLine3Ex2;
double         currentLine4Ex2;
double         currentLine5Ex2;
double         currentLine6Ex2;
string         Ex2SignalCross;
string         Ex2Trend;
string         Ex2ignal;


#endif
//+------------------------------------------------------------------+
