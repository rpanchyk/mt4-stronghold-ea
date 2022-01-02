//+------------------------------------------------------------------+
//|                                          Level Breaker Indicator |
//|                                         Copyright 2020, GoNaMore |
//|                    Based on 'VIP Dynamic Support Resistance.mq4' |
//|                      since 2010, KingLion - www.metastock.org.ua |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, GoNaMore"
#property link "https://github.com/gonamore/fx-level-breaker-ind"
#property description "Indicator shows possible trade entry points"
#property version "1.0"
#property strict

#property indicator_chart_window
#property indicator_buffers 7

// buffers
double Support[];
double Resistance[];
double SR_Mean[];
double HLC3[];
double MAOnArray[];
double buyBuffer[];
double sellBuffer[];

// input parameters
int confirmBarsCount = 4;
int minRequiredBars = 30; // Min required number of bars to analylize
bool filterByTrend = true;

// runtime
int counted_bars = 0;
bool canBuy = true;
bool canSell = true;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   IndicatorBuffers(7);

   SetIndexBuffer(0, Resistance);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDarkGreen);
   SetIndexLabel(0, "Resistance");
   SetIndexDrawBegin(0, 25);

   SetIndexBuffer(1, Support);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, clrFireBrick);
   SetIndexLabel(1, "Support");
   SetIndexDrawBegin(1, 25);

   SetIndexBuffer(2, SR_Mean);
   SetIndexStyle(2, DRAW_LINE, STYLE_DOT, 1, clrDarkGoldenrod);
   SetIndexLabel(2, "S/R_Mean");
   SetIndexDrawBegin(2, 25);

   SetIndexBuffer(3, HLC3);

   SetIndexBuffer(4, MAOnArray);

   SetIndexBuffer(5, buyBuffer);
   SetIndexStyle(5, DRAW_ARROW, EMPTY, 1, clrLime);
   SetIndexArrow(5, 108);
   SetIndexEmptyValue(5, 0.0);

   SetIndexBuffer(6, sellBuffer);
   SetIndexStyle(6, DRAW_ARROW, EMPTY, 1, clrRed);
   SetIndexArrow(6, 108);
   SetIndexEmptyValue(6, 0.0);

   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars < minRequiredBars)
     {
      return 0;
     }

   counted_bars = IndicatorCounted();
   if(counted_bars < 0) // check for possible errors
     {
      Print("Error: No counted bars");
      return -1;
     }

   int availableBars = minRequiredBars;

   for(int j = 0; j < availableBars; j++)
     {
      HLC3[j] = (High[iHighest(NULL, 0, MODE_HIGH, 3, j)] + Low[iLowest(NULL, 0, MODE_LOW, 3, j)] + Close[j]) / 3.0;
     }

   for(int j = 0; j < availableBars; j++)
     {
      MAOnArray[j] = iMAOnArray(HLC3, Bars, 25, 0, MODE_SMA, j);
     }

   for(int j = availableBars - 2; j >= 0; j--)
     {
      if(HLC3[j + 1] > MAOnArray[j + 1] && HLC3[j] < MAOnArray[j])
        {
         Resistance[j] = High[iHighest(NULL, 0, MODE_HIGH, 28, j)];
        }
      else
        {
         Resistance[j] = Resistance[j + 1];
        }

      if(HLC3[j + 1] < MAOnArray[j + 1] && HLC3[j] > MAOnArray[j])
        {
         Support[j] = Low[iLowest(NULL, 0, MODE_LOW, 28, j)];
        }
      else
        {
         Support[j] = Support[j + 1];
        }
     }

   for(int j = 0; j < availableBars; j++)
     {
      SR_Mean[j] = NormalizeDouble((Resistance[j] + Support[j]) / 2.0, Digits);
     }

   if(canDoBuy())
     {
      buyBuffer[0] = Ask;
      canBuy = false;
     }

   if(canDoSell())
     {
      sellBuffer[0] = Bid;
      canSell = false;
     }

   if(Resistance[confirmBarsCount] != Resistance[confirmBarsCount + 1])
     {
      canBuy = true;
     }

   if(Support[confirmBarsCount] != Support[confirmBarsCount + 1])
     {
      canSell = true;
     }

   return rates_total;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool canDoBuy()
  {
   if(!canBuy)
     {
      return false;
     }

   if(Resistance[0] != Resistance[confirmBarsCount - 1])
     {
      return false;
     }

   for(int i = 0; i < confirmBarsCount; i++)
     {
      if(Open[i] <= Resistance[i])
        {
         return false;
        }
     }

   if(filterByTrend)
     {
      for(int i = 1; i < ArraySize(Resistance); i += confirmBarsCount)
        {
         if(Resistance[0] == Resistance[i])
           {
            continue;
           }
         if(Resistance[0] < Resistance[i])
           {
            return false;
           }
         else
           {
            break;
           }
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool canDoSell()
  {
   if(!canSell)
     {
      return false;
     }

   if(Support[0] != Support[confirmBarsCount - 1])
     {
      return false;
     }

   for(int i = 0; i < confirmBarsCount; i++)
     {
      if(Open[i] >= Support[i])
        {
         return false;
        }
     }

   if(filterByTrend)
     {
      for(int i = 1; i < ArraySize(Support); i += confirmBarsCount)
        {
         if(Support[0] == Support[i])
           {
            continue;
           }
         if(Support[0] > Support[i])
           {
            return false;
           }
         else
           {
            break;
           }
        }
     }

   return true;
  }
//+------------------------------------------------------------------+
