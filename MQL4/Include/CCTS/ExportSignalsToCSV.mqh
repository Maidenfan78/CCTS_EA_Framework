//+------------------------------------------------------------------+
//|                   ExportSignalsToCSV.mqh                         |
//|  Include this file in your EA to dump OHLC + trade/exit signals  |
//+------------------------------------------------------------------+
#property strict

#include <CCTS/EaSetup/Breakout_Signals.mqh>  // adjust path if needed

//--- User inputs for signal export
extern string SignalFilenamePrefix = "signals_labeled";  // Prefix: signals_labeled_<magic>.csv
extern int    BackfillBars         = 1460;                // Increased default to cover more history

//--- Internal globals
static datetime recorded[];   // track which timestamps have been written
MqlRates        rates[];      // buffer for CopyRates

//+------------------------------------------------------------------+
//| Build filename including magic                                  |
//+------------------------------------------------------------------+
string GetSignalFilename()
{
   return(StringFormat("%s_%s.csv", SignalFilenamePrefix, magicNumberString));
}

//+------------------------------------------------------------------+
//| Initialize/truncate CSV + write header                          |
//+------------------------------------------------------------------+
void InitSignalsFile()
{
   int fh = FileOpen(GetSignalFilename(), FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(fh < 0)
   {
      PrintFormat("[SignalExport] Failed to init %s (Error %d)", GetSignalFilename(), GetLastError());
      return;
   }
   FileWriteString(fh, "Time,Open,High,Low,Close,Volume,tradeSignalLong,tradeSignalShort,exitSignalLong,exitSignalShort\r\n");
   FileClose(fh);
   ArrayResize(recorded, 0);
}

//+------------------------------------------------------------------+
//| Append a single row to CSV                                       |
//+------------------------------------------------------------------+
void RecordSignalsWithValues(
   datetime t,double o,double h,double l,double c,long v,
   int tsLong,int tsShort,int exLong,int exShort)
{
   int fh = FileOpen(GetSignalFilename(), FILE_READ|FILE_WRITE|FILE_ANSI);
   if(fh < 0)
      return;
   FileSeek(fh,0,SEEK_END);
   string line=StringFormat(
      "%s,%g,%g,%g,%g,%d,%d,%d,%d,%d\r\n",
      TimeToString(t,TIME_DATE|TIME_MINUTES),o,h,l,c,v,tsLong,tsShort,exLong,exShort);
   FileWriteString(fh,line);
   FileClose(fh);
   ArrayResize(recorded,ArraySize(recorded)+1);
   recorded[ArraySize(recorded)-1]=t;
}

//+------------------------------------------------------------------+
//| On EA init: backfill history in chronological order             |
//+------------------------------------------------------------------+
void StartSignalExport()
{
   if(!FileExists(GetSignalFilename()))
      InitSignalsFile();

   int want = BackfillBars;
   int total = CopyRates(_Symbol,Period(),0,want,rates);
   
   // Fixed diagnostic prints
   PrintFormat("[SignalExport] Requested %d bars, received %d bars", want, total);
   if(total >= 1)
   {
      PrintFormat("Newest bar: %s", TimeToString(rates[0].time));
      PrintFormat("Oldest bar: %s", TimeToString(rates[total-1].time));
   }
   
   if(total<2) 
   {
      Alert("Insufficient historical data! Only ", total, " bars available.");
      Print("Check historical data for ", _Symbol, " timeframe: ", Period(), " minutes");
      return;
   }

   int barsToFill=MathMin(BackfillBars,total-1);
   
   // Warn if data is insufficient
   if(barsToFill < 100) 
   {
      Alert("Warning: Only ", barsToFill, " bars available for backfill!");
      Print("Check historical data for ", _Symbol, " timeframe: ", Period(), " minutes");
   }
   
   // Collect lines in time order (oldest first)
   string lines[];
   ArrayResize(lines,barsToFill);
   for(int idx=0; idx<barsToFill; idx++)
   {
      int shift = idx + 1;  // 1 = newest completed bar
      MqlRates r = rates[shift];
      int tsL=0,tsS=0,exL=0,exS=0;
      signals_at(shift,tsL,tsS,exL,exS);
      lines[idx]=StringFormat(
         "%s,%g,%g,%g,%g,%d,%d,%d,%d,%d\r\n",
         TimeToString(r.time,TIME_DATE|TIME_MINUTES), r.open, r.high, r.low, r.close,
         r.tick_volume, tsL, tsS, exL, exS);
   }

   // Rewrite file: header + lines
   int fh=FileOpen(GetSignalFilename(), FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(fh<0) return;
   FileWriteString(fh,"Time,Open,High,Low,Close,Volume,tradeSignalLong,tradeSignalShort,exitSignalLong,exitSignalShort\r\n");
   for(int i=0;i<ArraySize(lines);i++)
      FileWriteString(fh,lines[i]);
   FileClose(fh);

   // Mark recorded timestamps
   ArrayResize(recorded,barsToFill);
   for(int i=0;i<barsToFill;i++)
      recorded[i]=rates[i+1].time;  // +1 to skip current bar
      
   PrintFormat("[SignalExport] Backfilled %d bars up to %s", 
        barsToFill, TimeToString(recorded[barsToFill-1]));
}

//+------------------------------------------------------------------+
//| On every new tick: append latest bar at bottom                   |
//+------------------------------------------------------------------+
void ExportSignalsOnTick()
{
   datetime t=iTime(_Symbol,Period(),1);
   
   // Skip duplicate records
   for(int i=0;i<ArraySize(recorded);i++)
   {
      if(recorded[i]==t) 
      {
         // Uncomment for debugging: Print("Skipping duplicate: ",TimeToString(t));
         return;
      }
   }
   
   int tsL=0,tsS=0,exL=0,exS=0;
   signals_at(1,tsL,tsS,exL,exS);
   double o=iOpen(_Symbol,Period(),1);
   double h=iHigh(_Symbol,Period(),1);
   double l=iLow(_Symbol,Period(),1);
   double c=iClose(_Symbol,Period(),1);
   long v=iVolume(_Symbol,Period(),1);
   RecordSignalsWithValues(t,o,h,l,c,v,tsL,tsS,exL,exS);
}

//+------------------------------------------------------------------+
//| Utility: check existence                                        |
//+------------------------------------------------------------------+
bool FileExists(const string fn)
{
   int h=FileOpen(fn,FILE_READ|FILE_TXT);
   if(h<0) return false;
   FileClose(h);
   return true;
}