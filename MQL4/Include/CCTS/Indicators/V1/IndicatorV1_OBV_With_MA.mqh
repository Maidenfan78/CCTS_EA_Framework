//+------------------------------------------------------------------+
//|                          IndicatorV1_OBV_With_MA.mqh             |
//|      Integrate On-Balance Volume (OBV) with Moving Average        |
//|                   Debug version with print statements            |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property link      "https://www.CoolCherry.com"
#property strict

#ifndef __V1_SETUP_MQH__
#define __V1_SETUP_MQH__

#include "..\..\CCTS_Config.mqh"

//--- user inputs for our V1 wrapper
extern string        V1                         = "---- V1 OBV Inputs ----";
input string         V1Indicator                = "V1\\OBV_With_MA";  // indicator name (without .mq4)
input int            V1MAPeriod                 = 14;                // MA period on OBV
input ENUM_MA_METHOD V1MAMethod                 = MODE_SMA;          // MA type
input int            V1MAShift                  = 0;                 // MA shift (bars)

//--- which custom-indicator buffers to grab
int V1Line_OBV        = 0;
int V1Line_OBVMA      = 1;

//+------------------------------------------------------------------+
//| Call the OBV+MA custom indicator and cache its current values   |
//+------------------------------------------------------------------+
void V1Setup()
  {
// Fetch both buffers from previous closed bar (shift = 1)
   currentLine1V1 = iCustom(Symbol(), Period(), V1Indicator, V1MAPeriod, V1MAMethod, V1MAShift, V1Line_OBV, 1);
   currentLine2V1 = iCustom(Symbol(), Period(), V1Indicator, V1MAPeriod, V1MAMethod, V1MAShift, V1Line_OBVMA, 1);
  }

//+------------------------------------------------------------------+
//| Generate the simple “High Long/High Short/Low” volume signal    |
//+------------------------------------------------------------------+
string V1Signals()
  {
   if(currentLine1V1 > currentLine2V1)
      V1Volume = "High Long";
   else
      if(currentLine1V1 < currentLine2V1)
         V1Volume = "High Short";
      else
         V1Volume = "Low";

// Debug print: result
   return(V1Volume);
  }

#endif
//+------------------------------------------------------------------+
