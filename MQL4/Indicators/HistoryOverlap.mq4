//+------------------------------------------------------------------+
//|                                               HistoryOverlap.mq4 |
//|                           Inspired by 'Quantum.mq4' 2010, zznbrm |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2022, FireTrot"
#property link        "https://firetrot.com"
#property description "Shows when the bar (closing price or shadow) overlaps in history"
#property version     "1.0"
#property strict

#property indicator_separate_window
#property indicator_buffers 2

enum APPLY_TO
  {
   APPLY_TO_CLOSE_PRICE, // Candle body close price
   APPLY_TO_SHADOW_CLOSE_PRICE // Candle shadow close price
  };

// input parameters
input int InpHistoryLimit = 1500; // Bars in history to process
input int InpPeriod = 100; // Period to compute overlaps
input APPLY_TO InpEstimatedBarApplyTo = APPLY_TO_SHADOW_CLOSE_PRICE; // Apply to estimated bar
input APPLY_TO InpHistoricalBarApplyTo = APPLY_TO_SHADOW_CLOSE_PRICE; // Apply to historical bar

// buffers
double buyBuffer[];
double sellBuffer[];

// runtime
double currStart; // current bar start price
double currEnd; // current bar end price
double histStart;  // historical bar start price
double histEnd; // historical bar end price
int overlap; // overlapping shift value

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   IndicatorShortName("HistoryOverlap(" + IntegerToString(InpPeriod) + ")");
   IndicatorDigits(0);
   IndicatorSetDouble(INDICATOR_MINIMUM, -InpPeriod);
   IndicatorSetDouble(INDICATOR_MAXIMUM, InpPeriod);

   SetIndexBuffer(0, buyBuffer);
   SetIndexLabel(0, "Overlap buy (bars)");
   SetIndexStyle(0, DRAW_HISTOGRAM, EMPTY, 3, clrGreen);
   SetIndexEmptyValue(0, 0.0);
   SetIndexDrawBegin(0, 0.0);

   SetIndexBuffer(1, sellBuffer);
   SetIndexLabel(1, "Overlap sell (bars)");
   SetIndexStyle(1, DRAW_HISTOGRAM, EMPTY, 3, clrRed);
   SetIndexEmptyValue(1, 0.0);
   SetIndexDrawBegin(1, 0.0);

   return INIT_SUCCEEDED;
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
   if(rates_total < InpPeriod)
     {
      return 0;
     }

   int limit = rates_total - prev_calculated + (prev_calculated > 0 ? 1 : -InpPeriod);
   limit = MathMin(limit, InpHistoryLimit);

   for(int i = 1; i < limit; i++)
     {
      if(InpEstimatedBarApplyTo == APPLY_TO_CLOSE_PRICE)
        {
         currStart = iOpen(NULL, 0, i);
         currEnd = iClose(NULL, 0, i);
        }
      else
        {
         if(isBullishBar(i))
           {
            currStart = iLow(NULL, 0, i);
            currEnd = iHigh(NULL, 0, i);
           }
         else
           {
            currStart = iHigh(NULL, 0, i);
            currEnd = iLow(NULL, 0, i);
           }
        }

      overlap = -1;
      for(int j = i + 1; j < i + InpPeriod - 1; j++)
        {
         if(InpHistoricalBarApplyTo == APPLY_TO_CLOSE_PRICE)
           {
            histStart = iOpen(NULL, 0, j);
            histEnd = iClose(NULL, 0, j);
           }
         else
           {
            if(isBullishBar(j))
              {
               histStart = iLow(NULL, 0, j);
               histEnd = iHigh(NULL, 0, j);
              }
            else
              {
               histStart = iHigh(NULL, 0, j);
               histEnd = iLow(NULL, 0, j);
              }
           }

         if(inRangeAbs(currEnd, histStart, histEnd))
           {
            overlap = j - i;
            break;
           }
        }

      if(currStart < currEnd)
        {
         buyBuffer[i] = overlap != -1 ? overlap : INT_MAX - 1; // put maximum value if actual was not found
        }
      else
        {
         sellBuffer[i] = overlap != -1 ? -overlap : INT_MIN + 1; // put minimum value if actual was not found
        }
     }

   return rates_total;
  }

//+------------------------------------------------------------------+
//| Determines if bar is bullish                                     |
//+------------------------------------------------------------------+
bool isBullishBar(int shift)
  {
   double open = iOpen(NULL, 0, shift);
   double close = iClose(NULL, 0, shift);

   return open < close;
  }

//+------------------------------------------------------------------+
//| Determines the given value belongs to unordered range            |
//+------------------------------------------------------------------+
bool inRangeAbs(double value, double from, double to)
  {
   double min = MathMin(from, to);
   double max = MathMax(from, to);

   return value > min && value < max;
  }
//+------------------------------------------------------------------+
