//+------------------------------------------------------------------+
//|                                                Stronghold_EA.mq4 |
//|                                   Expert Adviser for MetaTrader4 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, rpanchyk"
#property link        "https://github.com/rpanchyk/fx-stronghold-ea"
#property description "EA for automatic algorithmic trading"
#property strict

#include <Stronghold_LIB_TM.mqh>
#include <Stronghold_LIB_ST.mqh>

// config
input string _100 = "==== Определение первого ордера сетки по ADX ====";
input int adxPeriod = 14; // ADX - Period
input ENUM_APPLIED_PRICE adxAppliedPrice = PRICE_CLOSE; // ADX - Applied price
input int osmaFastEmaPeriod = 12; // OsMA - Fast EMA period
input int osmaSlowEmaPeriod = 26; // OsMA - Slow EMA period
input int osmaMacdSmaPeriod = 9; // OsMA - MACD SMA period
input ENUM_APPLIED_PRICE osmaAppliedPrice = PRICE_CLOSE; // Applied price

// runtime
TradeManager *tm;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
  {
   tm = new TradeManager(Symbol(), Period());
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete tm;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   tm.OnTickExecution();
   Comment(tm.GetStats());
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Strategy::CanOpenFirstOrder(int operation)
  {
   switch(operation)
     {
      case OP_BUY:
        {
         double i1 = iCustom(Symbol(), 0, "AdxCrossingOsMA_INGM", "", 10, "", adxPeriod, adxAppliedPrice, "", osmaFastEmaPeriod, osmaSlowEmaPeriod, osmaMacdSmaPeriod, osmaAppliedPrice, "", 0, 0, 0, 0, 0, 1);
         if(i1 > 0)
           {
            Print(" =================== buy ", i1);
           }
         return i1 > 0;
        }
      case OP_SELL:
        {

         double i2 = iCustom(Symbol(), 0, "AdxCrossingOsMA_INGM", "", 10, "", adxPeriod, adxAppliedPrice, "", osmaFastEmaPeriod, osmaSlowEmaPeriod, osmaMacdSmaPeriod, osmaAppliedPrice, "", 0, 0, 0, 0, 1, 1);
         if(i2 > 0)
           {
            Print(" =================== sell ", i2);
           }
         return i2 > 0;
        }
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }
  }
//+------------------------------------------------------------------+
