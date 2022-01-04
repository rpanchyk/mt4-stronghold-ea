//+------------------------------------------------------------------+
//|                                                Stronghold_EA.mq4 |
//|                                   Expert Adviser for MetaTrader4 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, FireTrot"
#property link        "https://firetrot.com"
#property description "EA for automatic algorithmic trading"
#property version     "1.5" // Should we care of version?
#property strict

#include <Stronghold_LIB_TM.mqh>
#include <Stronghold_LIB_ST.mqh>

enum OPEN_FIRST_ORDER_BY // Определение первого ордера сетки
  {
   MOVING_AVERAGE, // По скользящей средней
   STOCHASTIC, // По стохастику
   STANDARD_DEVIATION, // По стандартному отклонению
   ADX_OSMA, // По пересечению ADX с подверждением OsMA
   LEVEL_BREAKER // По пробитию уровней
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MovingAverageStrategy : public Strategy
  {
public:
   virtual bool      CanOpenFirstOrder(int operation);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class StochasticStrategy : public Strategy
  {
public:
   virtual bool      CanOpenFirstOrder(int operation);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class StandardDeviationStrategy : public Strategy
  {
public:
   virtual bool      CanOpenFirstOrder(int operation);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class AdxOsMAStrategy : public Strategy
  {
public:
   virtual bool      CanOpenFirstOrder(int operation);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class LevelBreakerStrategy : public Strategy
  {
public:
   virtual bool      CanOpenFirstOrder(int operation);
  };

// config
extern string _100 = "==== Определение первого ордера сетки ====";
extern OPEN_FIRST_ORDER_BY openFirstOrderBy = MOVING_AVERAGE; // Стратегия открытия первого ордера

extern string _110 = "==== Определение первого ордера сетки по скользяшке ====";
extern ENUM_TIMEFRAMES maTimeframe = PERIOD_M1; // Таймфрейм
extern int maPeriod = 56; // Период
int maShift = 0; // Сдвиг
ENUM_MA_METHOD maMethod = MODE_SMA; // Метод
ENUM_APPLIED_PRICE maAppliedPrice = PRICE_MEDIAN; // Применяемая цена
extern int maBackToHistory = 10; // Назад в историю для определения тренда

extern string _120 = "==== Определение первого ордера сетки по стохе ====";
extern ENUM_TIMEFRAMES stochTimeframe = PERIOD_M1; // Таймфрейм
extern int stochKperiod = 11; // K-период
int stochDperiod = 16; // D-период
extern int stochSlowing = 13; // Замедление
ENUM_MA_METHOD stochMaMethod = MODE_SMA; // Метод MA
ENUM_STO_PRICE stochPrice = STO_LOWHIGH; // Цена
extern double stochUpLevel = 95.0; // Верхний уровень
extern double stochDownLevel = 5.0; // Нижний уровень

extern string _130 = "==== Определение первого ордера сетки по стандартному отклонению ====";
extern ENUM_TIMEFRAMES sdTimeframe = PERIOD_M1; // Таймфрейм
extern int sdMaPeriod = 20; // Период
int sdMaShift = 0; // Сдвиг
ENUM_MA_METHOD sdMaMethod = MODE_SMA; // Метод MA
ENUM_APPLIED_PRICE sdAppliedPrice = PRICE_CLOSE; // Применяемая цена
extern int sdBackToHistory = 10; // Назад в историю для определения тренда
extern double sdLevel = 0.001; // Уровень для открытия ордера
extern int sdBackPeriod = 6; // Исторический период
extern double sdBackDiffCoef = 0.0006; // Историческая разница коеф.

extern string _140 = "==== Определение первого ордера сетки по ADX ====";
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
   switch(openFirstOrderBy)
     {
      case MOVING_AVERAGE:
         st = new MovingAverageStrategy();
         break;
      case STOCHASTIC:
         st = new StochasticStrategy();
         break;
      case STANDARD_DEVIATION:
         st = new StandardDeviationStrategy();
         break;
      case ADX_OSMA:
         st = new AdxOsMAStrategy();
         break;
      case LEVEL_BREAKER:
         st = new LevelBreakerStrategy();
         break;
      default:
         Print(__FUNCTION__, ": ", "Unknown openning first order type: ", openFirstOrderBy);
         return;
     }

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
bool MovingAverageStrategy::CanOpenFirstOrder(int operation)
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
//|                                                                  |
//+------------------------------------------------------------------+
bool StochasticStrategy::CanOpenFirstOrder(int operation)
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
//|                                                                  |
//+------------------------------------------------------------------+
bool StandardDeviationStrategy::CanOpenFirstOrder(int operation)
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
//|                                                                  |
//+------------------------------------------------------------------+
bool LevelBreakerStrategy::CanOpenFirstOrder(int operation)
  {
   if(iVolume(Symbol(), 0, 0) > 1) // analyze on open bars only
     {
      return false;
     }

   switch(operation)
     {
      case OP_BUY:
         return iCustom(Symbol(), 0, "LevelBreaker_IND", 5, 0) > 0;
      case OP_SELL:
         return iCustom(Symbol(), 0, "LevelBreaker_IND", 6, 0) > 0;
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }
  }
//+------------------------------------------------------------------+
