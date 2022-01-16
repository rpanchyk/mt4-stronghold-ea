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
input string _100 = "==== Определение первого ордера сетки по стандартному отклонению ====";
input ENUM_TIMEFRAMES sdTimeframe = PERIOD_M1; // Таймфрейм
input int sdMaPeriod = 20; // Период
input int sdMaShift = 0; // Сдвиг
input ENUM_MA_METHOD sdMaMethod = MODE_SMA; // Метод MA
input ENUM_APPLIED_PRICE sdAppliedPrice = PRICE_CLOSE; // Применяемая цена
input int sdBackToHistory = 10; // Назад в историю для определения тренда
input double sdLevel = 0.001; // Уровень для открытия ордера
input int sdBackPeriod = 6; // Исторический период
input double sdBackDiffCoef = 0.0006; // Историческая разница коеф.
input int osmaFastEmaPeriod = 12; // OsMA - Fast EMA period
input int osmaSlowEmaPeriod = 26; // OsMA - Slow EMA period
input int osmaMacdSmaPeriod = 9; // OsMA - MACD SMA period
input ENUM_APPLIED_PRICE osmaAppliedPrice = PRICE_CLOSE; // Applied price

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
//double prevLevel = iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, 1);
//double currLevel = iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, 0);
//double histLevel = iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, sdBackToHistory);
//double prevPrice = iClose(Symbol(), sdTimeframe, sdBackToHistory);

//switch(operation)
//  {
//   case OP_BUY:
//     {
//      //return prevLevel < sdLevel && currLevel >= sdLevel && Ask > prevPrice;
//      return iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, 1) < sdLevel
//             && iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, 0) >= sdLevel
//             && Ask > iClose(Symbol(), sdTimeframe, sdBackToHistory)
//             //&& CanOpenFirstOrderMA(operation)
//             ;
//     }
//   case OP_SELL:
//     {
//      //return prevLevel < sdLevel && currLevel >= sdLevel && Bid < prevPrice;
//      return iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, 1) < sdLevel
//             && iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, 0) >= sdLevel
//             && Bid < iClose(Symbol(), sdTimeframe, sdBackToHistory)
//             //&& CanOpenFirstOrderMA(operation)
//             ;
//     }
//   default:
//      return false;
//  }

   bool filterByPrice = false; // confirms trend

   switch(operation)
     {
      case OP_BUY:
        {
         //filterByPrice = Ask > iClose(Symbol(), sdTimeframe, sdBackToHistory)
         //                //&& CanOpenFirstOrderMA(operation)
         //                ;
         filterByPrice = iOsMA(Symbol(), sdTimeframe, osmaFastEmaPeriod, osmaSlowEmaPeriod, osmaMacdSmaPeriod, osmaAppliedPrice, 0) > 0;
         break;
        }
      case OP_SELL:
        {
         //filterByPrice = Bid < iClose(Symbol(), sdTimeframe, sdBackToHistory)
         //                //&& CanOpenFirstOrderMA(operation)
         //                ;
         filterByPrice = iOsMA(Symbol(), sdTimeframe, osmaFastEmaPeriod, osmaSlowEmaPeriod, osmaMacdSmaPeriod, osmaAppliedPrice, 0) < 0;
         break;
        }
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }

   return filterByPrice
//&& iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, 6) < sdLevel - 0.0006
          && iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, sdBackPeriod) < sdLevel - sdBackDiffCoef
          && iStdDev(Symbol(), sdTimeframe, sdMaPeriod, sdMaShift, sdMaMethod, sdAppliedPrice, 0) >= sdLevel;
  }
//+------------------------------------------------------------------+
