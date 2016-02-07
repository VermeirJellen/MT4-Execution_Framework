//+------------------------------------------------------------------+
//|                                                   MomentumEA.mq4 |
//|                                                   Vermeir Jellen |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright Jellen Vermeir"
//------------------ General Settings -----------------------------------------------|
extern string frameworkSpecific = "*** EXTRA functionality and restrictions ***";
extern string EAName = "EAName";

extern string uniqueId = "*** Unique ID of this EA (Used for order accounting) ***";
extern int EAUniqueID = 125478; // Unique ID for this EA

extern string slippageInfo = "*** Enter the maximum amount of allowed slippage for trade placement ***";              
extern int allowedSlippage = 20;  

extern string ecnBroker = "*** Enter true if your broker is an ECN-type broker ***";
extern bool isECN = true;

extern string evaluation = "*** set true to perform trading logic only at opening of a new  bar ***";
extern bool evaluateAtOpen = false;
//-----------------------------------------------------------------------------------|

#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//----------------------------------------------------------------------------------------
#include <Inform.mqh>             // Information for users
#include <OrderAccounting.mqh>    // Order accounting
#include <Events.mqh>             // Event tracking functions
#include <Trade.mqh>              // Trade execution functions

#include <TradeLogger.mqh>
#include <TradingCriterionMomentumEA.mqh>  // Trading criterion for this EA
//----------------------------------------------------------------------------------------

int init()                             
{
   initInformation();             // Init information Module
   initOrderAccounting();         // Init OrderAccounting Module
   initEvents();                  // Init Event Module
   initTradingModule();           // Initialize trading criterion parameters
   
   initTradeLogger();
   
   return(0);
}

//----------------------------------------------------------------------------------------
int start()                        
{
   // Perform logic every new tick or every new bar (depending on settings)
   if(!evaluateAtOpen || (evaluateAtOpen && newBar()))
   {
      orderAccounting();
      tradingConditionEvents();                       
      trade(criterion());       
      inform(0);
   }
   tradeLogger();
   
   return(0);
}  

int deinit()                      
{
   orderAccounting();
   deinitTradingModule();
   inform(-1); 
   
   deinitTradeLogger();      
    
   return(0);                       
}

bool newBar()
{
   static datetime latestBar = 0;
   if(Time[0] != latestBar)
   {
      latestBar = Time[0];
      return(true);
   }  
   return(false);
}