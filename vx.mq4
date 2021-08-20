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
   //--- check Bars is less than MA_Slow
   uint bars = Bars;
   if(bars < RSI || bars < MA_Fast || bars < MA_Slow){
      PrintFormat(__FUNCTION__,"Error: Not enough Bars (%d) for Indicators!",bars);
      return;
   }
   
  }
//+------------------------------------------------------------------+
