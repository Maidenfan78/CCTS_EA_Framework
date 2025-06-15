//+------------------------------------------------------------------+
//|                   ExportSignalsToCSV.mqh                         |
//|  Include this file in your EA to dump OHLC + trade/exit signals  |
//+------------------------------------------------------------------+
#property strict

#include "..\CCTS\EaSetup\Breakout_Signals.mqh"

//--- User inputs for signal export
extern string SignalFilenamePrefix = "signals_labeled";  // Filename prefix: signals_labeled_<magic>.csv
extern int    BackfillBars         = 1460;                // Number of historical bars to seed on init

//--- Internal globals
static datetime recorded[];   // track which timestamps have been written
//--- Buffer for CopyRates
MqlRates        rates[];

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
   if(handle < 0)
      return false;
   FileClose(handle);
   return true;
  }

//+------------------------------------------------------------------+
//| Create/truncate file and write header                            |
//+------------------------------------------------------------------+
void InitSignalsFile()
  {
   string filename = GetSignalFilename();
   int fh = FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_ANSI);
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
//| RecordSignalsWithValues: write one row of pre-fetched data       |
//+------------------------------------------------------------------+
void RecordSignalsWithValues(
   datetime t,
   double    o,
   double    h,
   double    l,
   double    c,
   long      v,
   int       tsLong,
   int       tsShort,
   int       exLong,
   int       exShort)
  {
   string filename = GetSignalFilename();
   int fh = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_ANSI);
   if(fh < 0)
     {
      PrintFormat("[SignalExport] Failed to open %s (Error %d)", filename, GetLastError());
      return;
     }
   FileSeek(fh, 0, SEEK_END);
   string line = StringFormat(
                    "%s,%g,%g,%g,%g,%d,%d,%d,%d,%d\r\n",
                    TimeToString(t, TIME_DATE|TIME_MINUTES),
                    o, h, l, c, v,
                    tsLong, tsShort, exLong, exShort
                 );
   FileWriteString(fh, line);
   FileClose(fh);

// mark as recorded
   ArrayResize(recorded, ArraySize(recorded)+1);
   recorded[ArraySize(recorded)-1] = t;
  }

//+------------------------------------------------------------------+
//| Initialize and backfill on EA start using CopyRates             |
//+------------------------------------------------------------------+
void StartSignalExport()
  {
   string filename = GetSignalFilename();
   if(!FileExists(filename))
      InitSignalsFile();

// How many we really want
   int want = BackfillBars + 12;
   int total = 0;
   int attempts = 0;

// Try up to 10 times (5 s total) for MT4 to fill its history cache
   while(attempts < 10)
     {
      total = CopyRates(_Symbol, Period(), 0, want, rates);
      if(total >= want || total > 2)
         break;       // got something
      Sleep(500);    // wait half a second
      attempts++;
     }

   if(total < 2)
     {
      Print("[SignalExport] Not enough data even after waiting, got ", total);
      return;
     }

   int barsToBackfill = MathMin(BackfillBars, total - 1);
   for(int i = barsToBackfill; i >= 1; i--)
     {
      MqlRates r = rates[i];
      int tsL, tsS, exL, exS;
      signals_at(i, tsL, tsS, exL, exS);
      RecordSignalsWithValues(r.time, r.open, r.high, r.low, r.close, r.tick_volume,
                              tsL,tsS,exL,exS);
     }
  }


//+------------------------------------------------------------------+
//| Append last closed bar on new bar                                |
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

//+------------------------------------------------------------------+
//| Record a specific bar by shift (legacy support)                  |
//+------------------------------------------------------------------+
void RecordSignalsForShift(int shift)
  {
// fallback to chart buffer for on-tick export
   datetime t = iTime(_Symbol, Period(), shift);
   if(t <= 0)
      return;
   for(int i=0; i<ArraySize(recorded); i++)
      if(recorded[i]==t)
         return;

   double o = iOpen(_Symbol, Period(), shift);
   double h = iHigh(_Symbol, Period(), shift);
   double l = iLow(_Symbol, Period(), shift);
   double c = iClose(_Symbol, Period(), shift);
   long   v = iVolume(_Symbol, Period(), shift);
   int tsLong=0, tsShort=0, exLong=0, exShort=0;
   signals_at(shift, tsLong, tsShort, exLong, exShort);

   RecordSignalsWithValues(t, o, h, l, c, v, tsLong, tsShort, exLong, exShort);
  }
//+------------------------------------------------------------------+
