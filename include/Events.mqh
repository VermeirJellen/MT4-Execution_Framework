//+------------------------------------------------------------------+
//|                                                      Events .mqh |
//|                                                   Vermeir Jellen |
//|                                           jellenvermeir@gmail.com|
//+------------------------------------------------------------------+
#property copyright "Vermeir Jellen"
//------------------------- Variables for Events.mqh ---------------------|
extern string explanationEvents = "*** Variables for Events ***";
extern string explanationCheckEvents = "*** Set true if events need to be printed ***";
extern bool checkEvents = true;
//------------------------------------------------------------------------|

// Update stoplevels and freeze levels
void tradingConditionEvents()
{
	newLevel=MarketInfo(Symbol(),MODE_STOPLEVEL); // Last known mindistance
   newFreeze=MarketInfo(Symbol(),MODE_FREEZELEVEL);
   spreadBA=MarketInfo(Symbol(),MODE_SPREAD);
   if (oldLevel!=newLevel)          
   {                                   
      oldLevel=newLevel;                 // New "old value"
      inform(10,newLevel);               // Message: new distance
   }
   if(oldFreeze!=newFreeze)
   {
      oldFreeze=newFreeze;
      inform(28,newFreeze);
   }
}

void orderEvents()
{
	if(checkEvents)
	{
		checkModifiedOrders();
		checkNewOrders();
	}
}

//---------------------------------------------------------------------
void checkModifiedOrders()
{
   bool match;                           
   // Searching for lost, type-changed, partly closed and reopened orders   
   for(int old=0; old<nrOldOrders; old++)
   { 
      match=false;
      for(int neww=0; neww<nrOrders; neww++)
      {
         if(checkTypeChanged(old, neww)) // Search for type changed orders
         {
            match=true; break;
         }
         if(checkReopenedOrPartlyClosed(old, neww)) // Search for reopened or partly closed orders
         {
            match=true; break;
         }                               
      }
      if (!match)               // Order was not found (closed)
         checkClosedOrder(old);     
    }
}

bool checkTypeChanged(int old, int neww)
{
   if (oldOrders[old][3]==newOrders[neww][3]) // Same ticket
   {                              
      if (newOrders[neww][5]!= oldOrders[old][5]) // Type changed?
         inform(7, newOrders[neww][3]);
      return(true);                     
   }
   return(false);
}

bool checkReopenedOrPartlyClosed(int old, int neww) 
{
   
   if (newOrders[neww][7]>0) // Check for ordercomment
                            // Server places old ticketnumber in comment when reopened or partly closed
   {
      OrderSelect(newOrders[neww][3], SELECT_BY_TICKET);                    //get comment
      if(StringFind(OrderComment(), DoubleToStr(oldOrders[old][3],0))!=-1) //try to find old ticketnumber in comment
      {
         if (oldOrders[old][4]==newOrders[neww][4])  // Same volume
            inform(8,oldOrders[old][3]);            // REOPENED (broker glitch)
         else                           
            inform(9,oldOrders[old][3]);            // PARTLY CLOSED
         return(true);
      }                                 
   }
   return(false);
}

void checkClosedOrder(int old)
{
   if (oldOrders[old][5]==0)
      inform(1, oldOrders[old][3]);  // Order Buy closed
   if (oldOrders[old][5]==1)
      inform(2, oldOrders[old][3]);  // Order Sell closed
   if (oldOrders[old][5]> 1)
      inform(3, oldOrders[old][3]);  // Pending order deleted
}


void checkNewOrders()
{
   for(int neww=0;neww<nrOrders;neww++)
   {
      // Ordercomment: reopened or partly closed order (not new)
      if (newOrders[neww][7]>0)
         continue;
         
      bool match=false;                
      for(int old=0;old<nrOldOrders;old++)       
      {                                 
         if (newOrders[neww][3]==oldOrders[old][3])   
         {                                         
            match=true;                      
            break;
         }                                
      }
      if (!match)                         
      {                                  
         if (newOrders[neww][5]==0)
            inform(4, newOrders[neww][3]); // Inform order Buy opened
         if (newOrders[neww][5]==1)
            inform(5, newOrders[neww][3]); // Inform order Sell opened
         if (newOrders[neww][5]> 1)
            inform(6, newOrders[neww][3]); // Inform Pending order placed
      }
   }
}

void initEvents()
{
   oldLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);   // Set initial minimum distance
   oldFreeze = MarketInfo(Symbol(), MODE_FREEZELEVEL); // Set initial freezelevel
   spreadBA = MarketInfo(Symbol(), MODE_SPREAD);
   Print("Current bid ask Spread: ", DoubleToStr(spreadBA,Digits));
   Print("Current minimum distance: ", DoubleToStr(oldLevel,Digits));
   Print("Current freezelevel: ", DoubleToStr(oldFreeze,Digits));
}