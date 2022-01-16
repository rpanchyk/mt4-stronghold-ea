//+------------------------------------------------------------------+
//|                                            Stronghold_LIB_TM.mqh |
//|                                            Trade Manager Library |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, FireTrot"
#property link        "https://firetrot.com"
#property description "Library serves trading operations"
#property strict

#include <Stronghold_LIB_GM.mqh>
#include <Stronghold_LIB_ST.mqh>

enum TRADE_ON
  {
   TRADE_ON_TICK, // Каждый тик
   TRADE_ON_BAR, // Новый бар
   TRADE_ON_TIMER // По таймеру
  };

// config
extern string _010 = "==== Общие ====";
extern int magic = 100; // Уникальный идентификатор инструмента
extern bool dryModeEnabled = false; // Режим "Сушка" (закрытие сеток)
extern bool showStats = true; // Показывать статистику?

extern string _020 = "==== Торговля ====";
extern TRADE_ON tradeOn = TRADE_ON_BAR; // Как торговать?
extern int timerInterval = 60; // Интервал таймера (секунд)
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class TradeManager
  {
public:
                     TradeManager(string inSymbol, int inPeriod, Strategy *inStrategy);
                    ~TradeManager();

   void              OnTickExecution();

   string            GetStats();
   int               TotalOrdersCount(); // TODO: wrongly used by MA only. Remove?
private:
   string            symbol;
   int               period;
   datetime          lastBarTime;
   double            currentLots;
   double            currentProfit;
   int               orderTickets[];
   datetime          lastOnTimerExecution;
   bool              tradeOnTimerAllowed;
   string            stats;
   GridManager       *gm;
   Strategy          *st;

   void              SimulateTimer();
   bool              IsTradeAllowedByNewBar();
   bool              IsTradeAllowedByTimer();
   void              Trade();
   bool              CanOpenFirstOrder(int operation);
   bool              CanOpenRefillOrder(int operation);
   bool              CanOpenAveragingOrder(int operation);
   void              OpenOpositeOrder();
   bool              IsProfitReached();
   bool              IsLossReached();
   double            CurrentLots();
   double            IncrementAndGetLots(double coef);
   double            IncrementLots(double value, double coef);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TradeManager::TradeManager(string inSymbol, int inPeriod, Strategy *inStrategy)
  {
   symbol = inSymbol;
   period = inPeriod;
   st = inStrategy;
   gm = new GridManager(symbol, magic, gridsCount);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManager::~TradeManager()
  {
   delete gm;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManager::OnTickExecution()
  {
   if(!IsTradeAllowed())
     {
      return;
     }

   SimulateTimer();

   if(tradeOn == TRADE_ON_BAR)
     {
      if(!IsTradeAllowedByNewBar())
        {
         return;
        }
     }

   if(tradeOn == TRADE_ON_TIMER)
     {
      if(!IsTradeAllowedByTimer())
        {
         return;
        }
     }

   Trade();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManager::SimulateTimer()
  {
   datetime currSec = TimeCurrent();
   if(currSec >= lastOnTimerExecution + timerInterval)
     {
      lastOnTimerExecution = currSec;

      stats = showStats ? gm.Stats() : "";
      tradeOnTimerAllowed = true;
     }
  }

//+------------------------------------------------------------------+
//| https://www.mql5.com/ru/articles/159                             |
//+------------------------------------------------------------------+
bool TradeManager::IsTradeAllowedByNewBar()
  {
   datetime currentBarTime = iTime(symbol, period, 0);
   if(lastBarTime != currentBarTime)
     {
      lastBarTime = currentBarTime;
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TradeManager::IsTradeAllowedByTimer()
  {
   if(tradeOnTimerAllowed)
     {
      tradeOnTimerAllowed = false;
      return true; // disable flag but allow one-time trading
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeManager::Trade()
  {
   gm.ResetPosition();

   while(gm.HasNext())
     {
      gm.GetNext(orderTickets);
      currentLots = CurrentLots();
      currentProfit = gm.GridProfit();

      if(IsProfitReached())
        {
         if(trailingStep > 0)
           {
            if(gm.UpdateTrailing(currentProfit, trailingStep))
              {
               Print("Trailing stop updated, profit: ", currentProfit);
               continue;
              }

            if(currentProfit <= gm.GetTrailingStopLoss())
              {
               Print("Trailing stop reached, profit: ", currentProfit);
               gm.ResetTrailing();
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
double TradeManager::CurrentLots()
  {
   double lastLots = gm.LastOrderLotsForGrid();
   return lastLots != 0 ? lastLots : startLots;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TradeManager::IncrementAndGetLots(double coef)
  {
   currentLots = IncrementLots(currentLots, coef);
   return currentLots;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TradeManager::IncrementLots(double value, double coef)
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
bool TradeManager::IsProfitReached()
  {
   return currentProfit >= takeProfit + trailingStep;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TradeManager::IsLossReached()
  {
   int gridOrdersCount = gm.GridOrdersCount();

   if(!recoveryEnabled || gridOrdersCount == 0 || currentProfit > 0)
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
void TradeManager::OpenOpositeOrder()
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
bool TradeManager::CanOpenRefillOrder(int operation)
  {
   if(!refillEnabled || gm.GridOrdersCount() == 0 || gm.GetTrailingStopLoss() > 0)
     {
      return false;
     }

   int orderType = -1;
   int refills = 0;
   int ticket = -1;
   double trendLots = 0;

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
bool TradeManager::CanOpenAveragingOrder(int operation)
  {
   if(!averagingEnabled || gm.GridOrdersCount() == 0 || gm.GetTrailingStopLoss() > 0)
     {
      return false;
     }

   int orderType = -1;
   int averagings = 0;
   int ticket = -1;
   double trendLots = 0;

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
bool TradeManager::CanOpenFirstOrder(int operation)
  {
   if(dryModeEnabled || gm.GridOrdersCount() > 0 || gm.FirstOrderIsOpenedOnBar())
     {
      return false;
     }

   return st.CanOpenFirstOrder(operation);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TradeManager::TotalOrdersCount()
  {
   return gm.TotalOrdersCount();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TradeManager::GetStats()
  {
   return stats;
  }
//+------------------------------------------------------------------+
