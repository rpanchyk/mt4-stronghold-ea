//|               Forex Expert Adviser for MetaTrader4               |
//| The adviser serves series of grids               |
//+------------------------------------------------------------------+
#property copyright  "Copyright 2020, GoNaMore"
#property link       "https://github.com/gonamore"
#property version    "1.0"
#property strict

#include <GonamoreUtils.mqh>

enum OPEN_FIRST_ORDER_BY // Определение первого ордера сетки
  {
   PREVIOUS_NETWOWK, // По ордеру предыдущей сетки
   MOVING_AVERAGE, // По скользящей средней
   STOCHASTIC, // По стохастику
   STANDARD_DEVIATION, // По стандартному отклонению
   ADX_OSMA // По пересечению ADX с подверждением OsMA
  };

// config
input string _010 = "==== Настройки инструмента ====";
extern int magic = 100; // Уникальный идентификатор инструмента
extern bool isDryMode = false; // Режим "Сушка" (закрытие сеток)

input string _020 = "==== Основные настройки ====";
extern double startLots = 0.1; // Стартовый лот
extern double maxLots = 6.0; // Максимальный лот
extern int takeProfit = 40; // Прибыль в валюте депозита (центы)
//extern int stopLoss = 40; // Убыток в валюте депозита перед разрулом (центы)
int stopLoss = takeProfit;

input string _030 = "==== Доливка ====";
extern bool refillEnabled = true; // Активировано?
extern int refillProfitLevel = 50; // Доливка при достижении процента от профита
extern double refillLotsCoef = 1.2; // Шаг лота доливки

input string _040 = "==== Разрул ====";
extern bool recoveryEnabled = true; // Активировано?
extern double recoveryLotsCoef = 2.5; // Шаг лота противоположного ордера
extern int maxOpositeOrdersCountForDowngradeRecoveryLots = 4; // Количество опозитних ордеров перед понижением лота разрула
extern double downgradeRecoveryLotsCoef = 0.1; // Коеф. пониженого лота разрула (1.0 + єто число)
extern bool closeByLoss = false; // Закрывать ордера по стоп-лоссу (для тестирования индикаторов)
extern bool lockIfMaxOpositeOrdersReached = false; // Локировать сетку при макс. количестве опозитных ордеров

input string _050 = "==== Определение первого ордера сетки ====";
extern OPEN_FIRST_ORDER_BY openFirstOrderBy = MOVING_AVERAGE; // Стратегия открытия первого ордера

input string _051 = "==== Определение первого ордера сетки по пред. сетке ====";
extern bool opOpositeOrderTypeToPreviousNetwork = true; // Перевертыш к пред. сетке
extern bool opByTrendIfWasNoOpositeOrderInPreviousNetwork = false; // Учитивать переворот пред. сетки

input string _052 = "==== Определение первого ордера сетки по скользяшке ====";
extern ENUM_TIMEFRAMES maTimeframe = PERIOD_M1; // Таймфрейм
extern int maPeriod = 56; // Период
int maShift = 0; // Сдвиг
ENUM_MA_METHOD maMethod = MODE_SMA; // Метод
ENUM_APPLIED_PRICE maAppliedPrice = PRICE_MEDIAN; // Применяемая цена
extern int maBackToHistory = 10; // Назад в историю для определения тренда

input string _053 = "==== Определение первого ордера сетки по стохе ====";
extern int stochKperiod = 11; // K-период
int stochDperiod = 16; // D-период
extern int stochSlowing = 13; // Замедление
ENUM_MA_METHOD stochMethod = MODE_SMA; // Метод
extern double stochUpLevel = 95.0; // Верхний уровень
extern double stochDownLevel = 5.0; // Нижний уровень

input string _054 = "==== Определение первого ордера сетки по стандартному отклонению ====";
extern ENUM_TIMEFRAMES sdTimeframe = PERIOD_M1; // Таймфрейм
extern int sdMaPeriod = 20; // Период
int sdMaShift = 0; // Сдвиг
ENUM_MA_METHOD sdMaMethod = MODE_SMA; // Метод
ENUM_APPLIED_PRICE sdAppliedPrice = PRICE_CLOSE; // Применяемая цена
extern int sdBackToHistory = 10; // Назад в историю для определения тренда
extern double sdLevel = 0.001; // Уровень для открытия ордера
extern int sdBackPeriod = 6; // Исторический период
extern double sdBackDiffCoef = 0.0006; // Историческая разница коеф.

input string _055 = "==== Определение первого ордера сетки по ADX ====";
extern int adxPeriod = 14; // ADX - Period
extern ENUM_APPLIED_PRICE adxAppliedPrice = PRICE_CLOSE; // ADX - Applied price
extern int osmaFastEmaPeriod = 12; // OsMA - Fast EMA period
extern int osmaSlowEmaPeriod = 26; // OsMA - Slow EMA period
extern int osmaMacdSmaPeriod = 9; // OsMA - MACD SMA period
extern ENUM_APPLIED_PRICE osmaAppliedPrice = PRICE_CLOSE; // Applied price

