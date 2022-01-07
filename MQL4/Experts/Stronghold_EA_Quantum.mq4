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
class QuantumSignalStrategy : public Strategy
  {
public:
   virtual bool      CanOpenFirstOrder(int operation);
  };

// config
// ...

// runtime
Strategy *st;
TradeManager *tm;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   st = new QuantumSignalStrategy();
   tm = new TradeManager(Symbol(), Period(), IsTesting(), st);

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
bool QuantumSignalStrategy::CanOpenFirstOrder(int operation)
  {
   switch(operation)
     {
      case OP_BUY:
         return iCustom(Symbol(), 0, "QuantumShaolin_IND", 0, 0) > 0;
      case OP_SELL:
         return iCustom(Symbol(), 0, "QuantumShaolin_IND", 1, 0) > 0;
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }
  }
//+------------------------------------------------------------------+
