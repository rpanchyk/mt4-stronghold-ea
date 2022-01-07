//+------------------------------------------------------------------+
//|                                                Quantum Indicator |
//|                                         Copyright 2021, FireTrot |
//|                              Based on 'Quantum.mq4' 2010, zznbrm |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2020, FireTrot"
#property link        "https://firetrot.com"
#property description "Indicator shows possible trade entry points"
//#property strict

#property indicator_chart_window
#property indicator_color1 clrLime
#property indicator_color2 clrRed
#property indicator_buffers 2

// buffers
double buyBuffer[];
double sellBuffer[];

// settings
extern int arrowSize = 3;
extern color arrowOnUpColor = clrLime;
extern color arrowOnDnColor = clrRed;
extern int arrowUpCode = 233;
extern int arrowDnCode = 234;
extern double signalGap = 0.5;

// input parameters
extern int eintDepth3 = 300;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   SetIndexBuffer(0, buyBuffer);
   SetIndexEmptyValue(0, 0.0);
   SetIndexStyle(0, DRAW_ARROW, EMPTY, arrowSize, arrowOnUpColor);
   SetIndexArrow(0, arrowUpCode);
   SetIndexLabel(0, NULL);

   SetIndexBuffer(1, sellBuffer);
   SetIndexEmptyValue(1, 0.0);
   SetIndexStyle(1, DRAW_ARROW, EMPTY, arrowSize, arrowOnDnColor);
   SetIndexArrow(1, arrowDnCode);
   SetIndexDrawBegin(1, 0.0);
   SetIndexLabel(1, NULL);

   IndicatorDigits(5);
   IndicatorShortName("Quantum");

   return 0;
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0)
     {
      return -1;
     }
   if(counted_bars > 0)
     {
      counted_bars--;
     }
   int intLimit = Bars - counted_bars;

   int intLow3;
   int intHigh3;
   for(int index = intLimit; index >= 0; index--)
     {
      buyBuffer[index] = 0.0;
      sellBuffer[index] = 0.0;

      intLow3 = iLowest(Symbol(), Period(), MODE_LOW, eintDepth3, index);
      if(intLow3 == index)
        {
         buyBuffer[index] = Low[index] - 5 * signalGap * Point;
        }

      intHigh3 = iHighest(Symbol(), Period(), MODE_HIGH, eintDepth3, index);
      if(intHigh3 == index)
        {
         sellBuffer[index] = High[index] + 5 * signalGap * Point;
        }
     }

   return 0;
  }
//+------------------------------------------------------------------+
