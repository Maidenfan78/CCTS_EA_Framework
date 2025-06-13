//+------------------------------------------------------------------+
//|                                         IndicatorSetBreakout.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property link      "https://www.CoolCherry.com"
#property strict

#ifndef __INDISET_MQH__
#define __INDISET_MQH__

#include "..\..\CCTS\CCTS_Config.mqh"

//////////////////////////////////// Ex2 Indicators ///////////////////////////////////
#include <CCTS\\Indicators\\Ex2\\IndicatorEx2_None.mqh>

//////////////////////////////////// Ex1 Indicators ///////////////////////////////////
#include <CCTS\\Indicators\\Ex1\\IndicatorEx1_Rex.mqh>

//////////////////////////////////// Continuation Indicators //////////////////////////////
//#include <MyBot_v6\\Indicators\\IndicatorsCont\\ContIndicator_Rex.mqh>

//////////////////////////////////// V1 Indicators ////////////////////////////////////
#include <CCTS\\Indicators\\V1\\IndicatorV1_OBV_With_MA.mqh>

//////////////////////////////////// C2 Indicators ////////////////////////////////////
#include <CCTS\\Indicators\\C2\\IndicatorC2_None.mqh>

//////////////////////////////////// C1 Indicators ////////////////////////////////////
#include <CCTS\\Indicators\\C1\\IndicatorC1_None.mqh> 

//////////////////////////////////// BL2 Indicators //////////////////////////////
#include <CCTS\\Indicators\\BL2\\IndicatorBL2_None.mqh>

// In main EA at the moment
/*
void InitialiseIndicators()
  {
   Ex2Setup();
   Ex1Setup();
  // ContSetup();
   V1Setup();
   C2Setup();
   C1Setup();
   BL2Setup();

   Ex2Signals();
   Ex1Signals();
 //  ContinuationSignals();
   V1Signals();
   C2Signals();
   C1Signals();
   BL2Signals();
  }
  */

#endif 