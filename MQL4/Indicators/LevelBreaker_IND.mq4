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

// input parameters
int confirmBarsCount = 3;
int minRequiredBars = 30; // Min required number of bars to analylize

// buffers
double Support[];
double Resistance[];
double SR_Mean[];
double HLC3[];
double MAOnArray[];
double buyBuffer[];
double sellBuffer[];

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
//int availableBars = maxBars >= Bars ? Bars : maxBars;

//SetIndexDrawBegin(0, Bars - availableBars);
//SetIndexDrawBegin(1, Bars - availableBars);

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

//if(counted_bars < 1) // initial zero
//  {
//   for(int i = 1; i <= availableBars; i++)
//     {
//      Resistance[availableBars - i] = 0;
//      Support[availableBars - i] = 0;
//      buyBuffer[availableBars - i] = 0;
//      sellBuffer[availableBars - i] = 0;
//     }
//  }

//if(counted_bars > 1)
//  {
//   return 0;
//  }

// int i = availableBars; //Bars - counted_bars;
//Print("Bars: " + Bars + " counted_bars: " + counted_bars);
//if(counted_bars > 0)
//  {
//   i++;
//  }
//else
//  {
//   Resistance[i] = High[i];
//   Support[i] = Low[i];
//  }

//availableBars = availableBars - counted_bars;
//int availableBars = Bars - counted_bars;
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

//for(int j = availableBars - 1; j >= 0; j--)
//  {
//   if(HLC3[j + 1] < MAOnArray[j + 1] && HLC3[j] > MAOnArray[j])
//     {
//      Support[j] = Low[iLowest(NULL, 0, MODE_LOW, 28, j)];
//     }
//   else
//     {
//      Support[j] = Support[j + 1];
//     }
//  }

   for(int j = 0; j < availableBars; j++)
     {
      SR_Mean[j] = NormalizeDouble((Resistance[j] + Support[j]) / 2.0, Digits);
     }

//if(canBuy && Close[i - 0] > Resistance[i - 1] && Close[i - 1] > Resistance[i - 1] && Close[i - 2] > Resistance[i - 1])
   if(canDoBuy())
     {
      //buyBuffer[i] = Low[i];
      buyBuffer[0] = Ask;
      canBuy = false;
     }

   if(canDoSell())
     {
      //sellBuffer[i] = High[i];
      sellBuffer[0] = Bid;
      canSell = false;
     }

//if(Ask < SR_Mean[i - 1])
   if(Resistance[confirmBarsCount] != Resistance[confirmBarsCount + 1])
     {
      canBuy = true;
     }
//if(Bid > SR_Mean[i - 1])
   if(Support[confirmBarsCount] != Support[confirmBarsCount + 1])
     {
      canSell = true;
     }

//Comment(
//   "\n"
//   + "Resistance: " + Resistance[i] //+ toString(Resistance)
//   + "\n"
//   + "Support: " + Support[i] //+ toString(Support)
//);

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

   int index = 1;
   if(Resistance[index] != Resistance[confirmBarsCount - 1])
     {
      return false;
     }

//bool res = true;

   for(int i = 0; i < confirmBarsCount; i++)
     {
      //      int index = bar - i;
      //      if(ArraySize(Open) <= index || index < 0)
      //        {
      //         return false;
      //        }
      //
      //      int index2 = bar - 1;
      //      if(ArraySize(Resistance) <= index2)
      //        {
      //         return false;
      //        }

      if(Open[i] <= Resistance[i])
        {
         return false;
        }
     }

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

   int index = 1;
   if(Support[index] != Support[confirmBarsCount - 1])
     {
      return false;
     }

   for(int i = 0; i < confirmBarsCount; i++)
     {
      //      int index = bar - i;
      //      if(ArraySize(Open) <= index || index < 0)
      //        {
      //         return false;
      //        }
      //
      //      int index2 = bar - 1;
      //      if(ArraySize(Support) <= index2)
      //        {
      //         return false;
      //        }

      //if(Open[index] >= Support[index2])
      if(Open[i] >= Support[i])
        {
         return false;
        }
     }

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

   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//string toString(double &arr[])
//  {
//   string res = "";
//
////for(int i = ArraySize(arr) - 1; i >= 0; i--)
//   for(int i = 0; i < ArraySize(arr); i++)
//     {
//      res += " " + i + "=" + arr[i];
//     }
//
//   return res;
//  }
//+------------------------------------------------------------------+