// runtime
int orderTickets[]; // sorted order tickets
double currentLots = startLots;
GridManager *gm;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsTradeAllowed())
     {
      return;
     }

   gm = new GridManager(3, Symbol(), magic);
   Comment(gm.Stats());

   while(gm.HasNext())
     {
      gm.GetNext(orderTickets);

      if(gm.GridIsLocked())
        {
         if(gm.GridProfit() >= 0)
           {
            Print("Closing grid");
            gm.CloseOrdersForGrid();
            ResetState();
           }
         currentLots = startLots; // (!)
         continue;
        }

      if(IsProfitReached())
        {
         Print("Profit reached");
         gm.CloseOrdersForGrid();
         ResetState();
         continue;
        }

      if(IsLossReached())
        {
         if(closeByLoss)
           {
            Print("Close by loss");
            gm.CloseOrdersForGrid();
            ResetState();
            continue;
           }

         Print("Loss reached");
         OpenOpositeOrder();
         continue;
        }

      if(CanOpenFirstOrder(OP_BUY))
        {
         Print("Can open BUY order");
         gm.OpenOrder(OP_BUY, currentLots, "first BUY");
         continue;
        }

      if(CanOpenFirstOrder(OP_SELL))
        {
         Print("Can open SELL order");
         gm.OpenOrder(OP_SELL, currentLots, "first SELL");
         continue;
        }

      if(CanOpenRefillOrder(OP_BUY))
        {
         Print("Can open BUY order - refill");
         gm.OpenOrder(OP_BUY, IncrementAndGetLots(refillLotsCoef), "refill BUY");
         continue;
        }

      if(CanOpenRefillOrder(OP_SELL))
        {
         Print("Can open SELL order - refill");
         gm.OpenOrder(OP_SELL, IncrementAndGetLots(refillLotsCoef), "refill SELL");
         continue;
        }
     }

   delete gm;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//int OrdersCount()
