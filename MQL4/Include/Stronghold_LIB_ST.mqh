//+------------------------------------------------------------------+
//|                                            Stronghold_LIB_ST.mqh |
//|                                               Strategy Interface |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, FireTrot"
#property link        "https://firetrot.com"
#property description "Interface describes strategy"
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Strategy
  {
public:
   virtual bool      CanOpenFirstOrder(int operation);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Strategy::CanOpenFirstOrder(int operation)
  {
   Print(__FUNCTION__, ": ", "Abstract strategy is executed");
   return false;
  }
//+------------------------------------------------------------------+
