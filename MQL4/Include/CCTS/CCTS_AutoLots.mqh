//+------------------------------------------------------------------+
//|                       CCTS_AutoLots.mqh                          |
//+------------------------------------------------------------------+
#property strict

#ifndef __AUTO_LOTS_MQH__
#define __AUTO_LOTS_MQH__

#include "..\CCTS\CCTS_Config.mqh"
#include "..\CCTS\CCTS_CalculateDigitsPoints.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"

// Normalize the lot size
double NormalizeLot(double lots)
  {
// Get broker specs
   double MaxLot  = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double MinLot  = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double LotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

// If MarketInfo returns invalid data, print a warning and return a default lot size
   if(MinLot == 0.0 || MaxLot == 0.0)
     {
      ErrorLog(__FUNCTION__, "Lot size error", currentSymbol, DoubleToStr(lots,2), "Invalid MinLot or MaxLot from MarketInfo");
      return 0.1; // Default minimum lot size (you can change this fallback if needed)
     }

// Avoid division by zero in case LotStep is invalid
   double InverseLotStep = (LotStep > 0.0) ? 1.0 / LotStep : 1.0 / MathMax(MinLot, 0.01);

// Calculate normalized lot size
   double NormalizedLot = MathFloor(lots * InverseLotStep) / InverseLotStep;

// Ensure lot size is within broker specs
   NormalizedLot = MathMax(NormalizedLot, MinLot);
   NormalizedLot = MathMin(NormalizedLot, MaxLot);

   return NormalizedLot;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcLotsVolume(double sl, int slPoints)
  {
   double SendLots = 0;
   double pipSize  = GetPip();
   double MaxLot   = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double MinLot   = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double LotStep  = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   double riskAmount = AccountBalance() * (RiskPercent / 100.0);

// ✅ Prevent division by zero
   if(slPoints <= 0 || pointValue <= 0)
     {
      ErrorLog(__FUNCTION__, "Lot size error", currentSymbol, DoubleToString(SendLots,2), " Stoploss :" + DoubleToString(sl,digits) + " Stoploss points :" + IntegerToString(slPoints,0) + " Point value :" + DoubleToString(pointValue,digits) + " SL Pips or Point Value Invalid. Using MinLot.");
      return MinLot;
     }
   double tickSize      = SymbolInfoDouble(currentSymbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue     = SymbolInfoDouble(currentSymbol, SYMBOL_TRADE_TICK_VALUE);
   double point         = SymbolInfoDouble(currentSymbol, SYMBOL_POINT);
   double StopLossPips  = sl / _Point;
   double PipValue      = tickValue / tickSize;

// ✅ Calculate lot size
   SendLots = riskAmount / (StopLossPips * tickValue);

// ✅ Normalize the lot size to ensure it conforms to broker specifications
   SendLots = NormalizeLot(SendLots);

   return SendLots;
  }

#endif
//+------------------------------------------------------------------+
