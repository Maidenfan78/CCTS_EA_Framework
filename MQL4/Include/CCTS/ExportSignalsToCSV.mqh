//+------------------------------------------------------------------+
//|                   ExportSignalsToCSV.mqh                         |
//|  Include this file in your EA to dump OHLC + trade/exit signals  |
//+------------------------------------------------------------------+
#property strict

#include <CCTS/EaSetup/Breakout_Signals.mqh>  // adjust path if needed

//--- User inputs for signal export
extern string SignalFilenamePrefix = "signals_labeled";  // Filename prefix: signals_labeled_<magic>.csv
extern int    BackfillBars         = 100;                // Number of historical bars to seed on init

//--- Internal globals
static datetime recorded[];   // track which timestamps have been written

//+------------------------------------------------------------------+
//| Build the full filename including magic number                   |
//+------------------------------------------------------------------+
string GetSignalFilename()
{
   return(StringFormat("%s_%s.csv", SignalFilenamePrefix, magicNumberString));
}

//+------------------------------------------------------------------+
//| Check if file exists                                             |
//+------------------------------------------------------------------+
bool FileExists(const string filename)
{
   int handle = FileOpen(filename, FILE_READ|FILE_TXT);
   if(handle < 0) return false;
   FileClose(handle);
   return true;
}

//+------------------------------------------------------------------+
//| Create/truncate file and write header                              |
//+------------------------------------------------------------------+
void InitSignalsFile()
{
   string filename = GetSignalFilename();
   int fh = FileOpen(filename, FILE_WRITE|FILE_ANSI);
   if(fh < 0)
   {
      PrintFormat("[SignalExport] Failed to create/truncate %s (Error %d)", filename, GetLastError());
      return;
   }
   FileWriteString(fh, "Time,Open,High,Low,Close,Volume,tradeSignalLong,tradeSignalShort,exitSignalLong,exitSignalShort\r\n");
   FileClose(fh);
   ArrayResize(recorded, 0);
}

//+------------------------------------------------------------------+
//| Record a specific bar by shift                                    |
//+------------------------------------------------------------------+
void RecordSignalsForShift(int shift)
{
   int tf = Period();
   datetime t = iTime(_Symbol, tf, shift);
   if(t <= 0) return;

   // skip duplicates
   for(int i=0; i<ArraySize(recorded); i++)
      if(recorded[i] == t)
         return;

   string filename = GetSignalFilename();
   int fh = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_ANSI);
   if(fh < 0)
   {
      PrintFormat("[SignalExport] Failed to open %s (Error %d)", filename, GetLastError());
      return;
   }
   FileSeek(fh, 0, SEEK_END);

   double o = iOpen(_Symbol, tf, shift);
   double h = iHigh(_Symbol, tf, shift);
   double l = iLow(_Symbol, tf, shift);
   double c = iClose(_Symbol, tf, shift);
   long   v = iVolume(_Symbol, tf, shift);
   int tsLong=0, tsShort=0, exLong=0, exShort=0;
   signals(tsLong, tsShort, exLong, exShort);

   string line = StringFormat(
      "%s,%g,%g,%g,%g,%d,%d,%d,%d,%d\r\n",
      TimeToString(t, TIME_DATE|TIME_MINUTES), o, h, l, c, v, tsLong, tsShort, exLong, exShort
   );
   FileWriteString(fh, line);
   FileClose(fh);

   // mark as recorded
   ArrayResize(recorded, ArraySize(recorded)+1);
   recorded[ArraySize(recorded)-1] = t;
}

//+------------------------------------------------------------------+
//| Initialize and backfill on EA start                               |
//+------------------------------------------------------------------+
void StartSignalExport()
{
   string filename = GetSignalFilename();
   if(!FileExists(filename))
      InitSignalsFile();

   // backfill historical bars
   for(int i=BackfillBars; i>=1; i--)
      RecordSignalsForShift(i);
}

//+------------------------------------------------------------------+
//| Append last closed bar on new bar                                 |
//+------------------------------------------------------------------+
void ExportSignalsOnTick()
{
   RecordSignalsForShift(1);
}

//+------------------------------------------------------------------+
//| Cleanup (none)                                                   |
//+------------------------------------------------------------------+
void StopSignalExport()
{
   // nothing to close
}
