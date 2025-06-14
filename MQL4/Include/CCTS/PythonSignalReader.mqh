//+------------------------------------------------------------------+
//|                                           PythonSignalReader.mqh |
//|                            Utility to read ML-generated signals |
//+------------------------------------------------------------------+
#property strict

#ifndef __PYTHON_SIGNAL_READER_MQH__
#define __PYTHON_SIGNAL_READER_MQH__

void ReadPythonSignals(
   const string &fileName,
   int &tradeSignalLong,
   int &tradeSignalShort,
   int &exitSignalLong,
   int &exitSignalShort)
  {
   tradeSignalLong  = 0;
   tradeSignalShort = 0;
   exitSignalLong   = 0;
   exitSignalShort  = 0;

   int handle = FileOpen(fileName, FILE_READ | FILE_TXT);
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
