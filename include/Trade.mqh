//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                                   Vermeir Jellen |
//|                                           jellenvermeir@gmail.com|
//+------------------------------------------------------------------+
#property copyright "Vermeir Jellen"
#define TRADE_OPERATION_OK 0
#define TRADE_OPERATION_RETRY 1
#define TRADE_OPERATION_HALT 2

#define CLOSE_ALL_ORDERS 8

int lastOpenedTicketNr;

int trade(int operation)
{
   if(operation==-2) // Do nothing
      return(0);
   if(operation==-1)
      manageOpenOrders();
   else
      openOrderByType(operation);
   return(0);
}

void openOrderByType(int operation)
{
   inform(1,0,0, "Order request.. " + operation);
   for(int part=0;part<orderParts;part++)
   {
      bool orderOpened=false; int retryCounter=0;
      
      //------------------------------------ Try to place an orderPart ----------------//
      while(!orderOpened)
      {
         orderOpened=true;
         
         double step = MarketInfo(Symbol(),MODE_LOTSTEP);
         double newLots = MathFloor(getInitialLotsize(operation,part+1)/step)*step;
         if(!volumeCheck(newLots))
            break;
         
         double price = NormalizeDouble(getInitialOpeningPrice(operation, part+1),Digits);      
         double stoploss = NormalizeDouble(getInitialStoplossLevel(operation, part+1),Digits);
         double takeProfit = NormalizeDouble(getInitialTakeProfitLevel(operation, part+1),Digits);
         datetime expiration = getInitialExpirationDate(operation, part+1);
         
         //Print("Price: ", DoubleToStr(price,Digits));
         //Print("Stoploss: ", DoubleToStr(stoploss,Digits));
         //Print("takeProfit: ", DoubleToStr(takeProfit,Digits));
         
         setCurrentOrderPart(part+1);
         int tradeResult=TRADE_OPERATION_HALT;
         
         //------------------------------------ Open orderfor non ECN-type broker ----------------//
         if(!isECN)  // Place order plus SL/TP
            tradeResult=openOrder(operation,newLots,price,stoploss,takeProfit,expiration);
            
         //------------------------------------ Open order for ECN-type broker --------------------//
         else        // Place order without SL/TP and add SL/TP through modification
         {
            tradeResult=openOrder(operation,newLots,price,0,0,expiration);
            if(tradeResult==TRADE_OPERATION_OK)     // Trade without SL/TP placed succesfully
            {
               bool modificationOk=false; int retryCounterECN=0;
               while(!modificationOk)     // Modify: add the SL/TP
               {
                  modificationOk=true;
                  tradeResult=modifyOrder(lastOpenedTicketNr,price,stoploss,takeProfit,expiration);
                  
                  if(tradeResult==TRADE_OPERATION_RETRY)  // Retry modification
                  {
                     if(retryCounterECN<3) // Retry the modification of the order
                        modificationOk=false;
                     else                 // Cancel the order   
                     {
                        inform(15,999);
                        tradeResult=TRADE_OPERATION_HALT;
                     }
                     retryCounterECN+=1;
                  }
                  
                  if(tradeResult==TRADE_OPERATION_HALT)   // Modification failed
                  {
                     //inform(27,lastOpenedTicketNr);         // Could not add SL/TP. Delete original order
                     bool deleteOk=false;
                     while(!deleteOk)
                     {
                        deleteOk=true;
                        tradeResult=closeOrDeleteOrder(operation,lastOpenedTicketNr,newLots);
                        if(tradeResult==TRADE_OPERATION_RETRY)  // Retry removing the original order, ad infinum
                           deleteOk=false;
                        if(tradeResult==TRADE_OPERATION_HALT)   // Critical: could not remove original order without SL/TP
                           inform(23,lastOpenedTicketNr);
                     }
                  }
               }
            }
         }
         
         //------------------------------------- Retry placement of trade if necessary ------------//
         if(tradeResult==TRADE_OPERATION_RETRY)
         {
            if(retryCounter<3)
               orderOpened=false;  
            else
            {
               inform(15,999);             
               tradeResult=TRADE_OPERATION_HALT;
            }
            retryCounter+=1;
         }   
         if(tradeResult==TRADE_OPERATION_HALT)   // Critical error: break
		 {
			inform(1,0,0, "Trade operation halt");
            break;
		 }
      }
   }                         
   return;
}