//  {
//   int result = ArraySize(orderTickets);
//   return result;
//  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsProfitReached()
  {
   return gm.TotalProfit() >= takeProfit;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsLossReached()
  {
   if(!recoveryEnabled || gm.GridOrdersCount() == 0)
     {
      return false;
     }

   if(!OrderSelect(orderTickets[gm.GridOrdersCount() - 1], SELECT_BY_TICKET, MODE_TRADES))
     {
      Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
      return false;
     }

   double stop = stopLoss * currentLots / startLots; // Carefull (!)

   if(OrderProfit() + OrderCommission() + OrderSwap() < stop * -1)
     {
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetState()
  {
   currentLots = startLots;
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

   int networkOpositeCount = 0;
   for(int i = gm.GridOrdersCount() - 1; i >= 0; i--)
     {
      if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return;
        }

      if(StringFind(OrderComment(), "first") != -1)
        {
         break;
        }
      if(StringFind(OrderComment(), "oposite") != -1)
        {
         networkOpositeCount++;
        }
     }

//double lotsCoef = networkOpositeCount >= maxOpositeOrdersCountForDowngradeRecoveryLots
//                  ? (1.0 + networkOpositeCount * downgradeRecoveryLotsCoef)
//                  : recoveryLotsCoef;

   double lotsCoef = recoveryLotsCoef;
   if(networkOpositeCount >= maxOpositeOrdersCountForDowngradeRecoveryLots)
     {
      if(lockIfMaxOpositeOrdersReached)
        {
         lotsCoef = 1.0; // lock
        }
      else
        {
         lotsCoef = 1.0 + networkOpositeCount * downgradeRecoveryLotsCoef;
        }
     }

//Print("currentLots = ", currentLots, " opositeLots = ", opositeLots);
//currentLots = IncrementLots(opositeLots, recoveryLotsCoef);
   currentLots = IncrementLots(opositeLots, lotsCoef);

   string comment = lotsCoef == 1.0 ? "lock" : "oposite";

   switch(orderType)
     {
      case OP_BUY:
        {
         gm.OpenOrder(OP_SELL, currentLots, comment + "_SELL");
         break;
        }
      case OP_SELL:
        {
         gm.OpenOrder(OP_BUY, currentLots, comment + "_BUY");
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OpenOpositeOrder2()
  {
   if(gm.GridOrdersCount() == 0)
     {
      return;
     }

   double buyLots = 0;
   double sellLots = 0;
   int networkOpositeCount = 0;

   for(int i = gm.GridOrdersCount() - 1; i >= 0; i--)
     {
      if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return;
        }

      if(OrderType() == OP_BUY)
        {
         buyLots += OrderLots();
        }
      if(OrderType() == OP_SELL)
        {
         sellLots += OrderLots();
        }
      if(StringFind(OrderComment(), "oposite") != -1)
        {
         networkOpositeCount++;
        }
     }

   double lotsCoef = recoveryLotsCoef;
   if(networkOpositeCount >= maxOpositeOrdersCountForDowngradeRecoveryLots)
     {
      if(lockIfMaxOpositeOrdersReached)
        {
         // lock
         gm.OpenOrder(OP_SELL, buyLots, "lock_SELL");
         gm.OpenOrder(OP_BUY, sellLots, "lock_BUY");
         return;
        }
      else
        {
         lotsCoef = 1.0 + networkOpositeCount * downgradeRecoveryLotsCoef;
        }
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

   currentLots = IncrementLots(opositeLots, lotsCoef);
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
bool CanOpenFirstOrder(int operation)
  {
//if(isDryMode || OrdersCount() > 0)
   if(isDryMode)
     {
      return false;
     }

   switch(openFirstOrderBy)
     {
      case PREVIOUS_NETWOWK:
         return CanOpenFirstOrderByPreviousNetwork(operation);
      case MOVING_AVERAGE:
         return CanOpenFirstOrderMA(operation);
      case STOCHASTIC:
         return CanOpenFirstOrderStoch(operation);
      case STANDARD_DEVIATION:
         return CanOpenFirstOrderStandardDeviation(operation);
      case ADX_OSMA:
         return CanOpenFirstOrderAdxOsMA(operation);
      default:
         Print(__FUNCTION__, ": ", "Unknown openning first order type: ", openFirstOrderBy);
         return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanOpenFirstOrderByPreviousNetwork(int operation)
  {
   RefreshRates();

   int ordersHistoryTotal = OrdersHistoryTotal();
   if(ordersHistoryTotal == 0)
     {
      Print(__FUNCTION__, ": ", "No history order, openning BUY");
      return operation == OP_BUY;
     }

   int orderType = -1;
   int prevOrderType = -1;
   int prevTicket = -1;
   for(int i = ordersHistoryTotal - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return false;
        }
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != magic || OrderType() > 5)
        {
         continue;
        }

      if(orderType == -1 && (prevTicket > OrderTicket() || i == 0))
        {
         orderType = prevOrderType;
         Print(__FUNCTION__, ": ", "last order type: ", orderType, " for ticket: ", OrderTicket());
         break;
        }

      prevOrderType = OrderType();
      prevTicket = OrderTicket();
     }

   if(orderType == -1)
     {
      Print(__FUNCTION__, ": ", "Cannot determine order type (seems new account), openning BUY");
      return operation == OP_BUY;
     }

   if(opByTrendIfWasNoOpositeOrderInPreviousNetwork)
     {
      Print(__FUNCTION__, ": ", "Unsupported opByTrendIfWasNoOpositeOrderInPreviousNetwork yet");
      return false;
     }

   switch(operation)
     {
      case OP_BUY:
         return opOpositeOrderTypeToPreviousNetwork ? orderType == OP_SELL : true;
      case OP_SELL:
         return opOpositeOrderTypeToPreviousNetwork ? orderType == OP_BUY : true;
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanOpenFirstOrderMA(int operation)
  {
   if(gm.TotalOrdersCount() > 0 && (gm.GridOrdersCount() > 0 || !gm.PrevGridIsLocked()))
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
bool CanOpenFirstOrderStoch(int operation)
  {
   switch(operation)
     {
      case OP_BUY:
         return iStochastic(Symbol(), 0, stochKperiod, stochDperiod, stochSlowing, stochMethod, 0, 0, 2) <= stochDownLevel
                && iStochastic(Symbol(), 0, stochKperiod, stochDperiod, stochSlowing, stochMethod, 0, 0, 1) > stochDownLevel;
      case OP_SELL:
         return iStochastic(Symbol(), 0, stochKperiod, stochDperiod, stochSlowing, stochMethod, 0, 0, 2) >= stochUpLevel
                && iStochastic(Symbol(), 0, stochKperiod, stochDperiod, stochSlowing, stochMethod, 0, 0, 1) < stochUpLevel;
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
bool CanOpenRefillOrder(int operation)
  {
   if(!refillEnabled || gm.GridOrdersCount() == 0)
     {
      return false;
     }

   if(!OrderSelect(orderTickets[gm.GridOrdersCount() - 1], SELECT_BY_TICKET, MODE_TRADES))
     {
      Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
      return false;
     }

   if(openFirstOrderBy == STANDARD_DEVIATION && StringFind(OrderComment(), "oposite") != -1)
     {
      return false;
     }

   if(openFirstOrderBy == PREVIOUS_NETWOWK && StringFind(OrderComment(), "oposite") != -1)
     {
      return false;
     }

   double refillLevel = 1.0 * takeProfit * refillProfitLevel / 100;

   if(operation == OP_BUY && OrderType() == OP_BUY && OrderOpenPrice() < Ask && OrderProfit() + OrderCommission() + OrderSwap() > refillLevel)
     {
      return true;
     }

   if(operation == OP_SELL && OrderType() == OP_SELL && OrderOpenPrice() > Bid && OrderProfit() + OrderCommission() + OrderSwap() > refillLevel)
     {
      return true;
     }

   return false;
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
