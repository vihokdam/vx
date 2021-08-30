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
string OBJ_TEXT_NAME           = "obj_name";

input ENUM_TIMEFRAMES TF       = PERIOD_H1;
input uint MA_PERIOD           = 50;
input uint RSI                 = 9;
input uint OVERBOUGHT          = 70;
input uint OVERSOLD            = 30;

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
//| Big Black bar identify function                                  |
//+------------------------------------------------------------------+
bool IsBigBlackBar(double open, double high, double low, double close, double candleWickPercentage=0.15)
  {
   double body = (high - low) * candleWickPercentage;   
   if((high - close) <= body){
      return true;
   }else if((close - low) <= body){
      return true;
   }
   return false;
  }
//+------------------------------------------------------------------+
//| StopLoss                                                         |
//+------------------------------------------------------------------+
void StopLoss(double sl=0.01){
   double sl_point = MathAbs(AccountBalance() * sl) * -1;   
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      if(OrderProfit() <= sl_point){
         if(OrderType() == OP_BUY){
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3))
               PrintFormat("OrderClose error : %s",ErrorDescription(GetLastError()));
         }else if(OrderType() == OP_SELL){
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3))
               PrintFormat("OrderClose error : %s",ErrorDescription(GetLastError()));
         }
      }
   }   
}
//+------------------------------------------------------------------+
//| close order                                                      |
//+------------------------------------------------------------------+
int ClosePosition(double tp=0.01){
   int counter = 0;
   double tp_point = AccountEquity() * tp;
   if(tp_point <= 0) return -1;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      if(OrderProfit() > tp_point){
         if(OrderType() == OP_BUY){
            if(OrderClose(OrderTicket(),OrderLots(),Bid,3)) counter++;
         }else if(OrderType() == OP_SELL){
            if(OrderClose(OrderTicket(),OrderLots(),Ask,3)) counter++;               
         }
      }
   }
   if(counter > 0) return counter;
   return -1;
}
//+------------------------------------------------------------------+
//| Check for close order                                            |
//+------------------------------------------------------------------+
int CheckForClose(double ma, double rsi, double open, double close, double low){
   if(IsBigestBar(1) && low > ma && close > open && rsi < OVERBOUGHT){
      return OP_SELL;
   }
   return -1;
}
//+------------------------------------------------------------------+
//| open order                                                       |
//+------------------------------------------------------------------+
int OpenPosition(int OP, double lots=0.01)
   {
      if(OP == OP_BUY){
         return OrderSend(Symbol(),OP_BUY,lots,Ask,3,0,0,"",MAGICMA,0);
      }else if(OP == OP_SELL){
         return OrderSend(Symbol(),OP_SELL,lots,Bid,3,0,0,"",MAGICMA,0);
      }
      return -1;
   }
