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

// runtime
Strategy *st;
TradeManager *tm;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
  {
   st = new Strategy();
   tm = new TradeManager(Symbol(), Period(), st);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete tm;
   delete st;
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
   Print(__FUNCTION__, ": ", "Stub strategy is executed");
   return false;
  }
//+------------------------------------------------------------------+
