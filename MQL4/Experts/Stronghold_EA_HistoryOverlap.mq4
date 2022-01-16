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
input string _100 = "==== Custom indicator parameters ====";
input int InpHistoryLimit = 10000;
input int InpPeriod = 1000;
input int InpEstimatedBarApplyTo = 1;
input int InpHistoricalBarApplyTo = 1;
input int InpThreshold = 50;

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
         return CustomIndicator(1, 1) <= -InpThreshold && CustomIndicator(1, 2) <= -InpThreshold;
        }
      case OP_SELL:
        {
         return CustomIndicator(0, 1) >= InpThreshold && CustomIndicator(0, 2) >= InpThreshold;
        }
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
   return iCustom(Symbol(), Period(), "HistoryOverlap", InpHistoryLimit, InpPeriod, InpEstimatedBarApplyTo, InpHistoricalBarApplyTo, buffer, shift);
  }
//+------------------------------------------------------------------+
