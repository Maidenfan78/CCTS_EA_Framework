//+------------------------------------------------------------------+
//|                                                  CCTS_NewBar.mqh |
//|                                                      Cool Cherry |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property strict

#ifndef __NEW_BAR_MQH__
#define __NEW_BAR_MQH__

#include "..\CCTS\CCTS_Config.mqh"

// Standard new bar rule: triggers when the candle open time changes.
bool NewBar(bool first_call = false)
  {
   static bool result = false;
   if(!first_call)
      return(result);

   static datetime previous_Time = 0;
   datetime current_time = iTime(currentSymbol, Period(), 0);
   result = false;
   if(previous_Time != current_time)
     {
      previous_Time = current_time;
      result = true;
     }
   return(result);
  }

//+------------------------------------------------------------------+
//|//|New bar rule: Triggers after the open of new candle.           |                                                                      |
//+------------------------------------------------------------------+
bool AfterNewBar(bool first_call = false)
  {
   static bool triggered = false;
   if(!first_call)
      return (triggered);

   static datetime last_trigger_time = 0; // Ensures trigger runs only once per candle
   datetime current_time = TimeCurrent();   // Current server time

// Get the current candle's open time based on the selected timeframe
   datetime current_candle_open = iTime(Symbol(), Period(), 0);

// Calculate the candle duration in seconds (Period() is in minutes, so convert to seconds)
   int period_seconds = Period() * 60;

// Calculate trigger time dynamically (1.39% of the timeframe duration, minimum 1 second)
   int trigger_offset = MathMax(int(period_seconds * 1.39 / 100.0), 1);
   datetime trigger_time = current_candle_open + trigger_offset;

// For AFTER new candle, trigger when current time is at or beyond the trigger_time.
// Optionally, you can define an upper window if needed. Here, we trigger once once current_time reaches trigger_time.
   if(current_time >= trigger_time && last_trigger_time != trigger_time)
     {
      last_trigger_time = trigger_time;
      triggered = true;

      // Print a confirmation message
      //     if(currentSymbol == "EURUSD" || currentSymbol == "XAGUSD")
      //       {
      //        Print("Triggered ", trigger_offset, " seconds after the open of the ", Period(),
      //              " minute candle. Current server time: ", TimeToString(current_time, TIME_SECONDS));
      //       }
      return (triggered);
     }

   triggered = false; // Reset after the window has passed
   return (triggered);
  }
  /*
  //+------------------------------------------------------------------+
//|New bar rule: Triggers before the open of new candle.             |                                                     |
//+------------------------------------------------------------------+
bool BeforeNewBar(bool first_call = false)
  {
   static bool triggered = false;
   if(!first_call)
      return triggered;

   static datetime last_trigger_time = 0; // Tracks when the function last triggered
   datetime current_time = TimeCurrent();   // Current server time

// Get the current candle's open time based on the selected timeframe
   datetime current_candle_open = iTime(Symbol(), Period(), 0);

// Calculate the candle duration in seconds (Period() is in minutes, so convert to seconds)
   int period_seconds = Period() * 60;

// Calculate the closing time of the current candle
   datetime current_candle_close = current_candle_open + period_seconds;

// Calculate trigger time dynamically (1.39% of the timeframe duration, min 1 second)
   int trigger_offset = MathMax(int(period_seconds * 1.39 / 100.0), 1); // Ensures at least 1 second offset
   datetime trigger_time = current_candle_close - trigger_offset;

// Ensure the trigger only runs once per candle
   if(current_time >= trigger_time && current_time < current_candle_close && last_trigger_time != trigger_time)
     {
      last_trigger_time = trigger_time;
      triggered = true;

      // Print a message for confirmation
      if(currentSymbol == "EURUSD" || currentSymbol == "XAGUSD")
        {
         Print("Triggered ", trigger_offset, " seconds before the close of the ", Period(), " minute candle.");
        }

      return triggered;
     }

   triggered = false; // Reset after the window has passed
   return triggered;
  }
  */
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

/*
// Main function to select the triggering mode.
bool NewBarSelect(bool first_call = false)
  {
// Ensure NewBar_Setting has a valid value
   if(NewBar_Setting != "STANDARD" && NewBar_Setting != "BEFOREBAR" && NewBar_Setting != "AFTERBAR")
     {
      Print("Error: Invalid NewBar_Setting value detected before execution: ", NewBar_Setting);
     }

   if(NewBar_Setting == "STANDARD")
     {
      return NewBar(first_call);
     }
   else
      if(NewBar_Setting == "BEFOREBAR")
        {
         return BeforeNewBar(first_call);
        }
      else
         if(NewBar_Setting == "AFTERBAR")
           {
            return AfterNewBar(first_call);
           }
         else
           {
            Print("Error: NewBar_Setting has an invalid value: ", NewBar_Setting, ". Defaulting to STANDARD.");
            return NewBar(first_call);
           }
  }

//+------------------------------------------------------------------+
*/

#endif
//+------------------------------------------------------------------+
