//+------------------------------------------------------------------+
//|                                              LarryWilliamsEA.mq5 |
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




void OnTick()
  {
   MqlRates PriceInformation[];
   ArraySetAsSeries(PriceInformation,true);
   //EMA Low
   int Data = CopyRates(_Symbol,PERIOD_D1,0,3,PriceInformation);
   double MovingAverageArray[];
   int MovingAverageDefinition = iDEMA(_Symbol,PERIOD_D1,10,0,PRICE_LOW);
   ArraySetAsSeries(MovingAverageArray,true);
   CopyBuffer(MovingAverageDefinition,0,0,3,MovingAverageArray);
   
   //Extractor
   double MovingAverageValueLow = MovingAverageArray[1];
   
   
   //EMA High
   Data = CopyRates(_Symbol,PERIOD_D1,0,3,PriceInformation);
   MovingAverageDefinition = iDEMA(_Symbol,PERIOD_D1,10,0,PRICE_HIGH);
   ArraySetAsSeries(MovingAverageArray,true);
   CopyBuffer(MovingAverageDefinition,0,0,3,MovingAverageArray);
   
   //Extractor
   double MovingAverageValueHigh = MovingAverageArray[1];
   
   //ATR
   double PriceArray[];
   int AverageTrueRange = iATR(_Symbol,PERIOD_H4,15);
   ArraySetAsSeries(PriceArray,true);
   CopyBuffer(AverageTrueRange,0,0,3,PriceArray);
   double AverageTrueRangeValue = NormalizeDouble(PriceArray[0],5);
   
   
   
   
   
   //SAR Bias
   double mySARArray[];
   int SARDefenition = iSAR(_Symbol,PERIOD_D1,0.02,0.2);
   ArraySetAsSeries(mySARArray,true); 
   CopyBuffer(SARDefenition,0,0,3,mySARArray);
   
   //Extract
   double SARValue = NormalizeDouble(mySARArray[0],5);
   
   
   //Open Trades
   int PositionsForThisCurrencyPair=0;
   for(int i=PositionsTotal()-1; i>0; i--)
   {
   string symbol=PositionGetSymbol(i);
   if (Symbol()==symbol){
   PositionsForThisCurrencyPair+=1; }
   }

   int MaxTradesAllowed = 0;
   
   //Executuon Method
   MqlTick Latest_Price; // Structure to get the latest prices      
   SymbolInfoTick(Symbol() ,Latest_Price); // Assign current prices to structure 
   string Direction;
   bool NotTraded;
   
   int CurrentPeroid;
   int LookBackPeroid;
   if (IsNewCandle() == true){
   
      LookBackPeroid +=1;
   }
   
   
   Comment(CurrentPeroid);
   
   if(LookBackPeroid > CurrentPeroid){
      NotTraded = true;
   }
   
   
   
   
   if(NotTraded == true){

   //Buy Model
   if(Latest_Price.bid > SARValue){
   Direction = "Bullish";
   
   //Risk Management
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double DynamicPositionSize= NormalizeDouble((Equity/10000),1);
   
   
   //Stop Loss Creation
   double Stoploss = Latest_Price.ask - AverageTrueRangeValue;
   Stoploss = Latest_Price.bid - Stoploss;
   Stoploss = Latest_Price.ask - Stoploss;
   
   //Conversion
   DoubleToString(Stoploss);
   Stoploss = StringSubstr(Stoploss,0,6);
   Stoploss = StringToDouble(Stoploss);
   
   
   
  
   
   if(PositionsForThisCurrencyPair <= MaxTradesAllowed){
   //Execution
   if(MovingAverageValueLow > PriceInformation[0].low){
   Trade.Buy(DynamicPositionSize,NULL,0,Stoploss,MovingAverageValueHigh,"Lowerband hit");
   NotTraded = false;
   CurrentPeroid = LookBackPeroid + 1;
   }
   }
   }
   

   
   //Sell Model
   if(Latest_Price.bid < SARValue){
   Direction = "Bearish";
   
   //Risk Management
   double Equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double DynamicPositionSize= NormalizeDouble((Equity/10000),1);
   
   
   //Stop Loss Creation
   double Stoploss = Latest_Price.ask - AverageTrueRangeValue;
   Stoploss = Latest_Price.bid - Stoploss;
   Stoploss = Latest_Price.ask + Stoploss;
   
   //Conversion
   DoubleToString(Stoploss);
   Stoploss = StringSubstr(Stoploss,0,6);
   Stoploss = StringToDouble(Stoploss);
   
   
   
  
   
   if(PositionsForThisCurrencyPair <= MaxTradesAllowed){
   //Execution
   if(MovingAverageValueHigh < PriceInformation[0].high){
   Trade.Sell(DynamicPositionSize,NULL,0,Stoploss,MovingAverageValueLow,"Lowerband hit");
   NotTraded = false;
   CurrentPeroid = LookBackPeroid + 1;
   }
   }
   }
   }
   
   
   //Comment(Direction);
   
   }
   
   
   
 
//+------------------------------------------------------------------+

bool IsNewCandle(void)
  {
   static datetime t_bar=iTime(_Symbol,PERIOD_D1,0);
   datetime time=iTime(_Symbol,PERIOD_D1,0);
//---
   if(t_bar==time)
      return false;
   t_bar=time;
//---
   return true;
  }