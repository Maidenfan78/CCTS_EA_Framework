//+------------------------------------------------------------------+
//|                                                  CCTS_NewBar.mqh  |
//|                                                      Cool Cherry  |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property strict

#ifndef __NEW_BAR_MQH__
#define __NEW_BAR_MQH__

#include "..\CCTS\CCTS_Config.mqh"

//----------------------------------------------
// If you have a global “currentSymbol” constant,
// you can replace Symbol() with currentSymbol.
// Here we’ll use Symbol() directly for reliability.
//----------------------------------------------

//-----------------------------------------------------------------------------
//  Function:  NewBar()
//  Purpose:   Return true exactly once when a new candle (any timeframe)
//             appears. Compares the last stored Time[0] against current.
//  Usage:     Simply call NewBar() from OnTick(). It returns true on the first
//             tick of each new bar, and false otherwise.
//-----------------------------------------------------------------------------
bool NewBar()
{
   // Static variable holds the last bar‐time we saw
   static datetime lastBarTime = 0;

   // Time[0] is the opening time of the current (most recent) bar
   datetime thisBarTime = Time[0];

   // If it has changed since last call, it’s a new bar
   if(thisBarTime != lastBarTime)
   {
      lastBarTime = thisBarTime;
      return true;
   }

   return false;
}


//-----------------------------------------------------------------------------
//  Function:  AfterNewBar()
//  Purpose:   Return true exactly once a small offset after each new candle’s
//             open. By default we wait 1.39% of bar length (min 1 sec). That
//             can be useful if you want to wait a moment into the bar.
//  Usage:     Call AfterNewBar() on every OnTick(). It will be false until
//             we pass (bar_open + offset), then true exactly once.
//-----------------------------------------------------------------------------
bool AfterNewBar()
{
   // Static holds the bar‐time we last triggered on
   static datetime lastTriggerTime = 0;

   // Find current bar’s open time
   datetime barOpen = iTime(Symbol(), Period(), 0);

   // Calculate bar duration in seconds
   int durationSec = Period() * 60;

   // Compute offset = max(1 sec, 1.39% of bar)
   int offsetSec = MathMax(int(durationSec * 1.39 / 100.0), 1);

   // The moment (barOpen + offsetSec) is when we fire
   datetime triggerPoint = barOpen + offsetSec;

   // If current server time ≥ triggerPoint, and we haven’t fired yet for this bar:
   if(TimeCurrent() >= triggerPoint && lastTriggerTime != triggerPoint)
   {
      lastTriggerTime = triggerPoint;
      return true;
   }

   return false;
}

#endif // __NEW_BAR_MQH__
