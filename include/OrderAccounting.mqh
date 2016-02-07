//+------------------------------------------------------------------+
//|                                              OrderAccounting.mqh |
//|                                                   Vermeir Jellen |
//|                                           jellenvermeir@gmail.com|
//+------------------------------------------------------------------+
#property copyright "Vermeir Jellen"
//----------- Variables for OrderAccounting.mqh ---------------------//
int currentPart=1;
int 
   newLevel,            // New value of the minimum distance
   oldLevel,            // Previous value of the minimum distance
   newFreeze,           // New value of the freeze level
   oldFreeze,           // Old value of the freeze level
   spreadBA,            // Value of spread
   orderParts,          // An order can consist of more than 1 part, if necessary
   nrOrdersPerType[6],  // Order type array
                        // [] order type: 0=B,1=S,2=BL,3=SL,4=BS,5=SS
   nrOrders,
   nrOldOrders;
   
double
   newOrders[250][13],   // Current order array (max simultaneous open orders = 250)
   oldOrders[250][13];   // Old order array
                        // [][0] order open price (abs. price value)
                        // [][1] StopLoss of the order (abs. price value)
                        // [][2] TakeProfit of the first order, 0 if not present
                        // [][3] order number        
                        // [][4] order volume (abs. price value)
                        // [][5] order type 0=B,1=S,2=BL,3=SL,4=BS,5=SS
                        // [][6] Order magic number (if our EA: MN == EAUniqueID
                        // [][7] 0/1 the fact of availability of comments
                        // [][8] Identifier for orders that consist of more than one part
                        // [][9] Expiration
                        // [][10] Order profit
                        // [][11] Order Commission
                        // [][12] Order Swap
//--------------------------------------------------------------------//

void initOrderAccounting()
{
	nrOrders = 0;
	nrOldOrders = 0;
	orderParts = 1;
	ArrayInitialize(nrOrdersPerType,0);
	ArrayInitialize(oldOrders,0);
	ArrayInitialize(newOrders,0);
}

void orderAccounting()
{
      int count=0;                           
      ArrayCopy(oldOrders,newOrders); 
      ArrayInitialize(newOrders,0);     
      ArrayInitialize(nrOrdersPerType,0);      
      nrOldOrders = nrOrders;
      for(int i=0; i<OrdersTotal(); i++) // For market and pending orders
      {
         if(OrderSelect(i,SELECT_BY_POS) && OrderMagicNumber()==EAUniqueID)          
         {
            newOrders[count][0]=OrderOpenPrice();    
            newOrders[count][1]=OrderStopLoss();     
            newOrders[count][2]=OrderTakeProfit();    
            newOrders[count][3]=OrderTicket();       
            newOrders[count][4]=OrderLots();        
            nrOrdersPerType[OrderType()]++;                  
            newOrders[count][5]=OrderType();         
            newOrders[count][6]=OrderMagicNumber();  
            if(OrderComment()=="")
               newOrders[count][7]=0;               
            else
               newOrders[count][7]=1;               
            if(orderParts>1)
               newOrders[count][8]=getOrderPart(count);
            else
               newOrders[count][8]=1;
            newOrders[count][9] = OrderExpiration();
            newOrders[count][10] = OrderProfit();
            newOrders[count][11] = OrderCommission();
            newOrders[count][12] = OrderSwap();
            count++;                                 
         }
      }
      nrOrders=count;                        
}

int getOrderPart(int index)
{
   for(int i=0;i<nrOldOrders;i++)
   {
      if(oldOrders[i][3]==newOrders[index][3] || checkReopenedOrPartlyClosed(i,index))
         return(oldOrders[i][8]);  // Existing order*/
   }
   return(currentPart);  // New order: currentPart
}

//------------------------------------------- Public functions
void setCurrentOrderPart(int partNr)
{
   currentPart = partNr;
}

bool openTrade()
{
   if(nrOrders>0)
      return(true);
   return(false);
}

int openMarketOrders()
{
   return(nrOrdersPerType[OP_BUY]+nrOrdersPerType[OP_SELL]);
}

int openPendingOrders()
{
   return(nrOrdersPerType[OP_BUYLIMIT]+nrOrdersPerType[OP_BUYSTOP]+nrOrdersPerType[OP_SELLLIMIT]+nrOrdersPerType[OP_SELLSTOP]);
}

int openBuyOrders()
{
   return(nrOrdersPerType[OP_BUY]);
}

int openSellOrders()
{
   return(nrOrdersPerType[OP_SELL]);
}

bool lastTradeLost()
{
   int numberHistory=OrdersHistoryTotal();
   if(numberHistory>0)
   {
      while(numberHistory>=0)
      {
         numberHistory-=1;
         if(OrderSelect(numberHistory,SELECT_BY_POS,MODE_HISTORY) && OrderMagicNumber()==EAUniqueID)
         {
            if(OrderProfit()<0)
               return(true);
         }
      }
   }
   return(false);
}