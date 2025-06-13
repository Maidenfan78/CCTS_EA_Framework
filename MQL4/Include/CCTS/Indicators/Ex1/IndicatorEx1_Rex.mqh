//+------------------------------------------------------------------+
//|                                             IndicatorEx1_Rex.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property link      "https://www.CoolCherry.com"
#property strict

#ifndef __EX1_SETUP_MQH__
#define __EX1_SETUP_MQH__

#include "..\..\CCTS_Config.mqh"

input string   ExitIndicator1            = "Ex1\\Rex";                // Name of Ex1 indicator
input int      ExPeriod1                 = 14;                 // Indicator period 1
input int      ExPeriod2                 = 0;                 // Indicator period 2
input int      ExPeriod3                 = 14;                 // Indicator period 3
input int      ExPeriod4                 = 0;                 // Indicator period 4

const int      Ex1Line1                  = 0;                  //Buffer 0
const int      Ex1Line2                  = 1;                  //Buffer 1

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Ex1Setup()
  {
// Fetch values using calculated shifts
   currentLine1Ex1       = iCustom(Symbol(), Period(), ExitIndicator1, ExPeriod1, ExPeriod2, ExPeriod3, ExPeriod4, Ex1Line1, 1);
   currentLine2Ex1       = iCustom(Symbol(), Period(), ExitIndicator1, ExPeriod1, ExPeriod2, ExPeriod3, ExPeriod4, Ex1Line2, 1);
   previousLine1Ex1      = iCustom(Symbol(), Period(), ExitIndicator1, ExPeriod1, ExPeriod2, ExPeriod3, ExPeriod4, Ex1Line1, 2);
   previousLine2Ex1      = iCustom(Symbol(), Period(), ExitIndicator1, ExPeriod1, ExPeriod2, ExPeriod3, ExPeriod4, Ex1Line2, 2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Ex1Signals()
  {
   if((previousLine1Ex1<previousLine2Ex1) && (currentLine1Ex1>=currentLine2Ex1))
      Ex1SignalCross = "Exit Short";
   else
      if((previousLine1Ex1>previousLine2Ex1) && (currentLine1Ex1<=currentLine2Ex1))
         Ex1SignalCross = "Exit Long";
      else
         Ex1SignalCross = "No Signal";
   if(currentLine1Ex1>currentLine2Ex1)
      Ex1Trend = "Exit Short";
   else
      if(currentLine1Ex1<currentLine2Ex1)
         Ex1Trend = "Exit Long";
      else
         Ex1Trend = "No Signal";
   return Ex1SignalCross + ", " + Ex1Trend;
  }

#endif

//+------------------------------------------------------------------+
