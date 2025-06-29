//+------------------------------------------------------------------+
//|                                           CCTS_CalculateSLTP.mqh |
//+------------------------------------------------------------------+
#property strict

#ifndef __SL_TP_MQH__
#define __SL_TP_MQH__

#include "..\CCTS\CCTS_Config.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"
#include "..\CCTS\CCTS_CalculateDigitsPoints.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CalculateStandardSLTP(double &Sl, double &Tp, double &Tp_2, int &SlPoints, int &TpPoints, int &Tp_2Points)
  {
// Validate ATR and multipliers
   if(ATRValue <= 0 || ATR_SL_Multiplier <= 0 || ATR_TP_Multiplier <= 0 || ATR_TP_Multiplier_2 <= 0)
     {
      ErrorLog(__FUNCTION__, "Error", currentSymbol, "Invalid ATR values or multipliers.");
      return false;
     }
   double pipSize = GetPip();
// Calculate stop-loss and take-profit based on ATR multipliers
   Sl   = NormalizeDouble(ATRValue * ATR_SL_Multiplier, digits);  // Stop-loss
   Tp   = NormalizeDouble(ATRValue * ATR_TP_Multiplier, digits);  // Take-profit
   Tp_2 = NormalizeDouble(ATRValue * ATR_TP_Multiplier_2, digits);  // Second take-profit


// Convert stop-loss values to points
   SlPoints   = (int) NormalizeDouble(Sl / pipSize, 0);
   TpPoints   = (int) NormalizeDouble(Tp / pipSize, 0);
   Tp_2Points = (int) NormalizeDouble(Tp_2 / pipSize, 0);

// Validate calculated values
   if(SlPoints <= 0 || TpPoints <= 0 || Tp_2Points <= 0)
     {
      ErrorLog(__FUNCTION__, "Invalid calculated SL or TP in pips. ", currentSymbol, DoubleToString(SlPoints,0) + " In points ", DoubleToString(TpPoints,0) + " In Points"," Invalid calculated SL or TP in pips.");
      return false;
     }

   return true; // Success
  }

#endif


