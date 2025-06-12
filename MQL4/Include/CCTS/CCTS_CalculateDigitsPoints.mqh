//+------------------------------------------------------------------+
//|                          Calculate_Pips_PointsDigits.mqh         |
//+------------------------------------------------------------------+
#property strict

#ifndef __CALC_PIPS_MQH__
#define __CALC_PIPS_MQH__

#include "..\CCTS\CCTS_Config.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"

// Function to determine the number of digits for the symbol
int GetDigits()
  {
   return (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
  }

// Function to determine point size
double GetPoint()
  {
   return SymbolInfoDouble(currentSymbol, SYMBOL_POINT);
  }

// Function to determine pip size
double GetPip()
  {
   double point = GetPoint();
   return (GetDigits() == 5 || GetDigits() == 3) ? point * 10 : point;
  }

// Function to determine pip value in account currency
double PointValue()
  {
   double tickSize      = SymbolInfoDouble(currentSymbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue     = SymbolInfoDouble(currentSymbol, SYMBOL_TRADE_TICK_VALUE);
   double point         = SymbolInfoDouble(currentSymbol, SYMBOL_POINT);
   double ticksPerPoint = tickSize/point;

   pointValue           = tickValue/ticksPerPoint;

   if(tickSize == 0 || tickValue == 0)
     {
      ErrorLog(__FUNCTION__, "Error", currentSymbol, "Warning: Invalid MarketInfo values. Using fallback.");
      return GetPip() * AccountBalance() / 10000; // Estimate pip value
     }

   return (pointValue);
  }

#endif
//+------------------------------------------------------------------+