void manageOpenOrders()
{
   double oldPrice, oldTakeProfit, oldStoploss, oldLots;
   datetime oldExpirationDate;
   double newPrice, newTakeProfit, newStoploss, newLots;
   datetime newExpirationDate;
   
   int operation, ticket;

   for(int i=0; i<nrOrders;i++)
   {
      bool orderManaged=false; int retryCounter=0;
      while(!orderManaged)
      {
         orderManaged=true;
         int result=TRADE_OPERATION_HALT;
         
         operation = newOrders[i][5];
         ticket = newOrders[i][3];
         newLots = newOrders[i][4];
      
         if(closePosition(i))
            result = closeOrDeleteOrder(operation,ticket,newLots);
         else
         { 
            double step = MarketInfo(Symbol(),MODE_LOTSTEP);
            oldPrice = NormalizeDouble(newOrders[i][0],Digits);
            oldTakeProfit = NormalizeDouble(newOrders[i][2],Digits);
            oldStoploss = NormalizeDouble(newOrders[i][1],Digits);
            oldLots = MathFloor(newOrders[i][4]/step)*step;
            oldExpirationDate = newOrders[i][9];
      
            newPrice = NormalizeDouble(getNewOpeningPrice(i),Digits);
            newStoploss = NormalizeDouble(getNewStoplossLevel(i), Digits);
            newTakeProfit = NormalizeDouble(getNewTakeProfitLevel(i), Digits);
            newLots = MathFloor(getNewLotsize(i)/step)*step;
            newExpirationDate = getNewExpirationDate(i);
      
            if(oldPrice!=newPrice || oldTakeProfit!=newTakeProfit 
               || oldStoploss!=newStoploss || oldExpirationDate!=newExpirationDate)
            {
               result = modifyOrder(ticket,newPrice, newStoploss, newTakeProfit, newExpirationDate);
            }
            if(oldLots>newLots)  // Partly close order
            {
               double closingPrice = Bid;
               if(operation==OP_SELL)
                  closingPrice=Ask;
               if(oldLots-newLots >= MarketInfo(Symbol(),MODE_MINLOT))
                  result = closeOrder(ticket,oldLots-newLots,closingPrice);
               else
                  result = closeOrder(ticket,oldLots,closingPrice);
            }
         }
         
         if(result==TRADE_OPERATION_RETRY)
         {
            if(retryCounter < 3)
               orderManaged=false;
            else
            {
               inform(15,999);
               result=TRADE_OPERATION_HALT;
            }
            retryCounter+=1;
         }
		 
		 if(result==TRADE_OPERATION_HALT)
		 {
			break;
		 }
      }  
   }
}
 
int closeOrDeleteOrder(int operation,int ticketNr,double lotSize)
{
   if(operation==OP_BUY ||operation==OP_SELL)
   { 
      double closingPrice = Bid;
      if(operation==OP_SELL)
         closingPrice = Ask;
      return(closeOrder(ticketNr,lotSize,closingPrice));
   }
   else
      return(deleteOrder(ticketNr));
}

//****************************************************************************************************************//
//********************************************* Basic Trading Functionality **************************************//
//****************************************************************************************************************//

int openOrder(int operation, double newLots, double price, double stoploss, double takeProfit, datetime expiration)
{
   inform(13,operation);
   lastOpenedTicketNr=OrderSend(Symbol(),operation,newLots,price,allowedSlippage,stoploss,takeProfit,"",EAUniqueID,expiration);
   if(lastOpenedTicketNr<0)
   {
      if(handleErrors(GetLastError())==false)   // Check for critical error
         return(TRADE_OPERATION_HALT);
      return(TRADE_OPERATION_RETRY);
   }
   orderAccounting();
   orderEvents();
   return(TRADE_OPERATION_OK);
}
  

