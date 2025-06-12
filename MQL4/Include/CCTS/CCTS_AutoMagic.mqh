//+------------------------------------------------------------------+
//|                                               CCTS_AutoMagic.mqh |
//|                                                              Sav |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Sav"
#property link      "https://www.mql5.com"
#property strict

#ifndef __MAGIC_AUTO_MQH__
#define __MAGIC_AUTO_MQH__

#include "..\CCTS\CCTS_Config.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int AutoMagic()
  {
   string sym = currentSymbol;
   StringReplace(sym, ".I", "");

   string base_str = "";
   for(int i = 0; i < StringLen(sym); i++)
     {
      ushort char_code = StringGetCharacter(sym, i);
      if(char_code >= 'A' && char_code <= 'Z')
         base_str += IntegerToString(char_code - 'A' + 1);
     }

   if(StringLen(base_str) == 0)
     {
      // Fallback hash
      int hash = 0;
      for(int i = 0; i < StringLen(sym); i++)
         hash = (hash << 5) - hash + StringGetCharacter(sym, i);
      return MathAbs(hash % 100000000);
     }

   base_str = StringSubstr(base_str, 0, 9);
   return (int)StrToInteger(base_str);
  }


#endif
//+------------------------------------------------------------------+
