//+------------------------------------------------------------------+
//|                                            IndicatorBL2_None.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property link      "https://www.CoolCherry.com"
#property strict

#ifndef __BL2_SETUP_MQH__
#define __BL2_SETUP_MQH__

#include "..\..\CCTS_Config.mqh"

// Dummy setup function (does nothing)
void BL2Setup()
  {
// Intentionally left blank
  }

// Dummy signals function (returns default/neutral values)
string BL2Signals()
  {
   return BL2SignalCross + ", " + BL2Trend + ", " + withInATR;
  }

#endif
//+------------------------------------------------------------------+
