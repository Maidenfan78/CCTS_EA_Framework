//+------------------------------------------------------------------+
//|                                                 Log_Journals.mqh |
//|                                                      Cool Cherry |
//+------------------------------------------------------------------+
#property copyright "Cool Cherry"
#property strict

#ifndef __LOG_ERRORS_MQH__
#define __LOG_ERRORS_MQH__

#include "..\WinUser32.mqh"
#include "..\stderror.mqh"
#include "..\stdlib.mqh"
#include "CCTS_Config.mqh"
#include "CCTS_LogUtils.mqh"

//+------------------------------------------------------------------+
void ErrorLog(string functionName, string context, string one = "", string two = "", string three = "",
              string four = "", string five = "", string six = "", string seven = "", string eight = "", bool logToFile = true)
  {
   int code = GetLastError();  // Get the last error
   string errorDescription = ErrorDescription(code);

// Always log errors, even if code is 0
   string codeString = IntegerToString(code, 0);

   if(context == "")
      context = "No additional context";

// Get current time in "yyyy.mm.dd hh:mi:ss" format
   string currentTime = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
   string magNum      = magicNumberString;

// Define a common CSV header
   string commonHeader = "Date & Time,Magic Number,Function,Context,Ticket,Symbol,Index,Open Price,Close Price,Take Profit,Stop Loss,Lots,Order Type,File Name,Additional Info,Error Details";

// Initialize all fields with default values
   string ticket         = "n/a";
   string symbol         = "n/a";
   string index          = "n/a";
   string openPrice      = "n/a";
   string closePrice     = "n/a";
   string tp             = "n/a";
   string sl             = "n/a";
   string lots           = "n/a";
   string orderType      = "n/a";
   string file_Name      = "n/a";
   string additionalInfo = "n/a";


// Fill in the values based on the action type
   if(context == "Failed to select order")
     {
      index  = one;
      symbol = two;
     }
   else
      if(context == "Error adjusting stop loss")
        {
         ticket = one;
         symbol = two;
         index  = three;
         tp     = four;
         sl     = five;
         additionalInfo = six;
        }
      else
         if(context == "Error opening order")
           {
            ticket         = one;
            symbol         = two;
            openPrice      = three;
            tp             = four;
            sl             = five;
            lots           = six;
            orderType      = seven;
            additionalInfo = eight;
           }
         else
            if(context == "File error" || context == "Failed to open file")
              {
               symbol         = one;
               file_Name      = two;
               additionalInfo = three;
              }
            else
               if(context == "Invalid price" || context == "Failed to close order")
                 {
                  ticket         = one;
                  symbol         = two;
                  index          = three;
                  closePrice     = four;
                  orderType      = five;
                  additionalInfo = six;
                 }
               else
                  if(context == "Lot size error")
                    {
                     symbol         = one;
                     lots           = two;
                     additionalInfo = three;
                    }
                  else
                     if(context == "SL or TP too close to price")
                       {
                        symbol         = one;
                        lots           = two;
                        additionalInfo = three;
                       }
                     else
                        if(context == "Error")
                          {
                           symbol         = one;
                           additionalInfo = two;
                          }
                        else
                          {
                           additionalInfo = "N/A";
                          }

// Construct the log message
   string logMessage = currentTime + "," + magNum + "," + functionName + "," + context + "," +
                       ticket + "," + symbol  + "," + index + "," + openPrice + "," + closePrice + "," +
                       tp + "," + sl + "," + lots + "," + orderType + "," + file_Name + "," +
                       additionalInfo + "," + codeString + " " + errorDescription;

// Print the log message to the terminal
   Print(logMessage);

// Use a fixed file name for a single CSV log
   string logFileName = "Logs/Error-Log_" +  eaTitle + ".csv";

   if(logToFile)
     {
      EnsureLogsDirectory();
      bool fileExists = FileIsExist(logFileName); // Check if the file exists
      int handle = INVALID_HANDLE;
      int maxRetries = 5;
      for(int attempt = 0; attempt < maxRetries; attempt++)
        {
         handle = FileOpen(logFileName, FILE_WRITE | FILE_READ | FILE_CSV);
         if(handle != INVALID_HANDLE)
            break;
         Sleep(5000); // wait 1 second before next try
        }

      if(handle == INVALID_HANDLE)
        {
         Print("Error in CCTS_LogErrors.mqh. Unable to write to error log file after retrying");
         return;
        }


      // If the file is new, write the common header
      if(!fileExists)
        {
         FileWrite(handle, commonHeader);
        }

      // Move to the end of the file and append the log message
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle, logMessage);
      FileClose(handle);

      // Reset the error AFTER logging it
      ResetLastError();
     }
  }

#endif
//+------------------------------------------------------------------+
