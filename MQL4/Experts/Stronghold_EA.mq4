//|               Forex Expert Adviser for MetaTrader4               |
//| The adviser serves series of grids               |
//+------------------------------------------------------------------+
#property copyright  "Copyright 2020, GoNaMore"
#property link       "https://github.com/gonamore"
#property version    "1.0"
#property strict

enum OPEN_FIRST_ORDER_BY // Определение первого ордера сетки
  {
   PREVIOUS_NETWOWK, // По ордеру предыдущей сетки
   MOVING_AVERAGE, // По скользящей средней
   STOCHASTIC, // По стохастику
   STANDARD_DEVIATION, // По стандартному отклонению
   ADX_OSMA // По пересечению ADX с подверждением OsMA
  };

enum OrderField
  {
   fOrderOpenTime,   // Время открытия
   fOrderType,       // Тип
   fOrderLots,       // Объём
   fOrderOpenPrice,  // Цена открытия
   fOrderStopLoss,   // S/L
   fOrderTakeProfit, // T/P
   fOrderCommission, // Комиссия
   fOrderSwap,       // Своп
   fOrderProfit      // Прибыль
  };

struct Grid
  {
   int               tickets[];
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class GridManager
  {
public:
   void                Init()
     {
      index = 0;
      InitTickets(fOrderOpenTime, sortedTickets);
      //InitGrids();
     }

   bool              HasNext()
     {
      return index < ArraySize(grids);
     }

   void              GetNext(int &out[])
     {
      int size = ArraySize(grids);
      ArrayResize(out, size);

      for(int i = 0; i < size; i++)
        {
         out[i] = int(grids[index].tickets[i]);
        }

      index++;
     }
private:
   int               sortedTickets[]; // sorted order tickets
   Grid              grids[]; // set of grids
   int               index;

   // https://tlap.com/massivy-i-czikly/
   void              InitTickets(OrderField field, int &out[])
     {
      RefreshRates();

      double arr[][2];

      int size = OrdersTotal();
      ArrayResize(arr, size);

      for(int i= size - 1; i >= 0; i--)
        {
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
           {
            Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
            return;
           }
         if(IsNotManagedOrder(OrderSymbol(), OrderMagicNumber()))
           {
            continue;
           }

         arr[i][1] = OrderTicket();

         switch(field)
           {
            case fOrderOpenTime:
               arr[i][0] = double(OrderOpenTime());
               break;
            case fOrderType:
               arr[i][0] = OrderType();
               break;
            case fOrderLots:
               arr[i][0] = OrderLots();
               break;
            case fOrderOpenPrice:
               arr[i][0] = OrderOpenPrice();
               break;
            case fOrderStopLoss:
               arr[i][0] = OrderStopLoss();
               break;
            case fOrderTakeProfit:
               arr[i][0] = OrderTakeProfit();
               break;
            case fOrderCommission:
               arr[i][0] = OrderCommission();
               break;
            case fOrderSwap:
               arr[i][0] = OrderSwap();
               break;
            case fOrderProfit:
               arr[i][0] = OrderProfit();
               break;
           }
        }

      ArraySort(arr);
      ArrayResize(out, size);

      for(int i = 0; i < size; i++)
        {
         out[i] = int(arr[i][1]);
        }
     }

   bool              IsNotManagedOrder(string symbol, int magicNumber)
     {
      return symbol != Symbol() || magicNumber != magic;
     }
  };

// constants
const int slippage = 50;

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
extern bool closeByLoss = false;

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
//int[] gridToTickets[]; // sorted order tickets by grid
double currentLots = startLots;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsTradeAllowed())
     {
      return;
     }

   InitAndSortOrderTickets(fOrderOpenTime, orderTickets);
   ShowStats();

   if(IsProfitReached())
     {
      Print("Profit reached");
      CloseOrders();
      return;
     }

   if(IsLossReached())
     {
      if(closeByLoss)
        {
         Print("Close by loss");
         CloseOrders();
         return;
        }

      Print("Loss reached");
      OpenOpositeOrder();
      return;
     }

   if(CanOpenFirstOrder(OP_BUY))
     {
      Print("Can open BUY order");
      OpenOrder(OP_BUY, currentLots, "first BUY");
      return;
     }

   if(CanOpenFirstOrder(OP_SELL))
     {
      Print("Can open SELL order");
      OpenOrder(OP_SELL, currentLots, "first SELL");
      return;
     }

   if(CanOpenRefillOrder(OP_BUY))
     {
      Print("Can open BUY order - refill");
      OpenOrder(OP_BUY, IncrementAndGetLots(refillLotsCoef), "refill BUY");
      return;
     }

   if(CanOpenRefillOrder(OP_SELL))
     {
      Print("Can open SELL order - refill");
      OpenOrder(OP_SELL, IncrementAndGetLots(refillLotsCoef), "refill SELL");
      return;
     }
  }

