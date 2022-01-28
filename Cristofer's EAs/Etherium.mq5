//+------------------------------------------------------------------+
//|                                                     Etherium.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
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



#include <Trade\Trade.mqh>
CTrade Trade;

bool AllowedLong = true;
bool AllowedShort = true;
double LotSize = 0;
double pips = 0.00010;;

input double RiskReward = 1;


void OnTick()
  {
   MqlRates PriceInformation[];
   ArraySetAsSeries(PriceInformation,true);
   
   
   double ticksize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   if (ticksize == 0.00001 || ticksize == 0.001){
   pips=0.00010;
   }
   //else{
   //pips = ticksize;
   //}
   
   
   
   //                            200 EMA Peroid
   //============================================================================
   // Used for generating the moving average
   
   
   //EMA Low
   int Data = CopyRates(_Symbol,PERIOD_H1,0,3,PriceInformation);
   double MovingAverageArray[];
   int MovingAverageDefinition = iDEMA(_Symbol,PERIOD_H1,200,0,PRICE_CLOSE);
   ArraySetAsSeries(MovingAverageArray,true);
   CopyBuffer(MovingAverageDefinition,0,0,3,MovingAverageArray);

   //Extractor
   double MovingAverage = MovingAverageArray[1];

     

   //                          Parabolic Sars
   //============================================================================
   // Used for getting stoploss
   double mySARArray[];
   int SARDefenition = iSAR(_Symbol,PERIOD_CURRENT,0.02,0.2);
   ArraySetAsSeries(mySARArray,true); 
   CopyBuffer(SARDefenition,0,0,3,mySARArray);
   
   //Extractor
   double SARValue = NormalizeDouble(mySARArray[0],5);
   
   

   //                          Market Direction
   //============================================================================
   // Used for updating direction
   
     string MarketDirection;
     bool ConfirmedDirection;
    
     if(PriceInformation[1].close > MovingAverage){
        
        MarketDirection = "Bullish"; 
        //Confirm Trend with indicator
        if(SARValue > MovingAverage && SARValue < PriceInformation[0].close){
        ConfirmedDirection = true;
        } 
        if(SARValue < MovingAverage || SARValue > PriceInformation[0].close){
        ConfirmedDirection = false;
        }    
     }
     
     if(PriceInformation[1].close < MovingAverage){
     //Confirm Trend with indicator
     MarketDirection = "Bearish"; 
        if(SARValue < MovingAverage && SARValue > PriceInformation[0].close){
        ConfirmedDirection = true;
        } 
        if(SARValue > MovingAverage || SARValue < PriceInformation[0].close){
        ConfirmedDirection = false;
       }
     }
    
    
    //                          Check if Trading allowed.
   //============================================================================   
   
   int PostionsForThisPair=0;
   for(int i = PositionsTotal()-1; i>=0; i--){
   string symbol = PositionGetSymbol(i);
   if (Symbol()==symbol){
   PostionsForThisPair +=1;
   }
   }
  
 
   
    //                             Pre Execution Conditioner
   //============================================================================
   
   if(MarketDirection == "Bullish" && SARValue > PriceInformation[0].close){
   AllowedLong = true;
   }
   if(MarketDirection == "Bearish" && SARValue < PriceInformation[0].close){
   AllowedShort = true;
   }
   
    
    //                              Execute Trading
   //============================================================================   
   
   
   if (PostionsForThisPair == 0){
   if(MarketDirection == "Bullish" && ConfirmedDirection == true && CheckEntry() == "Buy" && AllowedLong==true){

   //Take Profit Calculations
   MqlTick Latest_Price; 
   SymbolInfoTick(Symbol() ,Latest_Price); 
   double TakeProfit = Latest_Price.bid - SARValue;
   
   

   //Risk Management
   double StoplossInPips = Latest_Price.ask-SARValue;
   TakeProfit = Latest_Price.ask + TakeProfit*RiskReward;
   StoplossInPips = DoubleToString(StoplossInPips,5);
   StoplossInPips = StringToDouble(StoplossInPips);
   double Equity = AccountInfoDouble(ACCOUNT_BALANCE);
   double RiskedAmount = Equity*0.01;
   double LotSize = (RiskedAmount/(StoplossInPips/pips))/10;
   LotSize = DoubleToString(LotSize,2);
   LotSize = StringToDouble(LotSize);
   Print(LotSize," ",StoplossInPips, " ",pips," ",RiskedAmount," ",SARValue);
   
   Trade.Buy(LotSize,NULL,0,SARValue,TakeProfit,NULL);                                                
   AllowedLong = false;
   
    
   }
   if(MarketDirection == "Bearish" && ConfirmedDirection == true && CheckEntry() == "Sell" && AllowedShort==true){
   
   //Take Profit Calculation
   MqlTick Latest_Price; 
   SymbolInfoTick(Symbol() ,Latest_Price); 
   double TakeProfit = Latest_Price.bid - SARValue;
   
   //Risk Management
   double StoplossInPips = SARValue - Latest_Price.bid;
   TakeProfit = Latest_Price.bid + TakeProfit*RiskReward;
   StoplossInPips = DoubleToString(StoplossInPips,5);
   StoplossInPips = StringToDouble(StoplossInPips);
   double Equity = AccountInfoDouble(ACCOUNT_BALANCE);
   double RiskedAmount = Equity*0.01;
   double LotSize = (RiskedAmount/(StoplossInPips/pips))/10;
   LotSize = DoubleToString(LotSize,2);
   LotSize = StringToDouble(LotSize);
   Print(LotSize," ",StoplossInPips, " ",pips," ",RiskedAmount," ",SARValue);
   
  
   Trade.Sell(LotSize,NULL,0,SARValue,TakeProfit,NULL);                                                 
   AllowedShort = false;
    
   }
   }
   
   
   
   

   //      Display Text
   //==========================
   MessageBaord(MarketDirection,ConfirmedDirection,CheckEntry(),AllowedShort,AllowedLong);
   
   
  }
//+------------------------------------------------------------------+





string MessageBaord(string text01,string text02,string text03,string text04,string text05){
   Comment("Bias: ",text01," Confirmation: ",text02," Entry: ",text03," Allowed_Shorts: ",text04," Allowed_Longs: ",text05);
   return NULL;
}


string CheckEntry(){
   string Signal="";
   
   //MACD Histogram
   double PriceArray[];
   double MacDHistogram = iMACD(_Symbol,PERIOD_H1,12,26,9,PRICE_CLOSE);
   ArraySetAsSeries(PriceArray,true);
   CopyBuffer(MacDHistogram,0,0,3,PriceArray);
   
   //exctractor
   double MACDValue = (PriceArray[0]);
   double MACDLine[];
   CopyBuffer(MacDHistogram,MAIN_LINE,1,2,MACDLine);
   
   double SignalLine[];
   CopyBuffer(MacDHistogram,SIGNAL_LINE,1,2,SignalLine);
 

   //conditions
   if (MACDLine[1]<SignalLine[1]){
   Signal = "Sell";
   }
   if (MACDLine[1]>SignalLine[1]){
   Signal = "Buy";
   }
   
   return Signal;
}



