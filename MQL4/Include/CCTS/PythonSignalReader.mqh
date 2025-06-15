//+------------------------------------------------------------------+
//|                                           PythonSignalReader.mqh |
//|                            Utility to read ML-generated signals  |
//+------------------------------------------------------------------+
#property strict

#ifndef __PYTHON_SIGNAL_READER_MQH__
#define __PYTHON_SIGNAL_READER_MQH__

#include "..\CCTS\CCTS_Config.mqh"

// Build the per-instance filename: python_signals_<magic>.csv
string GetPythonSignalsFilename()
{
   // magicNumberString provided by EA globals
   return(StringFormat("python_signals_%s.csv", magicNumberString));
}

void ReadPythonSignals(
   int &tradeSignalLong,
   int &tradeSignalShort,
   int &exitSignalLong,
   int &exitSignalShort)
{
   tradeSignalLong  = 0;
   tradeSignalShort = 0;
   exitSignalLong   = 0;
   exitSignalShort  = 0;

   string fname = GetPythonSignalsFilename();
   int handle = FileOpen(fname, FILE_READ | FILE_TXT);
   if(handle == INVALID_HANDLE)
      return;

   string line = FileReadString(handle);
   FileClose(handle);

   string parts[];
   int count = StringSplit(line, ',', parts);
   if(count >= 4)
   {
      tradeSignalLong  = (int)StringToInteger(parts[0]);
      tradeSignalShort = (int)StringToInteger(parts[1]);
      exitSignalLong   = (int)StringToInteger(parts[2]);
      exitSignalShort  = (int)StringToInteger(parts[3]);
   }
}

#endif
//+------------------------------------------------------------------+
