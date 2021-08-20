//+------------------------------------------------------------------+
//|                                                           vx.mq4 |
//|                                                         VihokDam |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "VihokDam"
#property link      ""
#property version   "1.00"
#property strict

#define MAGICMA  20210820

input ENUM_TIMEFRAMES TF       = PERIOD_H1;
input uint MA_Fast             = 21;
input uint MA_Slow             = 50;
input uint RSI                 = 9;

//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
int OpenPosition(int OP, lots=0.01)
   {
      if(OP == OP_BUY){
         return OrderSend(Symbol(),OP_BUY,lots,Ask,3,0,0,"",MAGICMA,0);
      }else if(OP == OP_SELL){
         return OrderSend(Symbol(),OP_SELL,lots,Bid,3,0,0,"",MAGICMA,0);
      }
      return -1;
   }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
int CheckForOpen(double ma_fast, double ma_slow, double rsi, double close)
  {
   //--- Up Trend
   if(ma_fast > ma_slow && _
      close > ma_slow && _
      rsi < 50){
      return OP_BUY;
   }
   //--- Down Trend
   else if(ma_fast < ma_slow && _
      close < ma_slow && _
      rsi > 50){
      return OP_SELL
   }
   return -1;
  }
//+------------------------------------------------------------------+
//| Get Current Orders                                               |
//+------------------------------------------------------------------+
void CurrentOrders(string symbol, uint &buys, uint &sells)
  {
   for(int i = 0;i < OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false){
         PrintFormat(__FUNCTION__,"Error: Can't Get Current Orders {%s}", GetLastError());
         break;
      }
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA)
        {
         if(OrderType() == OP_BUY)  buys++;
         if(OrderType() == OP_SELL) sells++;
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //--- check Bars is less than Indicators input
   uint bars = Bars;
   if(bars < RSI || bars < MA_Fast || bars < MA_Slow){
      PrintFormat(__FUNCTION__,"Error: Not enough Bars (%d) for Indicators!",bars);
      return;
   }
   //--- go trading only for first tiks of new bar
   if(Volume[0] > 1) return false;
   
   //--- get data from indicators
   ma_fast = iMA(NULL,TF,MA_Fast,0,MODE_SMA,PRICE_CLOSE,1);
   ma_slow = iMA(NULL,TF,MA_Slow,0,MODE_SMA,PRICE_CLOSE,1);
   rsi = iRSI(NULL,TF,RSI,PRICE_CLOSE,1);
   close = Close[1];
   
  }
//+------------------------------------------------------------------+
