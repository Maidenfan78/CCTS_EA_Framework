//+------------------------------------------------------------------+
//|                                     CCTS_PersistentVariables.mqh |
//+------------------------------------------------------------------+
#property strict

#ifndef __PERS_VARIABLES_MQH__
#define __PERS_VARIABLES_MQH__

#include "..\stdlib.mqh"
#include "..\CCTS\CCTS_Config.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string StringTrim(const string &str)
  {

   int start  = 0;
   int end    = StringLen(str) - 1;

// Find the first non-whitespace character
   while(start <= end && StringGetChar(str, start) <= ' ')
     {
      start++;
     }

// Find the last non-whitespace character
   while(end >= start && StringGetChar(str, end) <= ' ')
     {
      end--;
     }

// Extract the trimmed string
   return StringSubstr(str, start, end - start + 1);
  }

// Create the file if missing and initialize default values
void CreateFileIfMissing(string MagicNumberString, string &PersistentVariableFileName)
  {
   PersistentVariableFileName = "Persitent_" + eaTitle + "_" + currentSymbol + ".csv";
   int fileHandle = FileOpen(PersistentVariableFileName, FILE_READ | FILE_TXT);

   if(fileHandle == INVALID_HANDLE)
     {
      // File doesn't exist, so create it with headers and default data
      fileHandle = FileOpen(PersistentVariableFileName, FILE_WRITE | FILE_TXT);
      if(fileHandle != INVALID_HANDLE)
        {
         FileWrite(fileHandle, "Hit95Target,ContinuationEnabled,LastTradeOrderType,LastTradeBaselineTrend,LastTradeEx2Exit,MovedToBE,TrailingStopAdjusted,oldAtrValue,orderOpenPrice,Hit95Logged,stopLossHit,baseLineFlipped");
         FileWrite(fileHandle, "0,0,Waiting for signal,Waiting for signal,Waiting for signal,0,0,", NormalizeDouble(ATRValue, digits), ",", + NormalizeDouble(OrderOpenPrice(),digits), ", Waiting for signal, Waiting for signal, Waiting for signal");
         Print("File created and initialized: ", PersistentVariableFileName);
         FileClose(fileHandle);
        }
      else
        {
         ErrorLog(__FUNCTION__, "File error", currentSymbol, fileName, "Error creating file");
        }
     }
   else
     {
      Print("File exists: ", PersistentVariableFileName);
      FileClose(fileHandle);
     }
  }

// Write the struct data to the file
void WriteToFile(const string &PersistentVariableFileName, const PersistentVariables &Variables)
  {
   int fileHandle = FileOpen(PersistentVariableFileName, FILE_WRITE | FILE_TXT);

   if(fileHandle == INVALID_HANDLE)
     {
      ErrorLog(__FUNCTION__, "Failed to open file", currentSymbol, fileName, "Write error");

      return;
     }

// Write headers if the file is empty
   if(FileSize(fileHandle) == 0)
     {
      if(!FileWrite(fileHandle, "Hit95Target,ContinuationEnabled,LastTradeOrderType,LastTradeBaselineTrend,LastTradeEx2Exit,MovedToBE,TrailingStopAdjusted,oldAtrValue,orderOpenPrice,Hit95Logged,stopLossHit,baseLineFlipped"))
        {
         //ErrorLog("Failed to write headers to file: " + PersistentVariableFileName + ". Error: " + IntegerToString(GetLastError()));
         ErrorLog(__FUNCTION__, "File error", currentSymbol, fileName, "Failed to write headers to file");
         FileClose(fileHandle);
         return;
        }
     }

   string lineToWrite = IntegerToString(Variables.Hit95Target ? 1 : 0) + "," +
                        IntegerToString(Variables.ContinuationEnabled ? 1 : 0) + "," +
                        Variables.LastTradeOrderType + "," +
                        Variables.LastTradeBaselineTrend + "," +
                        Variables.LastTradeEx2Exit + "," +
                        IntegerToString(Variables.MovedToBE ? 1 : 0) + "," +
                        IntegerToString(Variables.TrailingStopAdjusted ? 1 : 0) + "," +
                        DoubleToString(Variables.oldAtrValue,digits) + "," +
                        DoubleToString(Variables.orderOpenPrice,digits) + "," +
                        IntegerToString(Variables.Hit95Logged ? 1 : 0) + "," +
                        IntegerToString(Variables.stopLossHit ? 1 : 0) + "," +
                        IntegerToString(Variables.baseLineFlipped ? 1 : 0);

   if(!FileWrite(fileHandle, lineToWrite))
     {
      //ErrorLog("Failed to write data to file: " + PersistentVariableFileName + ". Line: " + lineToWrite + ". Error: " + IntegerToString(GetLastError()));
      ErrorLog(__FUNCTION__, "File error", currentSymbol, fileName, "Error to be defined");
      FileClose(fileHandle);
      return;
     }

   FileClose(fileHandle);
  }

// Read the struct data from the file
void ReadFromFile(const string &PersistentVariableFileName, PersistentVariables &Variables)
  {
   int fileHandle = FileOpen(PersistentVariableFileName, FILE_READ | FILE_TXT);

   if(fileHandle == INVALID_HANDLE)
     {
      ErrorLog(__FUNCTION__, "Failed to open file", currentSymbol, fileName, "Read error");
      return;
     }

   FileReadString(fileHandle); // Skip header line
   string readLine = FileReadString(fileHandle); // Read the data line
   FileClose(fileHandle);

// Trim and validate
   readLine = StringTrim(readLine);
   if(StringLen(readLine) == 0)
     {
      ErrorLog(__FUNCTION__, "File error", currentSymbol, fileName, "Read line is empty. Using default values.");
      return;
     }

   string parts[];
   int partsCount = StringSplit(readLine, ',', parts);

   if(partsCount < 12)
     {
      ErrorLog(__FUNCTION__, "File error", currentSymbol, fileName, "Insufficient data in file. Expected 12 parts.");
      return;
     }

// Parse the parts into the struct
   Variables.Hit95Target            = StringToInteger(parts[0]) != 0;
   Variables.ContinuationEnabled    = StringToInteger(parts[1]) != 0;
   Variables.LastTradeOrderType     = parts[2];
   Variables.LastTradeBaselineTrend = parts[3];
   Variables.LastTradeEx2Exit       = parts[4];
   Variables.MovedToBE              = StringToInteger(parts[5]) != 0;
   Variables.TrailingStopAdjusted   = StringToInteger(parts[6]) != 0;
   Variables.oldAtrValue            = StringToDouble(parts[7]);
   Variables.orderOpenPrice         = StringToDouble(parts[8]);
   Variables.Hit95Logged            = StringToInteger(parts[9]) != 0;
   Variables.stopLossHit            = StringToInteger(parts[10]) != 0;
   Variables.baseLineFlipped        = StringToInteger(parts[11]) != 0;
  }


#endif
//+------------------------------------------------------------------+
