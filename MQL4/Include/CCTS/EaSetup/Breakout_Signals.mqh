//+------------------------------------------------------------------+
//|                                            Breakout_Signals.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property strict

#ifndef __BREAKOUT_SIGNALS_MQH__
#define __BREAKOUT_SIGNALS_MQH__

#include "..\CCTS_Config.mqh"
#include "..\EaSetup\Breakout_Setup.mqh"

void signals_at(
   int shift,
   int &tradeSignalLong,
   int &tradeSignalShort,
   int &exitSignalLong,
   int &exitSignalShort)
{
   // initialize
   tradeSignalLong  = 0;
   tradeSignalShort = 0;
   exitSignalLong   = 0;
   exitSignalShort  = 0;

   // --- make sure we have enough bars for lookback + exit scan
   int exitBars    = 10;  // scan the next 10 older bars for the last entry
   int barsNeeded  = shift + CompareBarsAgo + RangeEnd + exitBars;
   if(Bars < barsNeeded) return;

   // --- calculate on the target bar (at index = shift)
   int s = shift;
   double signalValue   = Close[s];
   double longTermValue = Close[s + CompareBarsAgo];

   // compute highest / lowest CLOSE over our look-back range
   double highestClose = Close[s + RangeStart];
   double lowestClose  = Close[s + RangeStart];
   for(int i = RangeStart; i <= RangeEnd; i++)
   {
      double c = Close[s + i];
      if(c > highestClose) highestClose = c;
      if(c < lowestClose)  lowestClose  = c;
   }

   // entry signals
   if(signalValue > longTermValue
      && signalValue > highestClose
      && signalValue > lowestClose)
      tradeSignalLong = 1;

   if(signalValue < longTermValue
      && signalValue < highestClose
      && signalValue < lowestClose)
      tradeSignalShort = 1;

   // exit logic: find the last entry in the next `exitBars` bars
   int lastDir = 0;  // +1=long, -1=short
   for(int offset = 1; offset <= exitBars; offset++)
   {
      int idx = s + offset;
      double sv  = Close[idx];
      double ltv = Close[idx + CompareBarsAgo];

      // compute hi/lo for that bar
      double hi = Close[idx + RangeStart];
      double lo = Close[idx + RangeStart];
      for(int j = RangeStart; j <= RangeEnd; j++)
      {
         double cc = Close[idx + j];
         if(cc > hi) hi = cc;
         if(cc < lo) lo = cc;
      }

      if(sv > ltv && sv > hi && sv > lo) { lastDir = +1; break; }
      if(sv < ltv && sv < hi && sv < lo) { lastDir = -1; break; }
   }

   // now exit on a reversal at the target bar
   if(lastDir == +1
      && signalValue < longTermValue
      && signalValue < highestClose
      && signalValue < lowestClose)
      exitSignalLong = 1;

   if(lastDir == -1
      && signalValue > longTermValue
      && signalValue > highestClose
      && signalValue > lowestClose)
      exitSignalShort = 1;
}

#endif
