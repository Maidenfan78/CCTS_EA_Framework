//+------------------------------------------------------------------+
//|                                               CCTS_LogTrades.mqh |
//+------------------------------------------------------------------+
#property strict
#ifndef __LOG_TRADES2_MQH__
#define __LOG_TRADES2_MQH__

#include "CCTS_Config.mqh"
#include "CCTS_LogUtils.mqh"

string LogTradeFileName = "Logs/TradeHistory";

void LogTrade()
  {
   EnsureLogsDirectory();
   string csvFilename = LogTradeFileName + "_" + eaTitle + ".csv";
   bool   isNewFile   = !FileIsExist(csvFilename);
   int    fileHandle  = FileOpen(csvFilename,
                                 FILE_READ | FILE_WRITE | FILE_CSV,
                                 ',');

   if(fileHandle < 0)
     {
      Print("Failed to open file: ", csvFilename);
      return;
     }

   FileSeek(fileHandle, 0, SEEK_END);

   if(isNewFile)
     {
      // UTF-8 BOM
      uchar bom[3] = {0xEF,0xBB,0xBF};
      FileWriteArray(fileHandle, bom, 0, 3);

      // Header
      FileWrite(fileHandle,
                "EAName","EntryTime","ExitTime","Symbol","Timeframe","MagicNumber","TicketNumber","OrderType",
                "LotSize","InitialRisk","RMultiple",
                "OpenPrice","ClosePrice","TakeProfit","StopLoss",
                "Profit","ProfitDirection","DurationDays","DurationHours",
                "DurationMinutes","DealComment","ClosureReason");
     }

   for(int i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;

      // get the raw comment
      string dealComment = OrderComment();

      // only log if comment contains eaTitle
      if(StringFind(dealComment, eaTitle) < 0)
        {
         //PrintFormat("Skipping ticket %d: comment '%s' does not contain '%s'",
         //            OrderTicket(), dealComment, eaTitle);
         continue;
        }

      datetime openTime  = OrderOpenTime();
      datetime closeTime = OrderCloseTime();
      int      secs      = int(closeTime - openTime);
      int      dDays     = secs/86400;
      int      dHours    = (secs%86400)/3600;
      int      dMins     = (secs%3600)/60;

      string orderType = (OrderType()==ORDER_TYPE_BUY ? "BUY" :
                          OrderType()==ORDER_TYPE_SELL? "SELL" : "UNKNOWN");

      double profit    = OrderProfit()+OrderSwap()+OrderCommission();
      string pDir      = (profit<0 ? "LOSS" : "PROFIT");

      double lots      = OrderLots();
      double pipValue  = MarketInfo(OrderSymbol(), MODE_TICKVALUE);
      double slPips    = MathAbs(OrderOpenPrice()-OrderStopLoss())/Point;
      double initRisk  = lots*slPips*pipValue;
      double rMult     = (initRisk>0 ? profit/initRisk : 0.0);

      string tf;
      switch(Period())
        {
         case PERIOD_M1:  tf="M1";  break;
         case PERIOD_M5:  tf="M5";  break;
         case PERIOD_M15: tf="M15"; break;
         case PERIOD_M30: tf="M30"; break;
         case PERIOD_H1:  tf="H1";  break;
         case PERIOD_H4:  tf="H4";  break;
         case PERIOD_D1:  tf="D1";  break;
         case PERIOD_W1:  tf="W1";  break;
         case PERIOD_MN1: tf="MN1"; break;
         default:         tf=IntegerToString(Period()); break;
        }

      FileWrite(fileHandle,
                eaTitle,
                TimeToStr(openTime, TIME_DATE|TIME_SECONDS),
                TimeToStr(closeTime, TIME_DATE|TIME_SECONDS),
                OrderSymbol(),
                tf,
                OrderMagicNumber(),
                OrderTicket(),
                orderType,
                DoubleToStr(lots,2),
                DoubleToStr(initRisk,2),
                DoubleToStr(rMult,2),
                DoubleToStr(OrderOpenPrice(),Digits),
                DoubleToStr(OrderClosePrice(),Digits),
                DoubleToStr(OrderTakeProfit(),Digits),
                DoubleToStr(OrderStopLoss(),Digits),
                DoubleToStr(MathAbs(profit),2),
                pDir,
                dDays, dHours, dMins,
                dealComment,
                "Closed");
     }

   FileClose(fileHandle);
  // Print("File successfully created: ", csvFilename);
  // Alert("CSV saved to ", csvFilename);
  }

#endif // __LOG_TRADES2_MQH__