bool closeOrder(int ticketNr, double lotSize, double closingPrice)
{
   inform(12,ticketNr);
   if(!OrderClose(ticketNr,lotSize,closingPrice,allowedSlippage))
   {
      if(handleErrors(GetLastError())==false)
         return(TRADE_OPERATION_HALT);
      return(TRADE_OPERATION_RETRY);
   }
   orderAccounting();
   orderEvents();
   return(TRADE_OPERATION_OK);
}

bool deleteOrder(int ticketNr)
{
   inform(22,ticketNr);
   if(!OrderDelete(ticketNr))
   {
      if(handleErrors(GetLastError())==false)
         return(TRADE_OPERATION_HALT);
      return(TRADE_OPERATION_RETRY);
   }
   orderAccounting();
   orderEvents();
   return(TRADE_OPERATION_OK);
}

bool modifyOrder(int ticketNr,double newPrice,double newStoploss,double newTakeProfit,datetime newExpirationDate)
{
   inform(19,ticketNr);
   if(!OrderModify(ticketNr, newPrice, newStoploss, newTakeProfit, newExpirationDate))          
   {                               
      if(handleErrors(GetLastError())==false)
         return(TRADE_OPERATION_HALT);                
      return(TRADE_OPERATION_RETRY);
   }
   orderAccounting();
   orderEvents();
   return(TRADE_OPERATION_OK);
}

//****************************************************************************************************************//
//********************************************* Error handling ***************************************************//
//****************************************************************************************************************//

bool handleErrors(int error)                   
{
   inform(15, error);                     // Message
   switch(error)
   { 
      case 129:                           // Wrong price
      case 135:                           // Price changed
      case 138:                           // Requote
         RefreshRates();                
         return(true);                   
      case 136:                           // No quotes. Waiting for the tick to come
         while(RefreshRates()==false)    
            Sleep(1);                     
         return(true);
      case 4  :                           // Trade Server is busy                  
      case 6  :                           // No connection to the server
      case 128:                           // Trade Timeout
      case 137:                           // Broker is busy
      case 146:                           // The trade subsystem is busy
         Sleep(500);                     
         RefreshRates();                 
         return(true);                    
                                          // Critical errors:
      case 2 :                            // Common error
      case 5 :                            // Old version of the client terminal
      case 7 :                            // Not enough rights
      case 64:                            // Account blocked
      case 133:                           // Trading is prohibited
      case 141:                           // Too many requests
      case 148:                           // Too many orders
      case 0  :                           // Logical error in trading logic (Most likely..)
      default:                            // Other variants
         return(false);                   
     }
}

//***********************************************************//
// Helper functions..                                        //
//***********************************************************//
bool volumeCheck(double newLots)
{
   double minLot = MarketInfo(Symbol(),MODE_MINLOT);
   if (newLots < minLot)
   {
      inform(11,1,newLots);  // Lotsize too small!
      return(false);
   }
   
   double maxLot = MarketInfo(Symbol(),MODE_MAXLOT);   
   if (newLots > maxLot)
   {
      inform(11,2,newLots);
      return(false);
   }     
   
   double freeMargin = AccountFreeMargin();  
   double marginPerLot = MarketInfo(Symbol(),MODE_MARGINREQUIRED);          
   if (newLots*marginPerLot>freeMargin) //not enough margin
   {                                       
      inform(11,0,newLots); // Not enough money!                 
      return(false);                           
   }
   
   return(true);
}

/**
*  Check the minimum distance and the freezelevel between a baseline and the requestedlevel.
*  eg: Baseline for sell order = ASK, Baseline for buy order = BID
*  If requestedLevel too close: Return closest possible price, otherwise return requestedLevel
*/
double checkMinDistanceAndFreezeLevel(double baseline, double requestedLevel)
{
   double requiredMinOffset = MathMax(newLevel,newFreeze)*Point;
   if(baseline>requestedLevel && baseline-requiredMinOffset<requestedLevel)
   {
      Print("New level (baseline>requestedLevel)");
      return(baseline-requiredMinOffset); // RequestedLevel too close
   }
   if(baseline<requestedLevel && baseline+requiredMinOffset>requestedLevel)
   {
      Print("New level (baseline<requestedLevel");
      return(baseline+requiredMinOffset); // RequestedLevel too close
   }
      
   return(requestedLevel); // RequestedLevel OK
}