//+------------------------------------------------------------------+
//| https://tlap.com/massivy-i-czikly/                               |
//+------------------------------------------------------------------+
void InitAndSortOrderTickets(OrderField field, int &out[])
  {
   RefreshRates();

   double index[][2];

   int size = OrdersTotal();
   ArrayResize(index, size);

   for(int i= size - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return;
        }
      if(IsNotManagedOrder(OrderSymbol(), OrderMagicNumber()))
        {
         continue;
        }

      index[i][1] = OrderTicket();

      switch(field)
        {
         case fOrderOpenTime:
            index[i][0] = double(OrderOpenTime());
            break;
         case fOrderType:
            index[i][0] = OrderType();
            break;
         case fOrderLots:
            index[i][0] = OrderLots();
            break;
         case fOrderOpenPrice:
            index[i][0] = OrderOpenPrice();
            break;
         case fOrderStopLoss:
            index[i][0] = OrderStopLoss();
            break;
         case fOrderTakeProfit:
            index[i][0] = OrderTakeProfit();
            break;
         case fOrderCommission:
            index[i][0] = OrderCommission();
            break;
         case fOrderSwap:
            index[i][0] = OrderSwap();
            break;
         case fOrderProfit:
            index[i][0] = OrderProfit();
            break;
        }
     }

   ArraySort(index);
   ArrayResize(out, size);

   for(int i = 0; i < size; i++)
     {
      out[i] = int(index[i][1]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNotManagedOrder(string symbol, int magicNumber)
  {
   return symbol != Symbol() || magicNumber != magic;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowStats()
  {
   if(OrdersCount() > 0)
     {
      string orderStats = "";
      for(int i = 0; i < OrdersCount(); i++)
        {
         if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
           {
            Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
            break;
           }
         orderStats += "\n"
                       + "  " + OrderComment() + ":"
                       + " Profit: " + DoubleToString(OrderProfit(), 2)
                       + " Commission: " + DoubleToString(OrderCommission(), 2)
                       + " Swap: " + DoubleToString(OrderSwap(), 2)
                       + " Lots: " + DoubleToString(OrderLots(), 2);
        }

      Comment(
         "\n" + "Orders: ", orderStats,
         "\n" + "In Profit: " + DoubleToString(GetInProfit(), 0),
         "\n" + "In Loss: " + DoubleToString(GetInLoss(), 0),
         "\n" + "Overall Profit: " + DoubleToString(GetProfit(), 0)
      );
     }
   else
     {
      Comment(
         "\n" + "No orders"
      );
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrdersCount()
  {
   return ArraySize(orderTickets);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetInProfit()
  {
   double result = 0;
   if(OrdersCount() > 0)
     {
      for(int i = OrdersCount() - 1; i >= 0; i--)
        {
         if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
           {
            Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
            break;
           }

         if(OrderProfit() > 0)
           {
            result += OrderProfit() + OrderCommission() + OrderSwap();
           }
        }
     }
   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetInLoss()
  {
   double result = 0;
   if(OrdersCount() > 0)
     {
      for(int i = OrdersCount() - 1; i >= 0; i--)
        {
         if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
           {
            Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
            break;
           }

         if(OrderProfit() < 0)
           {
            result += OrderProfit() + OrderCommission() + OrderSwap();
           }
        }
     }
   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsProfitReached()
  {
   return GetProfit() >= takeProfit;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsLossReached()
  {
   if(!recoveryEnabled || OrdersCount() == 0)
     {
      return false;
     }

   if(!OrderSelect(orderTickets[OrdersCount() - 1], SELECT_BY_TICKET, MODE_TRADES))
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
double GetProfit()
  {
   double result = 0;
   if(OrdersCount() > 0)
     {
      for(int i = OrdersCount() - 1; i >= 0; i--)
        {
         if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
           {
            Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
            break;
           }

         result += OrderProfit() + OrderCommission() + OrderSwap();
        }
     }
   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOrders()
  {
   if(OrdersCount() > 0)
     {
      for(int i = OrdersCount() - 1; i >= 0; i--)
        {
         if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
           {
            Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
            return;
           }

         if(OrderType() == OP_BUY)
           {
            if(!OrderClose(OrderTicket(), OrderLots(), Bid, slippage, clrBlue))
              {
               Print(__FUNCTION__, ": ", "Unable to close BUY order: ", OrderTicket(), " error: ", GetLastError());
               return;
              }
           }

         if(OrderType() == OP_SELL)
           {
            if(!OrderClose(OrderTicket(), OrderLots(), Ask, slippage, clrRed))
              {
               Print(__FUNCTION__, ": ", "Unable to close SELL order: ", OrderTicket(), " error: ", GetLastError());
               return;
              }
           }
        }
     }

   ResetState();
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
   if(OrdersCount() == 0)
     {
      return;
     }

   int orderType = -1;
   double opositeLots = 0;

   for(int i = OrdersCount() - 1; i >= 0; i--)
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

//if(openFirstOrderBy == STANDARD_DEVIATION
//   && !CanOpenFirstOrderStandardDeviation(orderType)) // don't know why, but it works better with this filter (!)
//  {
//   return;
//  }

   int networkOpositeCount = 0;
   for(int i = OrdersCount() - 1; i >= 0; i--)
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

   double lotsCoef = networkOpositeCount >= maxOpositeOrdersCountForDowngradeRecoveryLots
                     ? (1.0 + networkOpositeCount * downgradeRecoveryLotsCoef)
                     : recoveryLotsCoef;

//Print("currentLots = ", currentLots, " opositeLots = ", opositeLots);
//currentLots = IncrementLots(opositeLots, recoveryLotsCoef);
   currentLots = IncrementLots(opositeLots, lotsCoef);

   switch(orderType)
     {
      case OP_BUY:
        {
         //if(!CanOpenFirstOrderStandardDeviation(OP_SELL))
         //  {
         //   return;
         //  }
         OpenOrder(OP_SELL, currentLots, "oposite SELL");
         break;
        }
      case OP_SELL:
        {
         //if(!CanOpenFirstOrderStandardDeviation(OP_BUY))
         //  {
         //   return;
         //  }
         OpenOrder(OP_BUY, currentLots, "oposite BUY");
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanOpenFirstOrder(int operation)
  {
   if(isDryMode || OrdersCount() > 0)
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
   if(!refillEnabled || OrdersCount() == 0)
     {
      return false;
     }

   if(!OrderSelect(orderTickets[OrdersCount() - 1], SELECT_BY_TICKET, MODE_TRADES))
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
double GetNetworkProfit()
  {
   if(OrdersCount() == 0)
     {
      return 0;
     }

   int orderType = -1;
   double result = 0;

   for(int i = OrdersCount() - 1; i >= 0; i--)
     {
      if(!OrderSelect(orderTickets[i], SELECT_BY_TICKET, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return 0;
        }

      if(orderType == -1) // define last order type
        {
         orderType = OrderType();
        }
      if(orderType != OrderType())
        {
         break;
        }
      result += OrderProfit() + OrderCommission() + OrderSwap();
     }

   return result;
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
//| Returns order ticket or -1 if error occured                      |
//+------------------------------------------------------------------+
int OpenOrder(int operation, double volume, string comment)
  {
   string operationAsString;
   double price;
   color arrowColor;

   RefreshRates();
   switch(operation)
     {
      case OP_BUY:
         operationAsString = "BUY";
         price = Ask;
         arrowColor = clrBlue;
         break;
      case OP_SELL:
         operationAsString = "SELL";
         price = Bid;
         arrowColor = clrRed;
         break;
      default:
         Print(__FUNCTION__, ": ", "Error operation not permitted: ", operation);
         return -1;
     }

   int ticket = OrderSend(Symbol(), operation, volume, price, slippage, 0, 0, comment, magic, 0, arrowColor);
   if(ticket != -1)
     {
      if(OrderSelect(ticket, SELECT_BY_TICKET))
        {
         Print(operationAsString, " order ", "ticket: ", ticket, " opened: ", OrderOpenPrice(), " with comment: ", comment);
         return ticket;
        }
      else
        {
         Print(__FUNCTION__, ": ", "Cannot get ", operationAsString, " order by ticket: ", ticket, " with error:", GetLastError());
         return -1;
        }
     }
   else
     {
      Print(__FUNCTION__, ": ", "Cannot open ", operationAsString, " order: ", GetLastError(), " volume: ", volume);
      return -1;
     }
  }
//+------------------------------------------------------------------+
