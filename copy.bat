@echo off
setlocal

@REM The script copies EA from MT4

@REM Read options file having format:
@REM DATA_DIR=C:\Users\[USER]\AppData\Roaming\MetaQuotes\Terminal\[TERMINAL_ID]
@REM To see the actual path go to main menu "File -> Open Data Folder" in MT4.
set OPTIONS_FILE=copy_options.txt
if not exist %OPTIONS_FILE% echo Error: %OPTIONS_FILE% file not found && pause && exit 1
for /f "delims== tokens=1,2" %%G in (%OPTIONS_FILE%) do set %%G=%%H

@REM Settings
set INCLUDE_DIR=MQL4\Include
set EXPERTS_DIR=MQL4\Experts
set INDICATORS_DIR=MQL4\Indicators

@REM Create local dirs if absent
if not exist "%INCLUDE_DIR%" mkdir "%INCLUDE_DIR%"
if not exist "%EXPERTS_DIR%" mkdir "%EXPERTS_DIR%"
if not exist "%INDICATORS_DIR%" mkdir "%INDICATORS_DIR%"

@REM Copy files to local repository
if exist "%DATA_DIR%\%INCLUDE_DIR%\Stronghold_LIB_GM.mqh" copy /Y "%DATA_DIR%\%INCLUDE_DIR%\Stronghold_LIB_GM.mqh" "%INCLUDE_DIR%"
if exist "%DATA_DIR%\%INCLUDE_DIR%\Stronghold_LIB_ST.mqh" copy /Y "%DATA_DIR%\%INCLUDE_DIR%\Stronghold_LIB_ST.mqh" "%INCLUDE_DIR%"
if exist "%DATA_DIR%\%INCLUDE_DIR%\Stronghold_LIB_TM.mqh" copy /Y "%DATA_DIR%\%INCLUDE_DIR%\Stronghold_LIB_TM.mqh" "%INCLUDE_DIR%"

if exist "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA.mq4" copy /Y "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA.mq4" "%EXPERTS_DIR%"
if exist "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_AdxOsMA.mq4" copy /Y "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_AdxOsMA.mq4" "%EXPERTS_DIR%"
if exist "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_LevelBreaker.mq4" copy /Y "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_LevelBreaker.mq4" "%EXPERTS_DIR%"
if exist "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_MovingAverage.mq4" copy /Y "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_MovingAverage.mq4" "%EXPERTS_DIR%"
if exist "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_Quantum.mq4" copy /Y "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_Quantum.mq4" "%EXPERTS_DIR%"
if exist "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_StandardDeviation.mq4" copy /Y "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_StandardDeviation.mq4" "%EXPERTS_DIR%"
if exist "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_Stochastic.mq4" copy /Y "%DATA_DIR%\%EXPERTS_DIR%\Stronghold_EA_Stochastic.mq4" "%EXPERTS_DIR%"

if exist "%DATA_DIR%\%INDICATORS_DIR%\AdxCrossing_INGM.mq4" copy /Y "%DATA_DIR%\%INDICATORS_DIR%\AdxCrossing_INGM.mq4" "%INDICATORS_DIR%"
if exist "%DATA_DIR%\%INDICATORS_DIR%\AdxCrossingOsMA_INGM.mq4" copy /Y "%DATA_DIR%\%INDICATORS_DIR%\AdxCrossingOsMA_INGM.mq4" "%INDICATORS_DIR%"
if exist "%DATA_DIR%\%INDICATORS_DIR%\LevelBreaker_IND.mq4" copy /Y "%DATA_DIR%\%INDICATORS_DIR%\LevelBreaker_IND.mq4" "%INDICATORS_DIR%"
if exist "%DATA_DIR%\%INDICATORS_DIR%\Quantum_IND.mq4" copy /Y "%DATA_DIR%\%INDICATORS_DIR%\Quantum_IND.mq4" "%INDICATORS_DIR%"

echo Successfully copied.
timeout /t 5
