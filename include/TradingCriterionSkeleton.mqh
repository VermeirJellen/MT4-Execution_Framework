//+------------------------------------------------------------------+
//|                                     TradingCriterionSkeleton.mqh |
//|                                                   Vermeir Jellen |
//|                                           jellenvermeir@gmail.com|
//+------------------------------------------------------------------+
#property copyright "Vermeir Jellen"

//------------ Variables for TradingCriterionSkeleton.mqh -----------|
extern string explanationDummyEA = "*** VARIABLES FOR TRADING MODULE ***";
extern int dummyExternalParam1 = 1;
extern int dummyExternalParam2 = 2;

int dummyParam;
//-------------------------------------------------------------------|

//----------------------------------------//
// INIT / DEINIT                          //
//----------------------------------------//

// Perform initialization upon startup, if necessary
void initTradingModule(){ dummyParam = 0; }
// Perform de-initilization on exit, if necessary
void deinitTradingModule(){}

//----------------------------------------//
// TRADING LOGIC - Check entry conditions //
//----------------------------------------//

// OP_BUY = 0, OP_SELL = 1, OP_BUYLIMIT = 2
// OP_SELLLIMIT = 3, OP_BUYSTOP = 4, OP_SELSTOP = 5
int criterion()                   
{   
	if(longCriterion())
		return(OP_BUY);
	if(shortCriterion())
		return(OP_SELL);
		
	return(-1); // do nothing - no signal
}

bool longCriterion(){ return(false); }
bool shortCriterion(){ return(false); }

//---------------------------------------------------------------//
// TRADING LOGIC - ORDER INFORMATION:                            //
// These functions are called to request                         //
// order information immediately after a succesful entry trigger //
//---------------------------------------------------------------//

// return intial stoplosslevel for the order
double getInitialStoplossLevel(int operation, int part){ return(0); }
// return initial take profit level for the order
double getInitialTakeProfitLevel(int operation, int part){ return(0); }
// return initial openingprice for the order
double getInitialOpeningPrice(int operation, int part)
{
   if(operation==OP_BUY)
      return(Ask);
   if(operation==OP_SELL)
      return(Bid);
      
   // if(operation==OP_BUYLIMIT){}
   // if(operation==OP_SELLLIMIT){}
   // if(operation==OP_BUYSTOP){}
   // if(operation==OP_SELLSTOP){}
   
   return(0);
}

// return initial lotsize for the order
double getInitialLotsize(int operation, int part){ return(1); }
// return expiration date for the order. (use 0, if no value)
datetime getInitialExpirationDate(int operation, int part){ return(0);}


//-------------------------------------------------------------------------//
// TRADING LOGIC - UPDATE ORDERS                                           //
// These functions are called every new tick or bar (depending on settings)//
// Relevant calls are made for all the active orders                       //
//-------------------------------------------------------------------------//

/* Framework: Individual order information can be accessed through the newOrders array
*  This array is managed by the orderAccounting module
*  newOrders[index][0]: openingPrice   
*  newOrders[index][1]: stoplossLevel    
*  newOrders[index][2]: take profit level   
*  newOrders[index][3]: ticket number       
*  newOrders[index][4]: lotsize                        
*  newOrders[index][5]: operation (type of order. 0 for buy, 1 for sell, 2 for buy limit, etc..)        
*  newOrders[index][6]: magic number (EA identifier) 
*  newOrders[index][7]: 0 if there is no ordercomment, 1 if there is a comment (comments managed by broker, do not use!)
*  newOrders[index][8]: orderPART (by default: number orderparts = 1)
*  newOrders[index][9]: Expiration
*  newOrders[index][10]: Order profit
*  newOrders[index][11]: Order Commission
*  newOrders[index][12]: Order Swap
*/

// Check potential conditions for a "force close"
bool closePosition(int index){ return (false); } // default: do not close order
// Update StopLoss levels for active orders
double getNewStoplossLevel(int index){ return(newOrders[index][1]); } // default: no update
// Update Take Profit levels for active orders
double getNewTakeProfitLevel(int index){ return(newOrders[index][2]); } // default: no update
// Update opening prices (for potential pending orders)
double getNewOpeningPrice(int index){ return(newOrders[index][0]); } // default: no update
// Update lotsizes for pending orders (or partially close open market orders)
double getNewLotsize(int index){ return(newOrders[index][4]); } // default: no update
// Update expirationdates for active orders
datetime getNewExpirationDate(int index){ return(newOrders[index][9]); } // default: no update

//--------------------------------------------------------------------------//
// TRADE LOGGING - OPTIMIZATION MODE                                        //
// When trade logging is enabled,                                           //
// make sure to optimize over a maximum of two parameters simultaneously    //
//--------------------------------------------------------------------------//
// optimizedParameter1 and optimizedParameter2 are external params of the tradelogger module
double getOptimizedParameter1()
{
   if(optimizedParameter1 == "dummyExternalParam1")
      return(dummyExternalParam1);
   if(optimizedParameter1 == "dummyExternalParam2")
      return(dummyExternalParam2);
    
   return(-1);
}

double getOptimizedParameter2()
{
   if(optimizedParameter1 == "dummyExternalParam1")
      return(dummyExternalParam1);
   if(optimizedParameter1 == "dummyExternalParam2")
      return(dummyExternalParam2);
      
   return(-1);
}

// helper function
double getPointValuePerLot()
{
   return(MarketInfo(Symbol(),MODE_TICKVALUE)/(MarketInfo(Symbol(),MODE_TICKSIZE)/MarketInfo(Symbol(),MODE_POINT)));
}