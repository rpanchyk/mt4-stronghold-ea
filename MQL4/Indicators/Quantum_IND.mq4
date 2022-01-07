//+------------------------------------------------------------------+
//|                                               Quantum Signal.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright                 "Ludaedfx"
#property version                   "1.2"
#property description               "Quantum Signal"
                          
//---- indicator settings
#property indicator_chart_window
#property  indicator_buffers 2 
#property  indicator_color1 clrLime
#property  indicator_color2 clrRed
//*********************************//
enum MYENUM
 { 
   Var0,
   Var1 
 };
//*********************************//

//---- input parameters
extern int eintDepth3 = 300;
extern color  ArrowOnUpColor = clrLime;
extern color  ArrowOnDnColor = clrRed;
extern int    ArrowDnCode  = 234;
extern int    ArrowUpCode  = 233;
extern int    ArrowSize    = 4;
extern double SignalGap    = 0.5;
extern bool  AlertsMessage = true; 
extern bool  AlertsSound   = false;
extern bool  AlertsEmail   = false;
extern bool  AlertsMobile  = false;
//*********************************//
input MYENUM SIGNAL_BAR     = Var0;  

datetime TimeBar; 
//*********************************//
//---- indicator buffers
double gadblUp3[];
double gadblDn3[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   SetIndexBuffer( 0, gadblUp3 );
   SetIndexEmptyValue( 0, 0.0 );
   SetIndexStyle(0, DRAW_ARROW, EMPTY,ArrowSize,ArrowOnUpColor);
   SetIndexArrow(0, ArrowUpCode);
   SetIndexLabel( 0, NULL );
   
   SetIndexBuffer( 1, gadblDn3 );
   SetIndexEmptyValue( 1, 0.0 );
   SetIndexStyle(1, DRAW_ARROW, EMPTY,ArrowSize,ArrowOnDnColor);
   SetIndexArrow(1,ArrowDnCode );
   SetIndexDrawBegin(1,0.0);
   SetIndexLabel( 1, NULL ); 
    
   IndicatorDigits( 5 );
     
   //---- name for DataWindow and indicator subwindow label
   IndicatorShortName( "Quantum Signal(" + eintDepth3 + ")" );
   
   return( 0 );
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
   return( 0 );
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   
   if (counted_bars < 0) return (-1);
   if (counted_bars > 0) counted_bars--;
   int intLimit = Bars - counted_bars;
   int intLow3, intHigh3;

   for( int inx = intLimit; inx >= 0; inx-- )
   {          
      gadblUp3[inx] = 0.0;
      gadblDn3[inx] = 0.0;
      
      intLow3 = iLowest( Symbol(), Period(), MODE_LOW, eintDepth3, inx-eintDepth3/2);
      
      if ( intLow3 == inx )
      {
         gadblUp3[inx] = Low[inx]-5*SignalGap*Point;
      }

      intHigh3 = iHighest( Symbol(), Period(), MODE_HIGH, eintDepth3, inx-eintDepth3/2);
      
      if ( intHigh3 == inx )
      {
         gadblDn3[inx] = High[inx]+5*SignalGap*Point;
      }
   }
//--------------------------------------------------------------------
   if(AlertsMessage || AlertsSound || AlertsEmail || AlertsMobile)
     {
      string  message1   =  StringConcatenate(Symbol(), " M", Period()," ", " Quantum Signal : Sell!");
      string  message2   =  StringConcatenate(Symbol(), " M", Period()," ", " Quantum Signal : Buy!");

      if(TimeBar!=Time[0] && gadblUp3[SIGNAL_BAR]>=gadblDn3[SIGNAL_BAR] && gadblUp3[SIGNAL_BAR+1]<gadblDn3[SIGNAL_BAR+1])
        {
         if(AlertsMessage)
            Alert(message1);
         if(AlertsSound)
            PlaySound("alert2.wav");
         if(AlertsEmail)
            SendMail(Symbol()+" - "+WindowExpertName()+" - ",message1);
         if(AlertsMobile)
            SendNotification(message1);
         TimeBar=Time[0];
        }
      if(TimeBar!=Time[0] && gadblUp3[SIGNAL_BAR]<=gadblDn3[SIGNAL_BAR] && gadblUp3[SIGNAL_BAR+1]>gadblDn3[SIGNAL_BAR+1])
        {
         if(AlertsMessage)
            Alert(message2);
         if(AlertsSound)
            PlaySound("alert2.wav");
         if(AlertsEmail)
            SendMail(Symbol()+" - "+WindowExpertName()+" - ",message2);
         if(AlertsMobile)
            SendNotification(message2);
         TimeBar=Time[0];

        }

     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Period String                                                    |
//+------------------------------------------------------------------+
string PeriodString()
  {
   switch(_Period)
     {
      case PERIOD_M1:
         return("M1");
      case PERIOD_M5:
         return("M5");
      case PERIOD_M15:
         return("M15");
      case PERIOD_M30:
         return("M30");
      case PERIOD_H1:
         return("H1");
      case PERIOD_H4:
         return("H4");
      case PERIOD_D1:
         return("D1");
      case PERIOD_W1:
         return("W1");
      case PERIOD_MN1:
         return("MN1");
      default:
         return("M"+(string)_Period);
     }
   return("M"+(string)_Period);
  }

//+--------------------------------------+

