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

// config
input string _100 = "==== Quantum with filter by MACD ====";
input int quantumPeriod = 8;
input int macdFastEmaPeriod = 5;
input int macdSlowEmaPeriod = 14;
input int macdSignalPeriod = 6;
input ENUM_APPLIED_PRICE macdAppliedPrice = PRICE_TYPICAL;

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
   switch(operation)
     {
      case OP_BUY:
         return CustomIndicator(0, 0) > 0;
      case OP_SELL:
         return CustomIndicator(1, 0) > 0;
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CustomIndicator(int buffer, int shift)
  {
   return iCustom(Symbol(), Period(), "QuantumWithFilter_IND", "", quantumPeriod, "", macdFastEmaPeriod, macdSlowEmaPeriod, macdSignalPeriod, buffer, shift);
  }
//+------------------------------------------------------------------+
