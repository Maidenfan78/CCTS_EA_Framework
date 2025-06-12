@echo off
echo Compiling EA...
"E:\GO_MT4\metaeditor.exe" /compile:"E:\CCTS_EA_Framework\MQL4\Experts\CCTS_Breakout.mq4" >> compile_log.txt 2>&1

echo Done. Opening compile_log.txt...
notepad compile_log.txt
pause
