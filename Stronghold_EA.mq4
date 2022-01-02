//+------------------------------------------------------------------+
//|               Forex Expert Adviser for MetaTrader4               |
//|                The adviser serves series of grids                |
//+------------------------------------------------------------------+
#property copyright  "Copyright 2020, GoNaMore"
#property link       "https://github.com/gonamore"
#property version    "1.4"
#property strict

#include <Stronghold_LIB_v1.4.mqh>

enum OPEN_FIRST_ORDER_BY // Определение первого ордера сетки
  {
   MOVING_AVERAGE, // По скользящей средней
   STOCHASTIC, // По стохастику
   STANDARD_DEVIATION, // По стандартному отклонению
   ADX_OSMA, // По пересечению ADX с подверждением OsMA
   LEVEL_BREAKER // По пробитию уровней
  };

// config
extern string _010 = "==== Общие ====";
extern int magic = 100; // Уникальный идентификатор инструмента
extern bool isDryMode = false; // Режим "Сушка" (закрытие сеток)
extern bool showStats = true; // Показывать статистику?
extern int refreshStatsPeriod = 60; // Интервал обновления статистики (секунд)

extern string _020 = "==== Торговля ====";
extern double startLots = 0.01; // Стартовый лот
extern double maxLots = 10.0; // Максимальный лот
extern int takeProfit = 25; // Прибыль в валюте депозита
extern int stopLoss = 0; // Убыток в валюте депозита перед разрулом (0 = прибыль)
extern bool useProportionalStopLoss = true; // Использовать пропорциональный стоп-лосс от стартового лота
extern int gridsCount = 1; // Количество сеток (зависит от типа определения первого ордера)

extern string _021 = "==== Трейлинг-стоп ====";
extern int trailingStep = 0; // Шаг трейла (вверх и вниз от текущего профита) (0 = выключен)

extern string _030 = "==== Доливка ====";
extern bool refillEnabled = true; // Активировано?
extern int refillCount = 10; // Количество доливок
extern double refillLotsCoef = 1.5; // Шаг лота доливки
extern double refillMaxLots = 2; // Максимальный лот доливки

extern string _040 = "==== Усреднение ====";
extern bool averagingEnabled = true; // Активировано?
extern int averagingCount = 10; // Количество усреднений
extern double averagingLotsCoef = 1.5; // Шаг лота усреднения
extern double averagingMaxLots = 2; // Максимальный лот усреднения

