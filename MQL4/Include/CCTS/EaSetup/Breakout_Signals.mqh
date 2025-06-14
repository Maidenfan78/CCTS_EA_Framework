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

void signals(
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

      // ◀── NEW bounds-check ──▶
   // We peek back up to RangeEnd bars for entry,
   // AND another 10 bars for exit-scan (i=2..11).
   int maxLookback = MathMax(RangeEnd, CompareBarsAgo);
   int exitBars    = 11;                         // bars scanned for last entry
   int barsNeeded  = maxLookback + exitBars + 1; // +1 for zero-based safety

   if(Bars < barsNeeded)
      return;

   // need enough bars
   if(Bars < RangeEnd + 2) 
      return;

   //--- primary values on the last closed bar
   double signalValue   = Close[1];               // “gold line”
   double longTermValue = Close[1 + CompareBarsAgo]; 

   //--- compute highest/lowest CLOSE over our look-back range
   double highestClose = Close[RangeStart];
   double lowestClose  = Close[RangeStart];
   for(int i = RangeStart+1; i <= RangeEnd; i++)
   {
      double c = Close[i];
      if(c > highestClose) highestClose = c;
      if(c < lowestClose)  lowestClose  = c;
   }

   //--- entry signals
   bool longCond  = (signalValue > longTermValue &&
                     signalValue > highestClose &&
                     signalValue > lowestClose);
   bool shortCond = (signalValue < longTermValue &&
                     signalValue < highestClose &&
                     signalValue < lowestClose);

   if(longCond)  tradeSignalLong  = 1;
   if(shortCond) tradeSignalShort = 1;

   //--- exit logic: find the last entry in the past 10 bars
   int lastDir = 0; // +1=long, -1=short
   for(int i = 2; i <= 11; i++) // bars 2..11 correspond to the last 10 closed bars
   {
      double sv   = Close[i];
      double ltv  = Close[i + CompareBarsAgo - 1]; // align the longTermValue shift
      double hi   = Close[i + RangeStart - 1];
      double lo   = hi;
      for(int j = RangeStart; j <= RangeEnd; j++)
      {
         double cc = Close[i + j - 1];
         if(cc > hi) hi = cc;
         if(cc < lo) lo = cc;
      }
      if(sv > ltv && sv > hi && sv > lo) { lastDir = +1; break; }
      if(sv < ltv && sv < hi && sv < lo) { lastDir = -1; break; }
   }

   //--- exit on the current bar if it reverses the same three tests
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
