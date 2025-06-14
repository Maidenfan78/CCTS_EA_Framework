//+------------------------------------------------------------------+
//|                                         CCTS_MoneyManagement.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property link      "https://www.CoolCherry.com"
#property strict

#ifndef __MONEY_MANAGEMENT_MQH__
#define __MONEY_MANAGEMENT_MQH__

#include "..\CCTS\CCTS_CalculateDigitsPoints.mqh"
#include "..\CCTS\CCTS_Config.mqh"
#include "..\CCTS\CCTS_CountOrders.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"
#include "..\CCTS\CCTS_LogActions.mqh"
#include "..\CCTS\CCTS_LogTrades.mqh"
#include "..\CCTS\CCTS_PersistentVariables.mqh"

//+------------------------------------------------------------------+
//| Move SL to breakeven when Order 1 closes                        |
//+------------------------------------------------------------------+
bool MoveToBreakEven(ENUM_ORDER_TYPE orderType)
  {
   if(MyOpenOrders() != 1 || variables.MovedToBE == true)
      return false;

   RefreshRates();
   double pipSize       = GetPip();
   bool   orderModified = false;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != currentSymbol || OrderMagicNumber() != MagicNumber)
         continue;

      double openPrice   = NormalizeDouble(OrderOpenPrice(), digits);
      int    ticket      = OrderTicket();
      double currentTP   = NormalizeDouble(OrderTakeProfit(), digits);
      double currentSL   = NormalizeDouble(OrderStopLoss(), digits);
      double newStopLoss = openPrice;

      // already at breakeven?
      if((orderType==ORDER_TYPE_BUY && currentSL>=openPrice) ||
         (orderType==ORDER_TYPE_SELL && currentSL<=openPrice))
        {
         variables.MovedToBE = true;
         break;
        }

      // compute new TP2 if enabled
      double newTakeProfit = 0;
      if(Use_Tp_2)
         newTakeProfit = (orderType==ORDER_TYPE_BUY)
                         ? openPrice + ATRValue * ATR_TrailingMultiplier * pipSize
                         : openPrice - ATRValue * ATR_TrailingMultiplier * pipSize;

      if(!OrderModify(ticket,
                      openPrice,
                      newStopLoss,
                      newTakeProfit,   // apply it here
                      0,
                      clrYellow))
        {
         ErrorLog(__FUNCTION__, "Error adjusting stop loss", IntegerToString(ticket), currentSymbol, DoubleToString(newTakeProfit,digits), DoubleToString(newStopLoss,digits));
        }
      else
        {
         LogAction("Stop loss adjusted", "Breakeven set", IntegerToString(ticket), currentSymbol,DoubleToString(newTakeProfit,digits),DoubleToString(newStopLoss,digits));
         variables.MovedToBE = true;
         orderModified       = true;
         WriteToFile(fileName, variables);
        }
      break;  // only adjust one order
     }
   return orderModified;
  }
//+------------------------------------------------------------------+
//|  Update Trailing Stop (ATR or Fixed Gap)                         |
//+------------------------------------------------------------------+
void UpdateTrailingStopSimple(double trailingStopGap)
  {
   RefreshRates();
   double bid         = NormalizeDouble(SymbolInfoDouble(currentSymbol, SYMBOL_BID), digits);
   double ask         = NormalizeDouble(SymbolInfoDouble(currentSymbol, SYMBOL_ASK), digits);
   double buyTSPrice  = NormalizeDouble(bid - trailingStopGap, digits);
   double sellTSPrice = NormalizeDouble(ask + trailingStopGap, digits);
   UpdateTrailingStop(buyTSPrice, sellTSPrice);

  }

//+------------------------------------------------------------------+
//|  ATR-Based Trailing Stop                                         |
//+------------------------------------------------------------------+
void UpdateTrailingStopATR(bool newBar)
  {
   static double atrGap = 0;
   if(newBar || atrGap == 0)
     {
      ATRValue = iATR(currentSymbol, Period(), ATR_Period, 1);
      ATRValue = NormalizeDouble(ATRValue, digits);
      atrGap   = NormalizeDouble(ATRValue * ATR_TrailingMultiplier, digits);

     }
   if(atrGap == 0)
      return;

   UpdateTrailingStopSimple(atrGap);
  }

//+------------------------------------------------------------------+
//|  Main Trailing Stop Function                                     |
//+------------------------------------------------------------------+
void UpdateTrailingStop(double buyTSPrice, double sellTSPrice)
  {
// only proceed if exactly one order is open
   if(MyOpenOrders() != 1)
      return;

   bool success      = true;
   int  failedIndex  = -1;
   int  failedTicket = -1;

// loop through your trades
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != currentSymbol || OrderMagicNumber() != MagicNumber)
         continue;

      int    ticket    = OrderTicket();
      double currentSL = NormalizeDouble(OrderStopLoss(), digits);
      double currentTP = NormalizeDouble(OrderTakeProfit(), digits);
      double openPrice = NormalizeDouble(OrderOpenPrice(), digits);

      // BUY side
      if(OrderType() == ORDER_TYPE_BUY)
        {
         double bid       = MarketInfo(currentSymbol, MODE_BID);
         double profitPts = NormalizeDouble(bid - openPrice, digits);

         // only start trailing once profit ≥ ATR_TrailingStart * ATRValue
         if(profitPts < ATRValue * ATR_TrailingStart)
            continue;

         if((currentSL == 0.0 || buyTSPrice > currentSL) &&
            (buyTSPrice >= openPrice))
           {
            if(!OrderModify(ticket, openPrice, buyTSPrice, currentTP, 0, clrOrange))
              {
               success      = false;
               failedIndex  = i;
               failedTicket = ticket;
              }
            else
              {
               LogAction("Stop loss adjusted",
                         "Trailing stop adjusted",
                         IntegerToString(ticket),
                         currentSymbol,
                         DoubleToString(currentTP,   digits),
                         DoubleToString(buyTSPrice, digits));
                         variables.TrailingStopAdjusted = true;
               openOrders = MyOpenOrders();
              }
           }
        }
      // SELL side
      else
         if(OrderType() == ORDER_TYPE_SELL)
           {
            double ask       = MarketInfo(currentSymbol, MODE_ASK);
            double profitPts = NormalizeDouble(openPrice - ask, digits);

            // only start trailing once profit ≥ ATR_TrailingStart * ATRValue
            if(profitPts < ATRValue * ATR_TrailingStart)
               continue;

            if((currentSL == 0.0 || sellTSPrice < currentSL) &&
               (sellTSPrice <= openPrice))
              {
               if(!OrderModify(ticket, openPrice, sellTSPrice, currentTP, 0, clrOrange))
                 {
                  success      = false;
                  failedIndex  = i;
                  failedTicket = ticket;
                 }
               else
                 {
                  LogAction("Stop loss adjusted",
                            "Trailing stop adjusted",
                            IntegerToString(ticket),
                            currentSymbol,
                            DoubleToString(currentTP,    digits),
                            DoubleToString(sellTSPrice, digits));
                            variables.TrailingStopAdjusted = true;
                  openOrders = MyOpenOrders();
                 }
              }
           }
     }

// If any modification failed, log it with the correct ticket/index
   if(!success)
     {
      ErrorLog(__FUNCTION__,
               "Error adjusting stop loss",
               IntegerToString(failedTicket, 0),
               currentSymbol,
               IntegerToString(failedIndex, 0),
               DoubleToString(OrderStopLoss(), digits),
               "Failed to move trailing stop");
     }
  }



#endif
//+------------------------------------------------------------------+
