@echo off
rem Allow overriding metaeditor_path from the environment
if not defined metaeditor_path (
    set "metaeditor_path=E:\MT4_4.1_STD_1\metaeditor.exe"
)

rem Use an absolute path to the EA source based on this script's location
set "mq4_file=%~dp0MQL4\Experts\CCTS_Breakout.mq4"
set "log_file=%~dp0compile_log.txt"

echo Compiling "%mq4_file%" ...
"%metaeditor_path%" /compile:"%mq4_file%" > "%log_file%" 2>&1

echo Done. See compile_log.txt for details.
pause
