//+------------------------------------------------------------------+
//|                                                           vx.mq4 |
//|                                                         VihokDam |
//|                                                                  |
//+------------------------------------------------------------------+
#include <stderror.mqh>
#include <stdlib.mqh>
#property copyright "VihokDam"
#property link      ""
#property version   "1.00"
#property strict

#define MAGICMA  20210820

input ENUM_TIMEFRAMES TF       = PERIOD_H1;
input double LOTSIZE           = 0.01;
input double SL                = 0.01;
input double TP                = 0.005;
uint MA_PERIOD                 = 50;
uint RSI                       = 14;
uint OVERBOUGHT                = 70;
uint OVERSOLD                  = 30;

double LotSize;
//+------------------------------------------------------------------+
//| Doji identify function                                           |
//+------------------------------------------------------------------+
int Doji(double open, double high, double low, double close) { return(Doji(open, high, low, close, _Symbol, 0.40)); }
int Doji(double open, double high, double low, double close, string symbol, double dojiBodyPercentage) {
   double tick_size = MarketInfo(symbol, MODE_TICKSIZE);
   double dojiBody = ((high - low) / tick_size) * dojiBodyPercentage;
   //--- Dragonfly Doji return 0
   if(((high - close) / tick_size) <= dojiBody && ((high - open) / tick_size) <= dojiBody) return 0;
   //--- Gravestone Doji return 1
   if(((close - low) / tick_size) <= dojiBody && ((open - low) / tick_size) <= dojiBody) return 1;
   return -1;
}
//+------------------------------------------------------------------+
//| Big Black bar identify function                                  |
//+------------------------------------------------------------------+
bool IsBigBlackBar(double open, double high, double low, double close) { return(IsBigBlackBar(open, high, low, close, _Symbol, 0.20)); }
bool IsBigBlackBar(double open, double high, double low, double close, string symbol, double candleWickPercentage) {
   double tick_size = MarketInfo(symbol, MODE_TICKSIZE);
   double candleWick = ((high - low) / tick_size) * candleWickPercentage;   
   if(((high - close) / tick_size) <= candleWick && ((open - low) / tick_size) <= candleWick){
      return true;
   }else if(((close - low) / tick_size) <= candleWick && ((high - open) / tick_size) <= candleWick){
      return true;
   }
   return false;   
}
//+------------------------------------------------------------------+
//| Bigest bar identify function                                     |
//+------------------------------------------------------------------+
bool IsBigestBar(uint startBar=1, uint period=5){
   if(startBar >= period) return false;
   uint bars = startBar + period;
   double size = High[startBar] - Low[startBar];
   for(uint i=startBar;i<=bars;i++){
      if((High[i] - Low[i]) > size) break;
      if(i==bars) return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//| Check for stoploss                                               |
//+------------------------------------------------------------------+
int CheckForStopLoss(double ma, double rsi, double open, double high, double low, double close) {
   double rsi_mid = 50;
   if(high < ma && close < open && rsi < rsi_mid) {
      //---Stop buy
      return OP_BUY;
   }else if(low > ma && close > open && rsi > rsi_mid) {
      //---Stop sell
      return OP_SELL;
   }
   return -1;
}
//+------------------------------------------------------------------+
//| close order                                                      |
//+------------------------------------------------------------------+
int ClosePosition(int& tickets[], int op, double tp)               { return(ClosePosition(tickets, op, tp, 3)); }
int ClosePosition(int& tickets[], int op, double tp, int slippage) {
   int counter = 0;
   double tp_point = MathCeil(AccountEquity() * tp);
   if(tp_point <= 0) return -1;
   for(int i=0;i<ArrayRange(tickets, 0);i++) {
      if(OrderSelect(tickets[i], SELECT_BY_TICKET)==false) break;
      if(OrderType() != op) { continue; }
      if(OrderProfit() < tp_point) { continue; }
      if(OrderType() == OP_BUY) {
         if(OrderClose(tickets[i], OrderLots(), Bid, slippage)) { counter++; }
      }else if(OrderType() == OP_SELL) {
         if(OrderClose(tickets[i],OrderLots(), Ask, slippage)) { counter++; }
      }
   }
   if(counter > 0) { return counter; }
   return -1;
}
bool ClosePosition(int& tickets[])               { return(ClosePosition(tickets, 3)); }
bool ClosePosition(int& tickets[], int slippage) {
   int counter = 0;
   for(int i=0;i<ArrayRange(tickets, 0);i++) {
      if(OrderSelect(tickets[i], SELECT_BY_TICKET)==false) break;
      if(OrderType() == OP_BUY) {
         if(OrderClose(tickets[i], OrderLots(), Bid, slippage)) { counter++; }
      }else if(OrderType() == OP_SELL) {
         if(OrderClose(tickets[i],OrderLots(), Ask, slippage)) { counter++; }
      }
   }
   if(ArrayRange(tickets, 0) == counter) return true;
   return false;
}
//+------------------------------------------------------------------+
//| Check for close order                                            |
//+------------------------------------------------------------------+
int CheckForClose(double ma, int rsi, int doji, double open, double high, double low, double close, int overbought, int oversold) {
   if(IsBigBlackBar(open, high, low, close)) {
      if(rsi >= overbought) {         
         return OP_BUY;
      }else if(rsi <= oversold) {         
         return OP_SELL;
      }
   }else {
      if(doji == 0 && rsi < oversold) {         
         return OP_SELL;
      }else if(doji == 1 && rsi > overbought) {         
         return OP_BUY;
      }
   }
   return -1;
}
//+------------------------------------------------------------------+
//| open order                                                       |
//+------------------------------------------------------------------+
int OpenPosition(int OP)              { return(OpenPosition(OP, LotSize, _Symbol, 3, 0, 0, "")); }
int OpenPosition(int OP, double lots, string symbol, int slippage, double stoploss, double takeprofit, string comment) {
      if(OP == OP_BUY){
         return OrderSend(symbol , OP_BUY, lots, Ask, slippage, stoploss, takeprofit, comment, MAGICMA);
      }else if(OP == OP_SELL){
         return OrderSend(symbol, OP_SELL, lots, Bid, slippage, stoploss, takeprofit, comment, MAGICMA);
      }
      return -1;
   }
//+------------------------------------------------------------------+
//| Check for open order                                             |
//+------------------------------------------------------------------+
int CheckForOpen(double ma, int rsi, int doji, double open, double high, double low, double close, int overbought, int oversold) {
   if(IsBigBlackBar(open, high, low, close)) {
      if(open > ma && close > open && rsi <= overbought) {         
         return OP_BUY;
      }else if(open < ma && close < open && rsi >= oversold) {
         return OP_SELL;
      }
   }else {      
      if(doji == 0 && low > ma && rsi < overbought) {         
         return OP_BUY;
      }else if(doji == 1 && high < ma && rsi > oversold) {         
         return OP_SELL;
      }
   }
   return -1;
}
//+------------------------------------------------------------------+
//| get order ticket function                                        |
//+------------------------------------------------------------------+
bool GetOrderTickets(int& tickets[])                                   { return(GetOrderTickets(tickets, _Symbol, MAGICMA)); }
bool GetOrderTickets(int& tickets[], int OP)                           { return(GetOrderTickets(tickets, OP, _Symbol, MAGICMA)); }
bool GetOrderTickets(int& tickets[], int OP, string symbol, int magic_number) {
   int counter = 0;
   int ticket_counter = 0;   
   for(int i=0;i<OrdersTotal();i++){
      if(OrderSelect(i,SELECT_BY_POS)==false) break;
      if(OrderSymbol() == symbol && OrderMagicNumber() == magic_number && OrderType() == OP) {
         counter++;
         ArrayResize(tickets, counter);
         tickets[ticket_counter] = OrderTicket();
         ticket_counter++;         
      }
   }
   if(counter > 0) { return true; }
   return false;
}
bool GetOrderTickets(int& tickets[], string symbol, int magic_number) {
   int counter = 0;
   int ticket_counter = 0;   
   for(int i=0;i<OrdersTotal();i++){
      if(OrderSelect(i,SELECT_BY_POS)==false) break;
      if(OrderSymbol() == symbol && OrderMagicNumber() == magic_number) {
         counter++;
         ArrayResize(tickets, counter);
         tickets[ticket_counter] = OrderTicket();
         ticket_counter++;         
      }
   }
   if(counter > 0) { return true; }
   return false;
}
//+------------------------------------------------------------------+
//| Get Pip Size                                                     |
//+------------------------------------------------------------------+
double PipSize()              { return(PipSize(_Symbol)); }
double PipSize(string symbol) {
   double point  = MarketInfo(symbol, MODE_POINT);
   int    digits = (int)MarketInfo(symbol, MODE_DIGITS);
   return(((digits%2)==1) ? point*10 : point);
}
//+------------------------------------------------------------------+
//| Get Pip Value                                                    |
//+------------------------------------------------------------------+
double PipValue(double lotsize)                { return(PipValue(lotsize, _Symbol)); }
double PipValue(double lotsize, string symbol) { return(((MarketInfo(symbol,MODE_TICKVALUE)*PipSize(symbol))/MarketInfo(symbol,MODE_TICKSIZE))* lotsize); }
//+------------------------------------------------------------------+
//| Get Point Value                                                  |
//+------------------------------------------------------------------+
double PointValue(double lotsize)                { return(PointValue(lotsize, _Symbol)); }
double PointValue(double lotsize, string symbol) { return((((MarketInfo(symbol,MODE_TICKVALUE)*PipSize(symbol))/MarketInfo(symbol,MODE_TICKSIZE))* lotsize)/10); }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---   
   double min_lot = MarketInfo(_Symbol, MODE_MINLOT);
   double max_lot = MarketInfo(_Symbol, MODE_MAXLOT);
   if(LOTSIZE < min_lot) {
      LotSize = min_lot;
   }else if(LOTSIZE > max_lot) {
      LotSize = max_lot;
   }else{
      LotSize = LOTSIZE;
   }
   
   double point_value = PointValue(LotSize);
   double acc_sl      = AccountBalance() * SL;
   PrintFormat("LotSize: %.2f SL: %d%% $ %.2f %s, %d points", LotSize, (int)(SL*100), acc_sl, AccountCurrency(), (int)(acc_sl/point_value));
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
   if(bars < RSI || bars < MA_PERIOD){
      PrintFormat(__FUNCTION__,"Error: Not enough Bars (%d) for Indicators!",bars);
      return;
   }      
   
   if(!IsTradeAllowed()) { return; }   
   if(Volume[0] > 1)     { return; }
   
   //--- get data from indicators
   double ma    = iMA(NULL,TF,MA_PERIOD,0,MODE_SMA,PRICE_CLOSE,1);
   int rsi      = (int)iRSI(NULL,TF,RSI,PRICE_CLOSE,1);   
   double open  = Open[1];
   double high  = High[1];
   double low   = Low[1];
   double close = Close[1];
   int doji     = Doji(open, high, low, close);
   int tickets[];            
      
   int op_open = CheckForOpen(ma, rsi, doji, open, high, low, close, 70, 30);      
   if(op_open >= 0){
      int order_ticket = OpenPosition(op_open);
      if(order_ticket > 0) {
         PrintFormat("[%d]Open buy position success", order_ticket);
      }
   }
   
   int sl_op = CheckForStopLoss(ma, rsi, open, high, low, close);
   if(sl_op >= 0) {
      if(GetOrderTickets(tickets, sl_op)) {
         if(ClosePosition(tickets)) { Print("stop position success!!"); }
      }
   }
   
   int op_close = CheckForClose(ma, rsi, doji, open, high, low, close, 70, 30);
   if(op_close >= 0){
      if(ClosePosition(tickets, op_close, TP) > 0) Print("Close Position success.");
   }
  }
//+------------------------------------------------------------------+