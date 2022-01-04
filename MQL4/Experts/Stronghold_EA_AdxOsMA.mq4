//+------------------------------------------------------------------+
//|                                                Stronghold_EA.mq4 |
//|                                   Expert Adviser for MetaTrader4 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, FireTrot"
#property link        "https://firetrot.com"
#property description "EA for automatic algorithmic trading"
#property strict

#include <Stronghold_LIB_TM.mqh>
#include <Stronghold_LIB_ST.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class AdxOsMAStrategy : public Strategy
  {
public:
   virtual bool      CanOpenFirstOrder(int operation);
  };
extern string _100 = "==== Определение первого ордера сетки по ADX ====";
extern int adxPeriod = 14; // ADX - Period
extern ENUM_APPLIED_PRICE adxAppliedPrice = PRICE_CLOSE; // ADX - Applied price
extern int osmaFastEmaPeriod = 12; // OsMA - Fast EMA period
extern int osmaSlowEmaPeriod = 26; // OsMA - Slow EMA period
extern int osmaMacdSmaPeriod = 9; // OsMA - MACD SMA period
extern ENUM_APPLIED_PRICE osmaAppliedPrice = PRICE_CLOSE; // Applied price

// runtime
Strategy *st;
TradeManager *tm;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   st = new AdxOsMAStrategy();
   tm = new TradeManager(Symbol(), IsTesting(), st);

   EventSetTimer(tm.GetRefreshStatsPeriod());
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();

   tm.OnDeinitExecution(reason);

   delete st;
   delete tm;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   tm.OnTimerExecution();
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
bool AdxOsMAStrategy::CanOpenFirstOrder(int operation)
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
