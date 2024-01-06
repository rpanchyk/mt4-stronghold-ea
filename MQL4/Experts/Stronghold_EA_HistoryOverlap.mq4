//+------------------------------------------------------------------+
//|                                                Stronghold_EA.mq4 |
//|                                   Expert Adviser for MetaTrader4 |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, rpanchyk"
#property link        "https://github.com/rpanchyk/fx-stronghold-ea"
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
   bool hasFirstConfirm = tm.HasFirstConfirm(operation);

   switch(operation)
     {
      case OP_BUY:
        {
         if(!hasFirstConfirm)
           {
            if(BuyFirstConfirmApproved())
              {
               tm.SetFirstConfirm(operation);
              }
            return false;
           }
         else
           {
            return BuySecondConfirmApproved();
           }
        }
      case OP_SELL:
        {
         if(!hasFirstConfirm)
           {
            if(SellFirstConfirmApproved())
              {
               tm.SetFirstConfirm(operation);
              }
            return false;
           }
         else
           {
            return SellSecondConfirmApproved();
           }
        }
      default:
         Print(__FUNCTION__, ": ", "Unsupported operation: ", operation);
         return false;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BuyFirstConfirmApproved()
  {
   return CustomIndicator(1, 1) <= -InpPeriod;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BuySecondConfirmApproved()
  {
   double currSar = iSAR(Symbol(), Period(), 0.0018, 0.2, 1);
   double currPrice = iOpen(Symbol(), Period(), 1);

   return currSar <= currPrice;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SellFirstConfirmApproved()
  {
   return CustomIndicator(0, 1) >= InpPeriod;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SellSecondConfirmApproved()
  {
   double currSar = iSAR(Symbol(), Period(), 0.0018, 0.2, 1);
   double currPrice = iClose(Symbol(), Period(), 1);

   return currSar >= currPrice;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CustomIndicator(int buffer, int shift)
  {
   return iCustom(Symbol(), Period(), "HistoryOverlap", InpHistoryLimit, InpPeriod, InpEstimatedBarApplyTo, InpHistoricalBarApplyTo, buffer, shift);
  }
//+------------------------------------------------------------------+
