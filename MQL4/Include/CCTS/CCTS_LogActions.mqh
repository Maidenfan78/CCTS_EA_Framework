//+------------------------------------------------------------------+
//|                                              CCTS_LogActions.mqh |
//|                                                      Cool Cherry |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property strict

#ifndef __LOG_ACTIONS_MQH__
#define __LOG_ACTIONS_MQH__

#include "..\stdlib.mqh"
#include "..\CCTS\CCTS_LogErrors.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LogAction(string actionType, string context, string one = "", string two = "", string three = "", string four = "", string five = "", string six = "", string seven = "", string eight = "", bool logToFile = true)
  {
// Get current time in "yyyy.mm.dd hh:mi:ss" format
   string currentTime = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
   string magNum      = magicNumberString;

// Define a common CSV header that includes all possible fields
   string commonHeader = "DateTime,Magic Number,Action,Context,Ticket,Symbol,Open Price,Close Price,Take Profit,Stop Loss,Lots,Order Type,Profit$,Additional Info";

// Declare all fields and set defaults (empty strings)
   string ticket         = "n/a";
   string symbol         = "n/a";
   string openPrice      = "n/a";
   string closePrice     = "n/a";
   string tp             = "n/a";
   string sl             = "n/a";
   string lots           = "n/a";
   string orderType      = "n/a";
   string profit         = "n/a";
   string additionalInfo = "n/a";

// Populate fields based on actionType
   if(actionType == "Trade Opened")
     {
      ticket    = one;
      symbol    = two;
      openPrice = three;
      tp        = four;
      sl        = five;
      lots      = six;
      orderType = seven;
     }
   else
      if(actionType == "Trade Closed" || actionType == "Stop loss hit" || actionType == "Take profit hit")
        {
         ticket     = one;
         symbol     = two;
         closePrice = three;
         profit     = four;
        }
      else
         if(actionType == "Stop loss adjusted")
           {
            ticket     = one;
            symbol     = two;
            tp         = three;
            sl         = four;
           }
         else
            if(actionType == "95% hit")
              {
               ticket         = one;
               symbol         = two;
               additionalInfo = three +" Close price";
              }
            else
              {
               additionalInfo = "N/A";
              }

// Construct the log message in the order of the common header fields
   string logMessage = currentTime + "," + magNum + "," + actionType + "," + context + "," +
                        ticket + "," + symbol + "," + openPrice + "," + closePrice + "," + tp + "," + sl + "," +
                        lots + "," + orderType + "," + profit + "," + additionalInfo;

// Print the log message to the terminal
   Print(logMessage);

// Use a fixed file name for a single CSV log file
   string logFileName = "Logs/ActionLog_" +  eaTitle + ".csv";

   if(logToFile)
     {
      bool fileExists = FileIsExist(logFileName); // Check if the file already exists
      int handle = FileOpen(logFileName, FILE_WRITE | FILE_READ | FILE_CSV);

      if(handle == INVALID_HANDLE)
        {
         ErrorLog(__FUNCTION__, "File error", currentSymbol, logFileName, "Unable to write to trade log file");
         return;
        }

      // If the file is new, write the common header
      if(!fileExists)
        {
         FileWrite(handle, commonHeader);
        }

      // Append the log message
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle, logMessage);
      FileClose(handle);
     }
  }

#endif 
