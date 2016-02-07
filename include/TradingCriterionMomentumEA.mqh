//+------------------------------------------------------------------+
//|                                   TradingCriterionMomentumEA.mqh |
//|                                                   Vermeir Jellen |
//|                                           jellenvermeir@gmail.com|
//+------------------------------------------------------------------+
#property copyright "Vermeir Jellen"

//------------ Variables for TradingCriterionMomentumEA.mqh ---------|
extern string explanationMomentumEA = "*** VARIABLES FOR TRADING MODULE ***";
extern int atrPeriod = 14;
extern double atrMultiplier = 2;
extern double takeProfitParameter = 1.5; // used when useTrail == FALSE;
extern double stoplossParameter = 1; // used when useTrail == FALSE

extern bool useTrail = true;
extern double trailParameter = 1; // used when useTrail == TRUE

int openBarCounter;
double trailing;
//-------------------------------------------------------------------|

//----------------------------------------//
// INIT / DEINIT                          //
//----------------------------------------//
void initTradingModule()
{
   // Force external framework setting 
   // (Evaluation of trading rules will only be performed one time for each new bar)
   evaluateAtOpen = TRUE; 
   
   // This variable keeps track on how long the active trade has been opened
   openBarCounter = 0;
   // Trailling stop.. used when useTrail == TRUE
   trailing = 0; // recalculated as a function of the recent price movement and the 'trailParameter'
}

void deinitTradingModule(){}

//----------------------------------------//
// TRADING LOGIC - Check entry conditions //
//----------------------------------------//
int criterion()                   
{   
   if(!openTrade()) // Check if EA already has active trade (orderaccounting functionality)
   { // if no open trade, check entry conditions
     openBarCounter=0; trailing=0;
	  if(longCriterion()){ trailing = NormalizeDouble((Close[1]-Open[1])*trailParameter,Digits); openBarCounter=0; return(OP_BUY); }
	  if(shortCriterion()){ trailing = NormalizeDouble((Open[1]-Close[1])*trailParameter,Digits); openBarCounter=0; return(OP_SELL); }
   }
   else // count the number of bars that the current active trade is in effect
      openBarCounter += 1;
      
	return(-1); // No trading signal
}

/**
* Go long when last closed bar has significant upward momentum
* Close[1] - Open[1] > atrMultiplier*ATR(atrPeriod)
*/
bool longCriterion()
{
   double momentum = Close[1]-Open[1];
	double threshold = atrMultiplier*iATR(Symbol(),0,atrPeriod,2);
	if(momentum > threshold)
	  return(true);
	return(false);
}

/**
* Go short when last closed bar has significant downward momentum
* Open[1] - Close[1] > atrMultiplier*ATR(atrPeriod)
*/
bool shortCriterion()
{
   double momentum = Open[1]-Close[1];
	double threshold = atrMultiplier*iATR(Symbol(),0,atrPeriod,2);
	if(momentum > threshold)
      return(true);
	return(false);
}


//---------------------------------------------------------------//
// TRADING LOGIC - ORDER INFORMATION:                            //
// These functions are called to request                         //
// order information immediately after a succesful entry trigger //
//---------------------------------------------------------------//
double getInitialStoplossLevel(int operation, int part)
{
   double multiplier = stoplossParameter;
   if(useTrail)
      multiplier = trailParameter;
   double allowedLoss = NormalizeDouble(MathAbs(Close[1]-Open[1])*multiplier,Digits);
   
	if(operation == OP_BUY)
	  return(Bid-allowedLoss);
	if(operation == OP_SELL)
	  return(Ask+allowedLoss);
}
 
double getInitialTakeProfitLevel(int operation, int part) // Return takeprofitlevel for first part of order
{
	if(!useTrail)
	{ // Use fixed profit level, when no trailing stop
      double profit = NormalizeDouble(MathAbs((Close[1]-Open[1])*takeProfitParameter),Digits);
	   if(operation == OP_BUY)
	     return(Bid+profit);
	   if(operation == OP_SELL)
	     return(Ask-profit);
	}
	else // Do not use a Take Profit level when we use a trailing stop
	  return(0);
}

