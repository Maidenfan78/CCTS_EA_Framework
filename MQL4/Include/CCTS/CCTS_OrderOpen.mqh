//+------------------------------------------------------------------+
//|                                               CCTS_OrderOpen.mqh |
//+------------------------------------------------------------------+
#property strict

#ifndef __ORDER_OPEN_MQH__
#define __ORDER_OPEN_MQH__

#include "..\CCTS\CCTS_Config.mqh"
#include "..\CCTS\CCTS_CountOrders.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"
#include "..\CCTS\CCTS_LogActions.mqh"
#include "..\CCTS\CCTS_LogTrades.mqh"
#include "..\CCTS\CCTS_PersistentVariables.mqh"
#include "..\CCTS\CCTS_CalculateDigitsPoints.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool openFirstOrder(ENUM_ORDER_TYPE orderType, double Sl, double Tp)
  {
   if(MyOpenOrders() != 0)
      return false;


   double pipSize          = GetPip();
   double Price            = 0;
   double stopLossPrice    = 0;
   double takeProfitPrice  = 0;
   bool   orderPlaced      = false;
   int    Ticket           = 0;
   string orderTypeString  = "";
   int    indColour = 0;
   int    indColourBuy        = clrGreen;
   int    indColourSell        = clrRed;

   RefreshRates();

   if(orderType == ORDER_TYPE_BUY)
     {
      indColour         = indColourBuy;
      Price             = SymbolInfoDouble(currentSymbol, SYMBOL_ASK);
      stopLossPrice     = NormalizeDouble(Price - Sl, digits);
      takeProfitPrice   = NormalizeDouble(Price + Tp, digits);


      orderTypeString      = "Buy";
     }
   else
      if(orderType == ORDER_TYPE_SELL)
        {
      indColour         = indColourSell;
         Price             = SymbolInfoDouble(currentSymbol, SYMBOL_BID);
         stopLossPrice     = NormalizeDouble(Price + Sl, digits);
         takeProfitPrice   = NormalizeDouble(Price - Tp, digits);
         orderTypeString   = "Sell";
        }

   int retryCount    = 0;
   int maxRetries    = 5;
   orderPlaced       = false;

   while(!orderPlaced && retryCount < maxRetries)
     {
      Ticket = OrderSend(currentSymbol, orderType, LotsVolume, Price, allowableSlippage, stopLossPrice, takeProfitPrice, tradeComment_1, MagicNumber, 0, indColour);

      if(Ticket > 0)
        {
         orderPlaced = true;
        }
      else
        {
         ErrorLog(__FUNCTION__, "Error opening order", IntegerToString(Ticket,0), currentSymbol, DoubleToStr(Price,digits), DoubleToString(takeProfitPrice,digits), DoubleToString(stopLossPrice,digits), DoubleToString(LotsVolume,2), orderTypeString, "1st order");

         Sleep(500);

         // ✅ Recalculate prices after refresh
         RefreshRates();

         if(orderType == ORDER_TYPE_BUY)
           {
            Price              = SymbolInfoDouble(currentSymbol, SYMBOL_ASK);
            stopLossPrice     = NormalizeDouble(Price - Sl, digits);
            takeProfitPrice   = NormalizeDouble(Price + Tp, digits);
           }
         else
            if(orderType == ORDER_TYPE_SELL)
              {
               Price           = SymbolInfoDouble(currentSymbol, SYMBOL_BID);
               stopLossPrice     = NormalizeDouble(Price + Sl, digits);
               takeProfitPrice   = NormalizeDouble(Price - Tp, digits);
              }
        }
      retryCount++;
     }

   if(orderPlaced)
     {
      openOrders                       = MyOpenOrders();
      variables.LastTradeOrderType     = orderTypeString;
     // variables.LastTradeBaselineTrend = BLTrend;
      variables.ContinuationEnabled    = false;
      variables.MovedToBE              = false;
      variables.TrailingStopAdjusted   = false;
      variables.baseLineFlipped        = false;
      variables.oldAtrValue            = ATRValue;
      variables.orderOpenPrice         = Price;
      variables.Hit95Target            = false;
     // stdSlHit                         = false;
     // tsSlHit                          = false;
      variables.stopLossHit            = false;
     // C1EntriesCount++;

      WriteToFile(fileName, variables);
      LogAction("Trade Opened", "1st order", DoubleToString(Ticket, 0), currentSymbol, DoubleToString(Price, digits), DoubleToString(takeProfitPrice, digits), DoubleToString(stopLossPrice, digits), DoubleToString(LotsVolume, 2), orderTypeString);
      return true;
     }
   else
     {
      openOrders = MyOpenOrders();
      return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool openSecondOrder(ENUM_ORDER_TYPE orderType, double Sl, double Tp_2)
  {
   if(MyOpenOrders() != 1)
      return false;

   double pipSize          = GetPip();
   double Price            = 0;
   double stopLossPrice    = 0;
   double takeProfitPrice  = 0;  // Initialize TP as 0 by default
   bool   orderPlaced      = false;
   int    Ticket           = 0;
   string orderTypeString  = "";
   int    indColour = 0;
   int    indColourBuy        = clrGreen;
   int    indColourSell        = clrRed;

// Calculate the open price, stop loss, and take profit prices based on the order type
   RefreshRates();

   if(orderType == ORDER_TYPE_BUY)
     {
      indColour         = indColourBuy;
      Price                = SymbolInfoDouble(currentSymbol, SYMBOL_ASK);
      stopLossPrice        = NormalizeDouble(Price - Sl, digits);
      orderTypeString      = "Buy";

      if(Use_Tp_2)
        {
         takeProfitPrice   = NormalizeDouble(Price + Tp_2, digits);
         Print("BUY: Take profit set at: ", takeProfitPrice);
        }
      else
        {
         Print("BUY: No take profit set.");
        }
     }
   else
      if(orderType == ORDER_TYPE_SELL)
        {
      indColour         = indColourSell;
         Price              = SymbolInfoDouble(currentSymbol, SYMBOL_BID);
         stopLossPrice      = NormalizeDouble(Price + Sl, digits);
         orderTypeString    = "Sell";

         if(Use_Tp_2)
           {
            takeProfitPrice   = NormalizeDouble(Price - Tp_2, digits);
            Print("SELL: Take profit set at: ", takeProfitPrice);
           }
         else
           {
            Print("SELL: No take profit set.");
           }
        }

   int retryCount = 0;
   int maxRetries = 5;
   orderPlaced    = false;

   while(!orderPlaced && retryCount < maxRetries)
     {
      Ticket = OrderSend(currentSymbol, orderType, LotsVolume, Price, allowableSlippage, stopLossPrice, takeProfitPrice, tradeComment_2, MagicNumber, 0, indColour);

      if(Ticket > 0)
        {
         orderPlaced = true;
        }
      else
        {
         ErrorLog(__FUNCTION__, "Error opening order", IntegerToString(Ticket,0), currentSymbol, DoubleToStr(Price,digits), DoubleToString(takeProfitPrice,digits), DoubleToString(stopLossPrice,digits), DoubleToString(LotsVolume,2), orderTypeString, "2nd order");

         Sleep(500);

         // ✅ Recalculate prices after refresh
         RefreshRates();

         if(orderType == ORDER_TYPE_BUY)
           {

            Price                = SymbolInfoDouble(currentSymbol, SYMBOL_ASK);
            stopLossPrice        = NormalizeDouble(Price - Sl, digits);
            orderTypeString      = "Buy";

            if(Use_Tp_2)
              {
               takeProfitPrice   = NormalizeDouble(Price + Tp_2, digits);
               Print("BUY: Take profit set at: ", takeProfitPrice);
              }
            else
              {
               Print("BUY: No take profit set.");
              }
           }
         else
            if(orderType == ORDER_TYPE_SELL)
              {

               Price              = SymbolInfoDouble(currentSymbol, SYMBOL_BID);
               stopLossPrice      = NormalizeDouble(Price + Sl, digits);
               orderTypeString    = "Sell";

               if(Use_Tp_2)
                 {
                  takeProfitPrice   = NormalizeDouble(Price - Tp_2, digits);
                  Print("SELL: Take profit set at: ", takeProfitPrice);
                 }
               else
                 {
                  Print("SELL: No take profit set.");
                 }
              }
        }
      retryCount++;
     }

   if(orderPlaced)
     {
      openOrders = MyOpenOrders();
      LogAction("Trade Opened", "2nd order", DoubleToString(Ticket, 0), currentSymbol, DoubleToString(Price, digits), DoubleToString(takeProfitPrice, digits), DoubleToString(stopLossPrice, digits), DoubleToString(LotsVolume, 2), orderTypeString);
      WriteToFile(fileName, variables);

      return true;
     }
   else
     {
      openOrders = MyOpenOrders();
      return false;
     }
  }
  
  #endif 

