//+------------------------------------------------------------------+
//|                                        CCTS_LogTradesBacktest.mqh |
//+------------------------------------------------------------------+
#property strict
#ifndef __LOG_TRADES_BACKTEST_MQH__
#define __LOG_TRADES_BACKTEST_MQH__

#include <CCTS\CCTS_Config.mqh>  // defines extern string eaTitle
#include <CCTS\CCTS_LogUtils.mqh>

string LogBacktestTradeFileName = "Logs/BacktestTradeHistory";

void LogTradeBacktest()
{
   EnsureLogsDirectory();
   // build full filename
   string csvFilename = LogBacktestTradeFileName + "_" + eaTitle + ".csv";

   // check if file already exists
   bool isNewFile = !FileIsExist(csvFilename);

   // open for read+write in CSV mode
   int handle = FileOpen(csvFilename,
                         FILE_READ  // allow checking size
                       | FILE_WRITE // allow writing/appending
                       | FILE_CSV,  // CSV parsing/writing
                         ','       // delimiter
                       );

   if(handle < 0)
   {
      Print("Failed to open CSV log: ", csvFilename);
      return;
   }

   // jump to end so we append
   FileSeek(handle, 0, SEEK_END);

   // if brand-new file, write BOM + header row
   if(isNewFile)
   {
      // UTF-8 BOM
      uchar bom[3] = {0xEF,0xBB,0xBF};
      FileWriteArray(handle, bom, 0, 3);

      // header columns
      FileWrite(handle,
         "EAName","EntryTime","ExitTime","Symbol","Timeframe","MagicNumber","TicketNumber","OrderType",
         "LotSize","InitialRisk","RMultiple",
         "OpenPrice","ClosePrice","TakeProfit","StopLoss",
         "Profit","ProfitDirection","DurationDays","DurationHours",
         "DurationMinutes","DealComment","ClosureReason"
      );
   }

   // loop through your closed orders history and write rows
   for(int idx = OrdersHistoryTotal() - 1; idx >= 0; idx--)
   {
      if(!OrderSelect(idx, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(StringFind(OrderComment(), eaTitle) < 0)
         continue;

      datetime openTime  = OrderOpenTime();
      datetime closeTime = OrderCloseTime();
      int secs = int(closeTime - openTime);
      int dDays  = secs / 86400;
      int dHours = (secs % 86400) / 3600;
      int dMins  = (secs % 3600) / 60;

      string orderType = (OrderType() == ORDER_TYPE_BUY ? "BUY" :
                          OrderType() == ORDER_TYPE_SELL? "SELL" : "UNKNOWN");

      double profit = OrderProfit() + OrderSwap() + OrderCommission();
      string pDir   = (profit < 0 ? "LOSS" : "PROFIT");

      double lots     = OrderLots();
      double pipValue = MarketInfo(OrderSymbol(), MODE_TICKVALUE);
      double slPips   = MathAbs(OrderOpenPrice() - OrderStopLoss()) / Point;
      double initRisk = lots * slPips * pipValue;
      double rMult    = (initRisk > 0 ? profit / initRisk : 0.0);

      // map Period() to text
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
         default:         tf = IntegerToString(Period()); break;
      }

      // write one CSV row
      FileWrite(handle,
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
         DoubleToStr(OrderOpenPrice(), Digits),
         DoubleToStr(OrderClosePrice(), Digits),
         DoubleToStr(OrderTakeProfit(), Digits),
         DoubleToStr(OrderStopLoss(), Digits),
         DoubleToStr(MathAbs(profit),2),
         pDir,
         dDays, dHours, dMins,
         OrderComment(),
         "Closed"
      );
   }

   FileClose(handle);
}

#endif // __LOG_TRADES2_MQH__