//+------------------------------------------------------------------+
//| Check for open order                                             |
//+------------------------------------------------------------------+
int CheckForOpen(double ma, double rsi, double open, double high, double low, double close)
  {   
   if(low > ma && close > open && rsi >= 50 && IsBigBlackBar(open, high, low, close)){
      return OP_BUY;
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
   TextCreate(0,OBJ_TEXT_NAME);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   TextDelete(0,OBJ_TEXT_NAME);
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
   
   //--- draw label on chart
   string text = StringConcatenate("$",DoubleToStr(AccountProfit(),2),
   " [",DoubleToStr(AccountEquity(),2),"]",
   " ",DoubleToStr(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),2),"%",
   " ",TimeToString(TimeCurrent(),TIME_MINUTES));
   TextChange(0,OBJ_TEXT_NAME,text);
   TextMove(0,OBJ_TEXT_NAME,Time[0]+(Time[0]-Time[1]),Ask);
   
   if(!IsTradeAllowed()) return;
   //--- go trading only for first tiks of new bar   
   if(Volume[0] > 1){
      StopLoss();
   }else{
      //--- get data from indicators   
      double ma = iMA(NULL,TF,MA_PERIOD,0,MODE_SMA,PRICE_CLOSE,1);
      double rsi = iRSI(NULL,TF,RSI,PRICE_CLOSE,1);
      double open = Open[1];
      double high = High[1];
      double low = Low[1];
      double close = Close[1];
      
      if(IsTradeAllowed() && IsBigBlackBar(open, high, low, close)){
         int op_open = CheckForOpen(ma, rsi, open, high, low, close);
         if(op_open >= 0){
            if(OpenPosition(op_open) > 0) Print("Open Position success.");
         }
         
         int op_close = CheckForClose(ma, rsi, open, close, low);
         if(op_close >= 0){
            if(ClosePosition() > 0) Print("Close Position success.");
         }
      }
   }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+ 
//| Creating Text object                                             | 
//+------------------------------------------------------------------+ 
bool TextCreate(const long              chart_ID=0,               // chart's ID 
                const string            name="Text",              // object name 
                const int               sub_window=0,             // subwindow index 
                datetime                time=0,                   // anchor point time 
                double                  price=0,                  // anchor point price 
                const string            text=" ",                 // the text itself 
                const string            font="Arial",             // font 
                const int               font_size=9,              // font size 
                const color             clr=clrGold,              // color 
                const double            angle=0.0,                // text slope 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_LOWER, // anchor type 
                const bool              back=false,               // in the background 
                const bool              selection=false,          // highlight to move 
                const bool              hidden=true,              // hidden in the object list 
                const long              z_order=0)                // priority for mouse click 
  { 
   //--- set anchor point coordinates if they are not set 
   ChangeTextEmptyPoint(time,price); 
   //--- reset the error value 
   ResetLastError(); 
   //--- create Text object 
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create \"Text\" object! Error code = ",GetLastError()); 
      return(false); 
     } 
   //--- set the text 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
   //--- set text font 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
   //--- set font size 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
   //--- set the slope angle of the text 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle); 
   //--- set anchor type 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor); 
   //--- set color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
   //--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
   //--- enable (true) or disable (false) the mode of moving the object by mouse 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
   //--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
   //--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
   //--- successful execution 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Move the anchor point                                            | 
//+------------------------------------------------------------------+ 
bool TextMove(const long   chart_ID=0,  // chart's ID 
              const string name="Text", // object name 
              datetime     time=0,      // anchor point time coordinate 
              double       price=0)     // anchor point price coordinate 
  { 
   //--- if point position is not set, move it to the current bar having Bid price 
   if(!time) 
      time=TimeCurrent(); 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
   //--- reset the error value 
   ResetLastError(); 
   //--- move the anchor point 
   if(!ObjectMove(chart_ID,name,0,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to move the anchor point! Error code = ",GetLastError()); 
      return(false); 
     } 
   //--- successful execution 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Change the object text                                           | 
//+------------------------------------------------------------------+ 
bool TextChange(const long   chart_ID=0,  // chart's ID 
                const string name="Text", // object name 
                const string text="Text") // text 
  { 
   //--- reset the error value 
   ResetLastError(); 
   //--- change object text 
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text)) 
     { 
      Print(__FUNCTION__, 
            ": failed to change the text! Error code = ",GetLastError()); 
      return(false); 
     } 
   //--- successful execution 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Delete Text object                                               | 
//+------------------------------------------------------------------+ 
bool TextDelete(const long   chart_ID=0,  // chart's ID 
                const string name="Text") // object name 
  { 
   //--- reset the error value 
   ResetLastError(); 
   //--- delete the object 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": failed to delete \"Text\" object! Error code = ",GetLastError()); 
      return(false); 
     } 
   //--- successful execution 
   return(true); 
  }
//+------------------------------------------------------------------+ 
//| Check anchor point values and set default values                 | 
//| for empty ones                                                   | 
//+------------------------------------------------------------------+ 
void ChangeTextEmptyPoint(datetime &time,double &price) 
  { 
   //--- if the point's time is not set, it will be on the current bar 
   if(!time) 
      time=TimeCurrent(); 
   //--- if the point's price is not set, it will have Bid value 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
  }