double getInitialOpeningPrice(int operation, int part)
{
   if(operation==OP_BUY)
      return(Ask);
   if(operation==OP_SELL)
      return(Bid);
}

/** 
* Allow two percent risk per trade
* Lotsize depends on stoploss level / amounts of points risked
*/
double getInitialLotsize(int operation, int part)
{  
   // double maxRisk = 100.0;
   double percentageRisk = 2; // risk 2% of account balance per trade
   double maxRisk = AccountBalance()*percentageRisk/100;
   
   // Get relevant multiplier
   double multiplier = stoplossParameter;
   if(useTrail)
      multiplier = trailParameter;
      
   // Calculate the amount of risk, expressed in points (including the spread)
   // Note: events.mqh keeps track of current bid ask spread (spreadBA)
   int pointsRisked = NormalizeDouble(MathAbs(Close[1]-Open[1])*multiplier,Digits)/Point+spreadBA;
   
   // calculate allowed risk amount per point movement
   double allowedRiskPerPoint = maxRisk/pointsRisked;
   // Fetch smallest allowed (fractional) lotsize
   double step = MarketInfo(Symbol(),MODE_LOTSTEP); 
   // calculate and return requested lotsize
   return(MathFloor(allowedRiskPerPoint/getPointValuePerLot()/step)*step);
}

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

// No "force close" conditions are in effect, always return false..
bool closePosition(int index){ return (false); }

/**
* Potentially update stoploss level when trade has been in effect for at least three bars
* If trailing: set SL at breakeven when in profit
* If not trailing: Recalculate trailing stop and update when it's at 
* a better profit/loss level than the previous stoploss
*/
double getNewStoplossLevel(int index)
{ 
   double currentStoploss = NormalizeDouble(newOrders[index][1],Digits);
   
   // We only check update conditions when the trade has been in effect for at least 3 bars
   if(openBarCounter >= 3)
   {
      int operation = newOrders[index][5]; 
      double openingPrice = NormalizeDouble(newOrders[index][0],Digits);
      
      // When not using a trailling stop, set stoploss at breakeven when we are currently in profit
      // (Note that we verify that stop loss is not already at breakeven to avoid repeating the functionality)
      if( !useTrail && ((operation == OP_BUY && currentStoploss < openingPrice) || (operation == OP_SELL && currentStoploss > openingPrice)) )
      {
         if(OrderProfit() > 0)
            return(openingPrice);
      }
      
      // When using a trailing stop..
      // Recalculate trailing stoploss and update if it's at a higher profit level
      if(useTrail)
      {
         if(operation == OP_BUY)
         {
            double newLow = NormalizeDouble(Bid-trailing,Digits);
            if(newLow > currentStoploss)
               return(newLow);
         }
         if(operation == OP_SELL)
         {
            double newHigh = NormalizeDouble(Ask+trailing,Digits);
            if(newHigh < currentStoploss)
               return(newHigh);
         }
      }
   }
   
   // Do not update stoploss level
   return(currentStoploss); 
}

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
double getOptimizedParameter1()
{
   if(optimizedParameter1 == "atrPeriod")
      return(atrPeriod);
   if(optimizedParameter1 == "atrMultiplier")
      return(atrMultiplier);
   if(optimizedParameter1 == "takeProfitParameter")
      return(takeProfitParameter);
   if(optimizedParameter1 == "useTrail")
      return(useTrail);
   if(optimizedParameter1 == "trailParameter")
      return(trailParameter);
    
   return(-1);
}

double getOptimizedParameter2()
{
   if(optimizedParameter2 == "atrPeriod")
      return(atrPeriod);
   if(optimizedParameter2 == "atrMultiplier")
      return(atrMultiplier);
   if(optimizedParameter2 == "takeProfitParameter")
      return(takeProfitParameter);
   if(optimizedParameter2 == "useTrail")
      return(useTrail);
   if(optimizedParameter2 == "trailParameter")
      return(trailParameter);
      
   return(-1);
}

double getPointValuePerLot()
{
   return(MarketInfo(Symbol(),MODE_TICKVALUE)/(MarketInfo(Symbol(),MODE_TICKSIZE)/MarketInfo(Symbol(),MODE_POINT)));
}
