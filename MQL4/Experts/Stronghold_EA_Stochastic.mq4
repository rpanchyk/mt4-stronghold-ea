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
input string _100 = "==== Определение первого ордера сетки по стохе ====";
input ENUM_TIMEFRAMES stochTimeframe = PERIOD_M1; // Таймфрейм
input int stochKperiod = 11; // K-период
input int stochDperiod = 16; // D-период
input int stochSlowing = 13; // Замедление
input ENUM_MA_METHOD stochMaMethod = MODE_SMA; // Метод MA
input ENUM_STO_PRICE stochPrice = STO_LOWHIGH; // Цена
input double stochUpLevel = 95.0; // Верхний уровень
input double stochDownLevel = 5.0; // Нижний уровень

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
         return iStochastic(Symbol(), stochTimeframe, stochKperiod, stochDperiod, stochSlowing, stochMaMethod, 0, 0, 2) <= stochDownLevel
                && iStochastic(Symbol(), stochTimeframe, stochKperiod, stochDperiod, stochSlowing, stochMaMethod, 0, 0, 1) > stochDownLevel;
      case OP_SELL:
         return iStochastic(Symbol(), stochTimeframe, stochKperiod, stochDperiod, stochSlowing, stochMaMethod, 0, 0, 2) >= stochUpLevel
                && iStochastic(Symbol(), stochTimeframe, stochKperiod, stochDperiod, stochSlowing, stochMaMethod, 0, 0, 1) < stochUpLevel;
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }
  }
//+------------------------------------------------------------------+