extern string _050 = "==== Разрул ====";
extern bool recoveryEnabled = true; // Активировано?
extern double recoveryLotsCoef = 2.5; // Шаг лота противоположного ордера
extern bool closeByLoss = false; // Закрывать ордера по стоп-лоссу (для тестирования)

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
datetime lastOnTimerExecution;
string stats;
double currentLots;
int orderTickets[];
GridManager *gm;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   gm = new GridManager(Symbol(), magic, gridsCount);
   EventSetTimer(refreshStatsPeriod);

   if(IsTesting())
     {
      OnTimer();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   delete gm;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   stats = showStats ? gm.Stats() : "";
   lastOnTimerExecution = TimeCurrent();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsTradeAllowed())
     {
      return;
     }

   if(IsTesting() && TimeCurrent() > lastOnTimerExecution + refreshStatsPeriod)
     {
      OnTimer();
     }

   Comment(stats);
   gm.ResetPosition();

   while(gm.HasNext())
     {
      gm.GetNext(orderTickets);
      currentLots = CurrentLots();

      if(IsProfitReached())
        {
         if(trailingStep > 0)
           {
            double profit = gm.GridProfit();
            if(gm.UpdateTrailing(profit, trailingStep))
              {
               Print("Trailing stop updated, profit: ", profit);
               refillEnabled = false;
               averagingEnabled = false;
               continue;
              }

            if(profit <= gm.GetTrailingStopLoss())
              {
               Print("Trailing stop reached, profit: ", profit);
               gm.ResetTrailing();
               refillEnabled = true;
               averagingEnabled = true;
               gm.CloseOrdersForGrid();
               gm.InitTicketsAndGrids();
               continue;
              }
           }
         else
           {
            Print("Profit reached");
            gm.CloseOrdersForGrid();
            gm.InitTicketsAndGrids();
            continue;
           }
        }

      if(IsLossReached())
        {
         if(closeByLoss)
           {
            Print("Close by loss");
            gm.CloseOrdersForGrid();
            gm.InitTicketsAndGrids();
           }
         else
           {
            Print("Loss reached");
            OpenOpositeOrder();
           }
         continue;
        }

      if(CanOpenFirstOrder(OP_BUY))
        {
         Print("Can open BUY order");
         gm.OpenOrder(OP_BUY, currentLots, "first_BUY");
         continue;
        }

      if(CanOpenFirstOrder(OP_SELL))
        {
         Print("Can open SELL order");
         gm.OpenOrder(OP_SELL, currentLots, "first_SELL");
         continue;
        }

      if(CanOpenRefillOrder(OP_BUY))
        {
         Print("Can open BUY order - refill");
         gm.OpenOrder(OP_BUY, IncrementAndGetLots(refillLotsCoef), "refill_BUY");
         continue;
        }

      if(CanOpenRefillOrder(OP_SELL))
        {
         Print("Can open SELL order - refill");
         gm.OpenOrder(OP_SELL, IncrementAndGetLots(refillLotsCoef), "refill_SELL");
         continue;
        }

      if(CanOpenAveragingOrder(OP_BUY))
        {
         Print("Can open BUY order - averaging");
         gm.OpenOrder(OP_BUY, IncrementAndGetLots(averagingLotsCoef), "averaging_BUY");
         continue;
        }

      if(CanOpenAveragingOrder(OP_SELL))
        {
         Print("Can open SELL order - averaging");
         gm.OpenOrder(OP_SELL, IncrementAndGetLots(averagingLotsCoef), "averaging_SELL");
         continue;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CurrentLots()
  {
   double lastLots = gm.LastOrderLotsForGrid();
   return lastLots != 0 ? lastLots : startLots;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double IncrementAndGetLots(double coef)
  {
   currentLots = IncrementLots(currentLots, coef);
   return currentLots;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double IncrementLots(double value, double coef)
  {
   double result = MathMin(value * coef, maxLots);
   result *= 100;
   result = MathRound(result);
   result /= 100;
   return NormalizeDouble(result, 2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsProfitReached()
  {
   return gm.GridProfit() >= takeProfit + trailingStep;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsLossReached()
  {
   int gridOrdersCount = gm.GridOrdersCount();

   if(!recoveryEnabled || gridOrdersCount == 0)
     {
      return false;
     }

   if(!OrderSelect(orderTickets[gridOrdersCount - 1], SELECT_BY_TICKET, MODE_TRADES))
     {
      Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
      return false;
     }

   int resolvedStopLoss = stopLoss > 0 ? stopLoss : takeProfit;
   double proportionalStopLoss = resolvedStopLoss * currentLots / startLots; // Carefull (!)
   double stop = useProportionalStopLoss ? proportionalStopLoss : resolvedStopLoss;

   return OrderProfit() + OrderCommission() + OrderSwap() < stop * -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenOpositeOrder()
  {
   if(gm.GridOrdersCount() == 0)
     {
      return;
     }

   int orderType = -1;
   double opositeLots = 0;
   for(int i = gm.GridOrdersCount() - 1; i >= 0; i--)
     {
      if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return;
        }

      if(orderType == -1) // define last order type
        {
         orderType = OrderType();
        }
      if(orderType != OrderType())
        {
         break;
        }
      opositeLots += OrderLots(); // gather either BUY or SELL lots (!)
     }

   currentLots = IncrementLots(opositeLots, recoveryLotsCoef);

   switch(orderType)
     {
      case OP_BUY:
        {
         gm.OpenOrder(OP_SELL, currentLots, "oposite_SELL");
         break;
        }
      case OP_SELL:
        {
         gm.OpenOrder(OP_BUY, currentLots, "oposite_BUY");
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanOpenRefillOrder(int operation)
  {
   if(!refillEnabled || gm.GridOrdersCount() == 0)
     {
      return false;
     }

   double trendLots = 0;

   int orderType = -1;
   int refills = 0;
   int ticket = -1;
   for(int i = gm.GridOrdersCount() - 1; i >= 0; i--)
     {
      if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return false;
        }

      if(orderType == -1) // define last order type
        {
         orderType = OrderType();
        }
      if(orderType != OrderType())
        {
         break;
        }

      if(StringFind(OrderComment(), "refill") != -1)
        {
         refills++;
        }
      else
        {
         ticket = OrderTicket(); // initial ticket in this direction
        }

      trendLots += OrderLots(); // gather either BUY or SELL lots (!)
     }

   if(trendLots * refillLotsCoef > refillMaxLots)
     {
      return false;
     }

   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     {
      Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
      return false;
     }

   double profit = OrderProfit() + OrderCommission() + OrderSwap();
   double level = 1.0 * takeProfit / (refillCount + 1);
   bool canProceed = refillCount > refills && profit > level * (refills + 1);

   if(canProceed && operation == OP_BUY && OrderType() == OP_BUY && OrderOpenPrice() < Ask)
     {
      return true;
     }
   if(canProceed && operation == OP_SELL && OrderType() == OP_SELL && OrderOpenPrice() > Bid)
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanOpenAveragingOrder(int operation)
  {
   if(!averagingEnabled || gm.GridOrdersCount() == 0)
     {
      return false;
     }

   double trendLots = 0;

   int orderType = -1;
   int averagings = 0;
   int ticket = -1;
   for(int i = gm.GridOrdersCount() - 1; i >= 0; i--)
     {
      if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return false;
        }

      if(orderType == -1) // define last order type
        {
         orderType = OrderType();
        }
      if(orderType != OrderType())
        {
         break;
        }

      if(StringFind(OrderComment(), "averaging") != -1)
        {
         averagings++;
        }
      else
        {
         ticket = OrderTicket(); // initial ticket in this direction
        }

      trendLots += OrderLots(); // gather either BUY or SELL lots (!)
     }

   if(trendLots * averagingLotsCoef > averagingMaxLots)
     {
      return false;
     }

   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     {
      Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
      return false;
     }

   double profit = OrderProfit() + OrderCommission() + OrderSwap();
   if(profit >= 0)
     {
      return false;
     }

   int resolvedStopLoss = stopLoss > 0 ? stopLoss : takeProfit;
   double proportionalStopLoss = resolvedStopLoss * currentLots / startLots; // Carefull (!)
   double stop = useProportionalStopLoss ? proportionalStopLoss : resolvedStopLoss;
   double level = 1.0 * stop / (averagingCount + 1);

   bool canProceed = averagingCount > averagings && -1.0 * profit > level * (averagings + 1);

   if(canProceed && operation == OP_BUY && OrderType() == OP_BUY && OrderOpenPrice() > Ask)
     {
      return true;
     }
   if(canProceed && operation == OP_SELL && OrderType() == OP_SELL && OrderOpenPrice() < Bid)
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanOpenFirstOrder(int operation)
  {
   if(isDryMode || gm.GridOrdersCount() > 0 || gm.FirstOrderIsOpenedOnBar())
     {
      return false;
     }

   switch(openFirstOrderBy)
     {
      case MOVING_AVERAGE:
         return CanOpenFirstOrderByMmovingAverage(operation);
      case STOCHASTIC:
         return CanOpenFirstOrderByStochastic(operation);
      case STANDARD_DEVIATION:
         return CanOpenFirstOrderStandardDeviation(operation);
      case ADX_OSMA:
         return CanOpenFirstOrderAdxOsMA(operation);
      case LEVEL_BREAKER:
         return CanOpenFirstOrderByLevelBreaker(operation);
      default:
         Print(__FUNCTION__, ": ", "Unknown openning first order type: ", openFirstOrderBy);
         return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanOpenFirstOrderByMmovingAverage(int operation)
  {
   if(gm.TotalOrdersCount() > 0) // only one grid is allowed
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
bool CanOpenFirstOrderByStochastic(int operation)
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
bool CanOpenFirstOrderStandardDeviation(int operation)
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
bool CanOpenFirstOrderAdxOsMA(int operation)
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
bool CanOpenFirstOrderByLevelBreaker(int operation)
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
