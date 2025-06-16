#ifndef __CCTS_LOG_UTILS_MQH__
#define __CCTS_LOG_UTILS_MQH__

void EnsureLogsDirectory()
  {
   string folder = "Logs";
   if(!FileIsExist(folder))
     {
      if(!FolderCreate(folder))
         Print("Failed to create logs directory: ", folder);
     }
  }

#endif // __CCTS_LOG_UTILS_MQH__
