//+------------------------------------------------------------------+
//|                                       CCTS_CalculateSlippage.mqh |
//+------------------------------------------------------------------+
#property strict

#ifndef __CALC_SLIPPAGE_MQH__
#define __CALC_SLIPPAGE_MQH__
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int calculateSlippage(double spread)
  {
// Minimum slippage of 3 points for low volatility assets
   int slippage = (int) MathMax(3, spread * 1.5); // Slippage = 1.5 * spread

// Ensure a max limit to avoid excessive slippage (e.g., for Bitcoin)
   if(slippage > 50)
      slippage = 50;

   return slippage;
  }

#endif
//+------------------------------------------------------------------+
