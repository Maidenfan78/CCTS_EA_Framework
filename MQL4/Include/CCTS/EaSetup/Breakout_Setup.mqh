//+------------------------------------------------------------------+
//|                                              Breakout_Setup.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property link      "https://www.CoolCherry.com"
#property strict

#ifndef __BREAKOUT_SETUP_MQH__
#define __BREAKOUT_SETUP_MQH__

extern string  SessionHeader          = "-------------------------- Session Selection --------------------------";
input bool     EnableAsianSession     = false;
input bool     EnableLondonSession    = true;
input bool     EnableNewYorkSession   = true;

extern string  DayHeader              = "-------------------------- Day of Week Filter Selection --------------------------";
input bool     AllowSunday            = false;
input bool     AllowMonday            = true;
input bool     AllowTuesday           = true;
input bool     AllowWednesday         = true;
input bool     AllowThursday          = true;
input bool     AllowFriday            = true;
input bool     AllowSaturday          = false;

extern string  IndicatorEnableHeader  = "-------------------------- Enable/Disable Indicators --------------------------";
input  bool    EnableBL2              = false;
input bool     EnableC1               = false;
input bool     EnableC2               = false;
input bool     EnableV1               = false;
input bool     EnableEx1              = false;
input bool     EnableEx2              = false;

extern string  EntrySelectHeader      = "-------------------------- Enable/Disable BL2, C1 Entry Type & Exit --------------------------";
input bool     UseCustomEntries       = true;
input bool     UseC1Entries           = false;
input bool     UseBL2Entries          = false;
input bool     UseATRFilter           = false;
input bool     UseCustomExits         = false;
input bool     UseC1AsExit            = false;
input bool     UseBL2AsExit           = false;

extern string  BarBreakout            = "-------------------------- Bar Breakout Inputs --------------------------";
input int      CompareBarsAgo         = 200;    // Bar index for the reference close (e.g., 200 bars ago)
input int      RangeStart             = 2;      // Starting index for the range (e.g., candle 2)
input int      RangeEnd               = 10;     // Ending index for the range (e.g., candle 10)

#endif