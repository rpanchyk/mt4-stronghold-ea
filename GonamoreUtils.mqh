//+------------------------------------------------------------------+
//| Utils                                                            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, GoNaMore"
#property link      "https://github.com/gonamore"
#property strict

// constants
const int slippage = 30;

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
                     GridManager(int gridCount, string symbolName, int magicNumber);
   bool              HasNext();
   void              GetNext(int &out[]);
   void              CloseOrdersForGrid();
   string            GetStats();
   int               OrdersCount();
   double            GetProfit();
   int               OpenOrder(int operation, double volume, string comment);
   int               PrevOrdersCount();
   bool              PrevIsLocked();
private:
   string            symbol;
   int               magic;
   int               index;
   int               sortedTickets[]; // sorted order tickets
   Grid              grids[]; // set of grids

   void              InitTickets(OrderField field, int &out[]);
   void              InitGrids(int gridCount);
   bool              IsNotManagedOrder(string symbolName, int magicNumber);
   double            GetInProfit();
   double            GetInLoss();
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
GridManager::GridManager(int gridCount, string symbolName, int magicNumber)
  {
   RefreshRates();

   symbol = symbolName;
   magic = magicNumber;
   index = -1;
   InitTickets(fOrderOpenTime, sortedTickets);
   InitGrids(gridCount);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool            GridManager::HasNext()
  {
   return index < ArraySize(grids) - 1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void              GridManager::GetNext(int &out[])
  {
   index++;

   int size = ArraySize(grids[index].tickets);
   ArrayResize(out, size);

   for(int i = 0; i < size; i++)
     {
      out[i] = grids[index].tickets[i];
     }
  }

//+------------------------------------------------------------------+
//| https://tlap.com/massivy-i-czikly/                               |
//+------------------------------------------------------------------+
void              GridManager::InitTickets(OrderField field, int &out[])
  {
   int size = OrdersTotal();
   if(size == 0)
     {
      ArrayResize(out, size);
      return;
     }

   double arr[][2];
   ArrayResize(arr, size);

   for(int i = size - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return;
        }
      if(IsNotManagedOrder(OrderSymbol(), OrderMagicNumber()))
        {
         Print("skip order ", i, OrderSymbol(), OrderMagicNumber());
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool              GridManager::IsNotManagedOrder(string symbolName, int magicNumber)
  {
   return symbol != symbolName || magic != magicNumber;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void             GridManager::InitGrids(int gridCount)
  {
   ArrayResize(grids, gridCount);

   int ticketsCount = ArraySize(sortedTickets);
   for(int i = 0; i < gridCount; i++)
     {
      ArrayResize(grids[i].tickets, 0);
     }

   for(int i = 0; i < ticketsCount; i++)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return;
        }

      string orderComment = OrderComment();
      if(StringFind(orderComment, "grid") != -1)
        {
         // gridXX_yy_zz
         int startPos = StringLen("grid");
         int length = StringFind(orderComment, "_") - StringLen("grid");
         string gridIndexAsString = StringSubstr(orderComment, startPos, length);
         int gridIndex = StrToInteger(gridIndexAsString);

         int newSize = ArraySize(grids[gridIndex].tickets) + 1;
         ArrayResize(grids[gridIndex].tickets, newSize);

         grids[gridIndex].tickets[newSize - 1] = OrderTicket();
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GridManager::CloseOrdersForGrid()
  {
   int ordersCount = ArraySize(grids[index].tickets);

   if(ordersCount > 0)
     {
      for(int i = ordersCount - 1; i >= 0; i--)
        {
         if(!OrderSelect(grids[index].tickets[i], SELECT_BY_TICKET, MODE_TRADES))
           {
            Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
            return;
           }

         int orderType = OrderType();
         int orderTicket = OrderTicket();
         double orderLots = OrderLots();

         if(orderType == OP_BUY)
           {
            if(!OrderClose(orderTicket, orderLots, Bid, slippage, clrBlue))
              {
               Print(__FUNCTION__, ": ", "Unable to close BUY order: ", orderTicket, " error: ", GetLastError());
               return;
              }
           }

         if(orderType == OP_SELL)
           {
            if(!OrderClose(orderTicket, orderLots, Ask, slippage, clrRed))
              {
               Print(__FUNCTION__, ": ", "Unable to close SELL order: ", orderTicket, " error: ", GetLastError());
               return;
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GridManager::GetStats()
  {
   if(OrdersCount() > 0)
     {
      string orderStats = "";
      for(int i = 0; i < OrdersCount(); i++)
        {
         if(!OrderSelect(sortedTickets[i], SELECT_BY_TICKET, MODE_TRADES))
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

      return
         "\n" + "Orders: " + orderStats +
         "\n" + "In Profit: " + DoubleToString(GetInProfit(), 0) +
         "\n" + "In Loss: " + DoubleToString(GetInLoss(), 0) +
         "\n" + "Overall Profit: " + DoubleToString(GetProfit(), 0)
         ;
     }
   else
     {
      return "\n" + "No orders";
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GridManager::OrdersCount()
  {
   int result = ArraySize(sortedTickets);
   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GridManager::GetInProfit()
  {
   double result = 0;
   if(OrdersCount() > 0)
     {
      for(int i = OrdersCount() - 1; i >= 0; i--)
        {
         if(!OrderSelect(sortedTickets[i], SELECT_BY_TICKET, MODE_TRADES))
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
double GridManager::GetInLoss()
  {
   double result = 0;
   if(OrdersCount() > 0)
     {
      for(int i = OrdersCount() - 1; i >= 0; i--)
        {
         if(!OrderSelect(sortedTickets[i], SELECT_BY_TICKET, MODE_TRADES))
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
double GridManager::GetProfit()
  {
   double result = 0;
   if(OrdersCount() > 0)
     {
      for(int i = OrdersCount() - 1; i >= 0; i--)
        {
         if(!OrderSelect(sortedTickets[i], SELECT_BY_TICKET, MODE_TRADES))
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
//| Returns order ticket or -1 if error occured                      |
//+------------------------------------------------------------------+
int GridManager::OpenOrder(int operation, double volume, string comment)
  {
   RefreshRates();

   string operationAsString;
   double price;
   color arrowColor;

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

   string orderComment = "grid" + IntegerToString(index) + "_" + comment;

   int ticket = OrderSend(Symbol(), operation, volume, price, slippage, 0, 0, orderComment, magic, 0, arrowColor);
   if(ticket != -1)
     {
      if(OrderSelect(ticket, SELECT_BY_TICKET))
        {
         Print(operationAsString, " order ", "ticket: ", ticket, " opened: ", OrderOpenPrice(), " with comment: ", orderComment);

         // update tickets info
         InitTickets(fOrderOpenTime, sortedTickets);
         InitGrids(ArraySize(grids));

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
//|                                                                  |
//+------------------------------------------------------------------+
int GridManager::PrevOrdersCount()
  {
   if(index < 1)
     {
      return 0;
     }

   Grid grid = grids[index - 1];
   int result = ArraySize(grid.tickets);

   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool              GridManager::PrevIsLocked()
  {
   if(index < 1)
     {
      return false;
     }

   Grid grid = grids[index - 1];
   int ordersCount = ArraySize(grid.tickets);

   if(ordersCount > 1)
     {
      if(!OrderSelect(grid.tickets[ordersCount - 1], SELECT_BY_TICKET, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return false;
        }
      double currLots = OrderLots();

      if(!OrderSelect(grid.tickets[ordersCount - 2], SELECT_BY_TICKET, MODE_TRADES))
        {
         Print(__FUNCTION__, ": ", "Unable to select the order: ", GetLastError());
         return false;
        }
      double prevLots = OrderLots();

      Print(currLots, prevLots);

      return currLots == prevLots;
     }

   return false;
  }
//+------------------------------------------------------------------+
