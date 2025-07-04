//+------------------------------------------------------------------+
//|                                             CCTS_CloseTrades.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property link      "https://www.CoolCherry.com"
#property strict

#ifndef __CLOSE_TRADES_MQH__
#define __CLOSE_TRADES_MQH__

#include "..\CCTS\CCTS_Config.mqh"
#include "..\CCTS\CCTS_CountOrders.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"
#include "..\CCTS\CCTS_LogActions.mqh"
#include "..\CCTS\CCTS_LogTrades.mqh"
#include "..\CCTS\CCTS_PersistentVariables.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CustomExitOn(int closeLong, int closeShort)
  {
   if(closeLong == 1)
      CloseAllCustom();  // or CloseAllLongCustom();
   if(closeShort == 1)
      CloseAllCustom();  // or CloseAllShortCustom();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void C1ExitOn()
  {
   if(C1SignalCross == "Short")
     {
      CloseAllC1(ORDER_TYPE_BUY);
     }
   else
      if(C1SignalCross == "Long")
        {
         CloseAllC1(ORDER_TYPE_SELL);
        }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BL2ExitOn()
  {
   if(BL2SignalCross == "Short")
     {
      CloseAllBL2(ORDER_TYPE_BUY);
     }
   else
      if(BL2SignalCross == "Long")
        {
         CloseAllBL2(ORDER_TYPE_SELL);
        }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FastExitIndicatorOn()
  {
   if(Ex1SignalCross == "Exit Long")
     {
      CloseAllEx1(ORDER_TYPE_BUY);
     }
   else
      if(Ex1SignalCross == "Exit Short")
        {
         CloseAllEx1(ORDER_TYPE_SELL);
        }
  }
///////////////////////////////////////////////////////////////////
void SlowExitIndicatorOn()
  {
   if(Ex2SignalCross == "Exit Long")
     {
      CloseAllEx2(ORDER_TYPE_BUY);
     }
   else
      if(Ex2SignalCross == "Exit Short")
        {
         CloseAllEx2(ORDER_TYPE_SELL);
        }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllCustom()
  {
// 1) only proceed if exactly one EA trade is open
//  if(MyOpenOrders() != 1)
 //    return;

   int       attempts   = 0;
   const int MAX_PASSES = 3;

// 2) retry the full close‐pass until the runner is gone or we hit MAX_PASSES
   while(MyOpenOrders() > 0 && attempts < MAX_PASSES)
     {
      // 3) scan all orders
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
         if(OrderSymbol()     != currentSymbol ||
            OrderMagicNumber()!= MagicNumber)
            continue;

         // 4) pull ticket details
         int    Ticket    = OrderTicket();
         double lots      = OrderLots();
         int    type      = OrderType();
         RefreshRates();
         double ClosePrice = NormalizeDouble(
                                (type == ORDER_TYPE_BUY
                                 ? SymbolInfoDouble(currentSymbol, SYMBOL_BID)
                                 : SymbolInfoDouble(currentSymbol, SYMBOL_ASK))
                                , digits);

         if(ClosePrice <= 0)
           {
            ErrorLog(__FUNCTION__, "Invalid price", IntegerToString(Ticket,0));
            continue;
           }

         // 5) retry on requote up to 5×
         bool closed = false;
         for(int retry = 0; retry < 5 && !closed; retry++)
           {
            closed = OrderClose(Ticket, lots, ClosePrice, allowableSlippage, clrRed);
            if(!closed && GetLastError() == ERR_REQUOTE)
              {
               Sleep(300);
               RefreshRates();
               ClosePrice = NormalizeDouble(
                               (type == ORDER_TYPE_BUY ? Bid : Ask)
                               , digits);
              }
           }

         // 6) update flags & logs on a successful close
         if(closed)
           {
            variables.ContinuationEnabled = true;
            variables.Hit95Target         = false;
            variables.LastTradeEx2Exit    = Ex2SignalCross;
            variables.MovedToBE           = false;
            WriteToFile(fileName, variables);

            double profit = OrderProfit();
            LogAction("Trade Closed", "Custom Exit", DoubleToString(Ticket, 0), currentSymbol, DoubleToString(ClosePrice, digits), DoubleToString(profit, 2));
            LogTrade();
           }

         // only one runner to close, break out after attempting it
         break;
        }

      // short pause before re-check
      Sleep(200);
      RefreshRates();
      attempts++;
     }

// 7) final sanity check
   if(MyOpenOrders() > 0)
      Print(__FUNCTION__,
            ": Failed to close runner trade after ",
            MAX_PASSES, " passes");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// Close positions with BL2 indicator
void CloseAllBL2(ENUM_ORDER_TYPE order_Type)
  {
// 1) only proceed when you’ve got exactly two EA trades open
   if(MyOpenOrders() != 2)
      return;

   int       attempts     = 0;
   const int MAX_ATTEMPTS = 3;

// 2) retry the full close-pass until no trades remain or we exceed MAX_ATTEMPTS
   while(MyOpenOrders() > 0 && attempts < MAX_ATTEMPTS)
     {
      // 3) walk the entire trade pool
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
         if(OrderSymbol()     != currentSymbol ||
            OrderMagicNumber()!= MagicNumber)
            continue;

         // 4) pull ticket details
         int    Ticket = OrderTicket();
         double lots   = OrderLots();
         int    type   = OrderType();

         RefreshRates();
         double ClosePrice = NormalizeDouble(
                                (type == ORDER_TYPE_BUY
                                 ? SymbolInfoDouble(currentSymbol, SYMBOL_BID)
                                 : SymbolInfoDouble(currentSymbol, SYMBOL_ASK))
                                , digits);

         if(ClosePrice <= 0)
           {
            ErrorLog(__FUNCTION__, "Invalid price", IntegerToString(Ticket,0));
            continue;
           }

         // 5) retry on requote up to 5 times
         bool closed = false;
         for(int retry = 0; retry < 5 && !closed; retry++)
           {
            closed = OrderClose(Ticket, lots, ClosePrice, allowableSlippage, clrRed);
            if(!closed && GetLastError() == ERR_REQUOTE)
              {
               Sleep(300);
               RefreshRates();
               ClosePrice = NormalizeDouble(
                               (type == ORDER_TYPE_BUY ? Bid : Ask)
                               , digits);
              }
           }

         // 6) if we got it, update flags & logs
         if(closed)
           {
            variables.ContinuationEnabled = false;
            variables.Hit95Target         = false;
            variables.MovedToBE           = false;
            WriteToFile(fileName, variables);

            double profit = OrderProfit();
            LogAction("Trade Closed", "BL2 Exit", DoubleToString(Ticket, 0), currentSymbol, DoubleToString(ClosePrice, digits), DoubleToString(profit, 2));
            LogTrade();
           }
        }

      // small pause before next full pass
      Sleep(200);
      RefreshRates();
      attempts++;
     }

// 7) final sanity check
   if(MyOpenOrders() > 0)
      Print(__FUNCTION__,
            ": Failed to close ", MyOpenOrders(),
            " trades after ", MAX_ATTEMPTS, " attempts");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// Close positions with C1 indicator
void CloseAllC1(ENUM_ORDER_TYPE order_Type)
  {
// 1) only proceed when you’ve got exactly two EA trades open
   if(MyOpenOrders() != 2)
      return;

   int       attempts     = 0;
   const int MAX_ATTEMPTS = 3;

// 2) retry the full close-pass until no trades remain or we exceed MAX_ATTEMPTS
   while(MyOpenOrders() > 0 && attempts < MAX_ATTEMPTS)
     {
      // 3) walk the entire trade pool
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
         if(OrderSymbol()     != currentSymbol ||
            OrderMagicNumber()!= MagicNumber)
            continue;

         // 4) pull ticket details
         int    Ticket = OrderTicket();
         double lots   = OrderLots();
         int    type   = OrderType();

         RefreshRates();
         double ClosePrice = NormalizeDouble(
                                (type == ORDER_TYPE_BUY
                                 ? SymbolInfoDouble(currentSymbol, SYMBOL_BID)
                                 : SymbolInfoDouble(currentSymbol, SYMBOL_ASK))
                                , digits);

         if(ClosePrice <= 0)
           {
            ErrorLog(__FUNCTION__, "Invalid price", IntegerToString(Ticket,0));
            continue;
           }

         // 5) retry on requote up to 5 times
         bool closed = false;
         for(int retry = 0; retry < 5 && !closed; retry++)
           {
            closed = OrderClose(Ticket, lots, ClosePrice, allowableSlippage, clrRed);
            if(!closed && GetLastError() == ERR_REQUOTE)
              {
               Sleep(300);
               RefreshRates();
               ClosePrice = NormalizeDouble(
                               (type == ORDER_TYPE_BUY ? Bid : Ask)
                               , digits);
              }
           }

         // 6) if we got it, update flags & logs
         if(closed)
           {
            variables.ContinuationEnabled = false;
            variables.Hit95Target         = false;
            variables.MovedToBE           = false;
            WriteToFile(fileName, variables);

            double profit = OrderProfit();
            LogAction("Trade Closed", "C1 Exit", DoubleToString(Ticket, 0), currentSymbol, DoubleToString(ClosePrice, digits), DoubleToString(profit, 2));
            LogTrade();
           }
        }

      // small pause before next full pass
      Sleep(200);
      RefreshRates();
      attempts++;
     }

// 7) final sanity check
   if(MyOpenOrders() > 0)
      Print(__FUNCTION__,
            ": Failed to close ", MyOpenOrders(),
            " trades after ", MAX_ATTEMPTS, " attempts");
  }
//Close positions with Ex1///////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Close both trades if—and only if—you have exactly two open       |
//+------------------------------------------------------------------+
void CloseAllEx1(ENUM_ORDER_TYPE order_Type)
  {
// 1) only proceed when you’ve got exactly two EA trades open
   if(MyOpenOrders() != 2)
      return;

   int       attempts     = 0;
   const int MAX_ATTEMPTS = 3;

// 2) retry the full close-pass until no trades remain or we exceed MAX_ATTEMPTS
   while(MyOpenOrders() > 0 && attempts < MAX_ATTEMPTS)
     {
      // 3) walk the entire trade pool
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
         if(OrderSymbol()     != currentSymbol ||
            OrderMagicNumber()!= MagicNumber)
            continue;

         // 4) pull ticket details
         int    Ticket = OrderTicket();
         double lots   = OrderLots();
         int    type   = OrderType();

         RefreshRates();
         double ClosePrice = NormalizeDouble(
                                (type == ORDER_TYPE_BUY
                                 ? SymbolInfoDouble(currentSymbol, SYMBOL_BID)
                                 : SymbolInfoDouble(currentSymbol, SYMBOL_ASK))
                                , digits);

         if(ClosePrice <= 0)
           {
            ErrorLog(__FUNCTION__, "Invalid price", IntegerToString(Ticket,0));
            continue;
           }

         // 5) retry on requote up to 5 times
         bool closed = false;
         for(int retry = 0; retry < 5 && !closed; retry++)
           {
            closed = OrderClose(Ticket, lots, ClosePrice, allowableSlippage, clrRed);
            if(!closed && GetLastError() == ERR_REQUOTE)
              {
               Sleep(300);
               RefreshRates();
               ClosePrice = NormalizeDouble(
                               (type == ORDER_TYPE_BUY ? Bid : Ask)
                               , digits);
              }
           }

         // 6) if we got it, update flags & logs
         if(closed)
           {
            variables.ContinuationEnabled = false;
            variables.Hit95Target         = false;
            variables.MovedToBE           = false;
            WriteToFile(fileName, variables);

            double profit = OrderProfit();
            LogAction("Trade Closed", "Ex1", DoubleToString(Ticket, 0), currentSymbol, DoubleToString(ClosePrice, digits), DoubleToString(profit, 2));
            LogTrade();
           }
        }

      // small pause before next full pass
      Sleep(200);
      RefreshRates();
      attempts++;
     }

// 7) final sanity check
   if(MyOpenOrders() > 0)
      Print(__FUNCTION__,
            ": Failed to close ", MyOpenOrders(),
            " trades after ", MAX_ATTEMPTS, " attempts");
  }

//Close positions with Ex2///////////////////////////////////////////////////////////////////
//+------------------------------------------------------------------+
//| Close the runner trade when—and only when—exactly one is open    |
//+------------------------------------------------------------------+
void CloseAllEx2(ENUM_ORDER_TYPE order_Type)
  {
// 1) only proceed if exactly one EA trade is open
   if(MyOpenOrders() != 1)
      return;

   int       attempts   = 0;
   const int MAX_PASSES = 3;

// 2) retry the full close‐pass until the runner is gone or we hit MAX_PASSES
   while(MyOpenOrders() > 0 && attempts < MAX_PASSES)
     {
      // 3) scan all orders
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
         if(OrderSymbol()     != currentSymbol ||
            OrderMagicNumber()!= MagicNumber)
            continue;

         // 4) pull ticket details
         int    Ticket    = OrderTicket();
         double lots      = OrderLots();
         int    type      = OrderType();
         RefreshRates();
         double ClosePrice = NormalizeDouble(
                                (type == ORDER_TYPE_BUY
                                 ? SymbolInfoDouble(currentSymbol, SYMBOL_BID)
                                 : SymbolInfoDouble(currentSymbol, SYMBOL_ASK))
                                , digits);

         if(ClosePrice <= 0)
           {
            ErrorLog(__FUNCTION__, "Invalid price", IntegerToString(Ticket,0));
            continue;
           }

         // 5) retry on requote up to 5×
         bool closed = false;
         for(int retry = 0; retry < 5 && !closed; retry++)
           {
            closed = OrderClose(Ticket, lots, ClosePrice, allowableSlippage, clrRed);
            if(!closed && GetLastError() == ERR_REQUOTE)
              {
               Sleep(300);
               RefreshRates();
               ClosePrice = NormalizeDouble(
                               (type == ORDER_TYPE_BUY ? Bid : Ask)
                               , digits);
              }
           }

         // 6) update flags & logs on a successful close
         if(closed)
           {
            variables.ContinuationEnabled = true;
            variables.Hit95Target         = false;
            variables.LastTradeEx2Exit    = Ex2SignalCross;
            variables.MovedToBE           = false;
            WriteToFile(fileName, variables);

            double profit = OrderProfit();
            LogAction("Trade Closed", "Ex2", DoubleToString(Ticket, 0), currentSymbol, DoubleToString(ClosePrice, digits), DoubleToString(profit, 2));
            LogTrade();
           }

         // only one runner to close, break out after attempting it
         break;
        }

      // short pause before re-check
      Sleep(200);
      RefreshRates();
      attempts++;
     }

// 7) final sanity check
   if(MyOpenOrders() > 0)
      Print(__FUNCTION__,
            ": Failed to close runner trade after ",
            MAX_PASSES, " passes");
  }

#endif
//+------------------------------------------------------------------+
