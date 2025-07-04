//+------------------------------------------------------------------+
//|                                                CountOrders.mqh   |
//+------------------------------------------------------------------+
#property strict

#ifndef __COUNT_ORDERS_MQH__
#define __COUNT_ORDERS_MQH__

#include "..\CCTS\CCTS_Config.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"

//+------------------------------------------------------------------+
//| Count open orders for current symbol and magic number           |
//+------------------------------------------------------------------+
int MyOpenOrders()
  {
   RefreshRates();
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderSymbol()     == currentSymbol &&
            OrderMagicNumber()== MagicNumber)
           {
            count++;
           }
        }
      else
        {
         ErrorLog(__FUNCTION__, "Failed to select order", IntegerToString(i, 0), currentSymbol);
        }
     }
   return count;
  }

#endif
//+------------------------------------------------------------------+
