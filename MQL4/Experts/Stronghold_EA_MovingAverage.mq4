//+------------------------------------------------------------------+
//|                                                Stronghold_EA.mq4 |
//|                                   Expert Adviser for MetaTrader4 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, rpanchyk"
#property link        "https://github.com/rpanchyk/mt4-stronghold-ea"
#property description "EA for automatic algorithmic trading"
#property strict

#include <Stronghold_LIB_TM.mqh>
#include <Stronghold_LIB_ST.mqh>

// config
input string _100 = "==== Определение первого ордера сетки по скользяшке ====";
input ENUM_TIMEFRAMES maTimeframe = PERIOD_M1; // Таймфрейм
input int maPeriod = 56; // Период
input int maShift = 0; // Сдвиг
input ENUM_MA_METHOD maMethod = MODE_SMA; // Метод
input ENUM_APPLIED_PRICE maAppliedPrice = PRICE_MEDIAN; // Применяемая цена
input int maBackToHistory = 10; // Назад в историю для определения тренда

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
   if(tm.TotalOrdersCount() > 0) // only one grid is allowed
     {
      return false;
     }

   double prevPrice = iMA(Symbol(), maTimeframe, maPeriod, maShift, maMethod, maAppliedPrice, maBackToHistory);
   if(prevPrice == 0)
     {
      Print(__FUNCTION__, ": ", "Error obtaining prev price: ", GetLastError());
      return false;
     }

   double currPrice = iMA(Symbol(), maTimeframe, maPeriod, maShift, maMethod, maAppliedPrice, 0);
   if(currPrice == 0)
     {
      Print(__FUNCTION__, ": ", "Error obtaining curr price: ", GetLastError());
      return false;
     }

   switch(operation)
     {
      case OP_BUY:
         return currPrice > prevPrice;
      case OP_SELL:
         return currPrice < prevPrice;
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }
  }
//+------------------------------------------------------------------+
