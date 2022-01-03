@echo off
setlocal

@REM The script copies EA from MT4

@REM Read properties in format:
@REM BASE_PATH=C:\Users\[USER]\AppData\Roaming\MetaQuotes\Terminal\[TERMINAL_ID]
@REM To see the path go to main menu "File -> Open Data Path" in MT4.
for /f "delims== tokens=1,2" %%G in (copy_options.txt) do set %%G=%%H

@REM Settings
set INCLUDE_DIR=MQL4\Include
set EXPERTS_DIR=MQL4\Experts
set INDICATORS_DIR=MQL4\Indicators

@REM Create local dirs if absent
if not exist "%INCLUDE_DIR%" mkdir "%INCLUDE_DIR%"
if not exist "%EXPERTS_DIR%" mkdir "%EXPERTS_DIR%"
if not exist "%INDICATORS_DIR%" mkdir "%INDICATORS_DIR%"

@REM Copy files to local repository
if exist "%BASE_PATH%\%INCLUDE_DIR%\Stronghold_LIB.mqh" copy /Y "%BASE_PATH%\%INCLUDE_DIR%\Stronghold_LIB.mqh" "%INCLUDE_DIR%"
if exist "%BASE_PATH%\%EXPERTS_DIR%\Stronghold_EA.mq4" copy /Y "%BASE_PATH%\%EXPERTS_DIR%\Stronghold_EA.mq4" "%EXPERTS_DIR%"
if exist "%BASE_PATH%\%INDICATORS_DIR%\AdxCrossing_INGM.mq4" copy /Y "%BASE_PATH%\%INDICATORS_DIR%\AdxCrossing_INGM.mq4" "%INDICATORS_DIR%"
if exist "%BASE_PATH%\%INDICATORS_DIR%\AdxCrossingOsMA_INGM.mq4" copy /Y "%BASE_PATH%\%INDICATORS_DIR%\AdxCrossingOsMA_INGM.mq4" "%INDICATORS_DIR%"
if exist "%BASE_PATH%\%INDICATORS_DIR%\LevelBreaker_IND.mq4" copy /Y "%BASE_PATH%\%INDICATORS_DIR%\LevelBreaker_IND.mq4" "%INDICATORS_DIR%"

echo Successfully copied.
pause
