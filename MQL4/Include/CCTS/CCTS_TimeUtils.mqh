//+------------------------------------------------------------------+
//|                                                ICT_TimeUtils.mqh |
//|                                                      Cool Cherry |
//|                                       https://www.CoolCherry.com |
//+------------------------------------------------------------------+
#property copyright   "Cool Cherry"
#property link        "https://www.CoolCherry.com"
#property strict

#ifndef __ICT_TIME_UTILS_MQH__
#define __ICT_TIME_UTILS_MQH__

//+------------------------------------------------------------------+
//| Return broker UTC offset in seconds (includes DST if applied)    |
//+------------------------------------------------------------------+
int  GetBrokerUTCOffsetSeconds()
{
   // TimeCurrent() is broker local, TimeGMT() is true UTC
   return(int)(TimeCurrent() - TimeGMT());
}

//+------------------------------------------------------------------+
//| Convert broker-local time to UTC                                 |
//+------------------------------------------------------------------+
datetime BrokerTimeToUTC(datetime brokerTime)
{
   return brokerTime - GetBrokerUTCOffsetSeconds();
}

//+------------------------------------------------------------------+
//| Convert UTC time to target timezone given offset in hours       |
//+------------------------------------------------------------------+
datetime UTCToTargetZone(datetime utcTime, double offsetHours)
{
   return utcTime + (int)(offsetHours * 3600);
}

//+------------------------------------------------------------------+
//| Normalize broker time directly into a target zone               |
//+------------------------------------------------------------------+
datetime NormalizeTime(datetime brokerTime, double targetOffsetHours)
{
   datetime utc = BrokerTimeToUTC(brokerTime);
   return UTCToTargetZone(utc, targetOffsetHours);
}

//+------------------------------------------------------------------+
//| Return the “hour” (0–23) in the target timezone                  |
//+------------------------------------------------------------------+
int GetNormalizedHour(double targetOffsetHours)
{
   datetime t = NormalizeTime(TimeCurrent(), targetOffsetHours);
   return TimeHour(t);
}

//+------------------------------------------------------------------+
//| Return the “day of week” (0=Sun…6=Sat) in the target timezone   |
//+------------------------------------------------------------------+
int GetNormalizedDayOfWeek(double targetOffsetHours)
{
   datetime t = NormalizeTime(TimeCurrent(), targetOffsetHours);
   return TimeDayOfWeek(t);
}

//+------------------------------------------------------------------+
//| Check if now in target zone falls within [startHour,endHour)    |
//+------------------------------------------------------------------+
bool IsWithinSession(int startHour, int endHour, double targetOffsetHours)
{
   int h = GetNormalizedHour(targetOffsetHours);
   return (h >= startHour && h < endHour);
}

#endif // __ICT_TIME_UTILS_MQH__
