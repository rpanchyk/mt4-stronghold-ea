//+------------------------------------------------------------------+
//|                                            Stronghold_LIB_ST.mqh |
//|                                               Strategy Interface |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, rpanchyk"
#property link        "https://github.com/rpanchyk/mt4-stronghold-ea"
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
