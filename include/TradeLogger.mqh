//+------------------------------------------------------------------+
//|                                                  TradeLogger.mqh |
//|                                                   Vermeir Jellen |
//|                                           jellenvermeir@gmail.com|
//+------------------------------------------------------------------+
#property copyright "Vermeir Jellen"


//---------------- Variables for Tradelogger.mqh --------------------|
extern string explanationLogging = "VARIABLES FOR TRADELOGGER MODULE";
extern bool logTrades=false; 	// set true in order to write trading information to .csv file
extern string loggingID="456";
extern string maxTradesExplanation="Enter number of maximum simultaneous trades (if unknown, set to -1)";
extern int maxNumberOfSimultaneousTrades=-1;

extern string explanationParameters="ONLY USED WHEN IN OPTIMIZATION MODE";
extern int nrOptimizedParameters=2;
extern string optimizedParameter1="parameter1";
extern string optimizedParameter2="parameter2";

double tradeData[][14]; 
						// [0] = ticketNr
						// [1] = orderOpenTime
						// [2] = OrderCloseTime
						// [3] = OrderType
						// [4] = OrderOpenPrice
						// [5] = OrderClosePrice
						// [6] = orderHighestPrice
						// [7] = orderLowestPrice
						// [8] = orderCloseProfit
						// [9] = orderHighestProfit
						// [10] = orderLowestProfit
						// [11] = orderCommission
						// [12] = orderSwap
						// [13] = orderLots

int handle; string fileName; int nrLoggedTrades;
bool fileOK;
//------------------------------------------------------------------|

//------------------------------
void initTradeLogger()
{
   if(!logTrades) 
   { 
      Print("TestLogger: Logging Disabled!"); 
      fileOK=false; 
      return; 
   }
   
   //MathSrand(TimeLocal());
   if(IsOptimization())
   { 
      double parameter1 = getOptimizedParameter1(); double parameter2 = getOptimizedParameter2();
      if(nrOptimizedParameters == 1)
      {
         if (parameter1 != -1)
         {
            fileName = StringConcatenate(EAName, "_", "ID-", loggingID, "_", optimizedParameter1, "-", parameter1,".csv");
         }
         else
         {
            Print("TestLogger: Optimized parameter incorrect"); fileOK = false; return;
         }
      }
      else if(nrOptimizedParameters == 2)
      {
         if(parameter1 != -1 && parameter2 != -1)
         {
            fileName = StringConcatenate(EAName, "_", "ID-", loggingID, "_", optimizedParameter1, "-", parameter1, "_", optimizedParameter2, "-", parameter2,".csv");
         }
         else
         {
            Print("TestLogger: At least one optimized parameter incorrect"); fileOK = false; return;
         }
      }
      else
      {
         Print("TestLogger: nrOptimizedParameters should be 1 or 2");
      }
   }
   else
   { 
      fileName = StringConcatenate(EAName, "_", "ID-", loggingID,".csv");
   }
   handle = FileOpen(fileName,FILE_CSV|FILE_READ|FILE_WRITE,";");
   if(handle != -1)
   {
      Print("TradeLogger: Creating file " + fileName);
      FileWrite(handle,"ticketNr","orderOpenTime","orderCloseTime","orderType","orderOpenPrice","orderClosePrice","orderHighestPrice","orderLowestPrice","orderCloseProfit","orderHighestProfit","orderLowestProfit","orderCommission","orderSwap","orderLots"); 
      nrLoggedTrades=0;
      fileOK = true;
   }
   else
   {
      fileOK = false;
      Print("TestLogger: File Initialization Problem!");
   }
}
//------------------------------

void tradeLogger()
{
   if(fileOK)
   {
      for(int j=0;j<OrdersTotal();j++)
      {
         if(OrderSelect(j,SELECT_BY_POS) && OrderMagicNumber()==EAUniqueID && relevantType())
            logTrade();
      }
   }
}

bool relevantType()
{
   int type = OrderType();
   if(type==OP_BUY || type==OP_SELL)
      return (true);
   return (false);
}

void logTrade()
{
   if(nrLoggedTrades==0){addNewLoggedTrade(); return;}
   
   int startIndex = 0;
   if(maxNumberOfSimultaneousTrades != -1)
      startIndex = MathMax(0,nrLoggedTrades-maxNumberOfSimultaneousTrades);
      
   for(int i=startIndex;i<nrLoggedTrades;i++)
   {
      if(tradeData[i][0]==OrderTicket())
      {
         tradeData[i][9] = NormalizeDouble(MathMax(tradeData[i][9],OrderProfit()),2);
         tradeData[i][10] = NormalizeDouble(MathMin(tradeData[i][10],OrderProfit()),2);
         if(tradeData[i][3] == OP_BUY)
         {
            tradeData[i][6] = NormalizeDouble(MathMax(tradeData[i][6],Bid),Digits);
            tradeData[i][7] = NormalizeDouble(MathMin(tradeData[i][7],Bid),Digits);
         }
         if(tradeData[i][3] == OP_SELL)
         {
            tradeData[i][6] = NormalizeDouble(MathMax(tradeData[i][6],Ask),Digits);
            tradeData[i][7] = NormalizeDouble(MathMin(tradeData[i][7],Ask),Digits);
         }
         return;
      }  
   }
   addNewLoggedTrade(); // add new logged trade
}

void addNewLoggedTrade()
{
   nrLoggedTrades+=1;
   ArrayResize(tradeData,nrLoggedTrades);
   
   tradeData[nrLoggedTrades-1][0]=OrderTicket();
   tradeData[nrLoggedTrades-1][1]=OrderOpenTime();
   tradeData[nrLoggedTrades-1][2]=0;
   tradeData[nrLoggedTrades-1][3]=OrderType();
   tradeData[nrLoggedTrades-1][4]=OrderOpenPrice();
   tradeData[nrLoggedTrades-1][5]=0;
   
   if(OrderType() == OP_BUY)//sell at bid
   {
      tradeData[nrLoggedTrades-1][6]=Bid;
      tradeData[nrLoggedTrades-1][7]=Bid;
   }
   else //buy back at Ask
   {
      tradeData[nrLoggedTrades-1][6]=Ask;
      tradeData[nrLoggedTrades-1][7]=Ask;
   }
   tradeData[nrLoggedTrades-1][8]=0;
   tradeData[nrLoggedTrades-1][9]=OrderProfit(); // current profit is highest profit
   tradeData[nrLoggedTrades-1][10]=OrderProfit(); // current profit is lowest profit
   tradeData[nrLoggedTrades-1][11]=OrderCommission();
   tradeData[nrLoggedTrades-1][12]=0;
   tradeData[nrLoggedTrades-1][13]=OrderLots();
}


/**
*tradeData[][0] = ticketNr
*           [1] = orderOpenTime
*           [2] = OrderCloseTime
*           [3] = OrderType
*           [4] = OrderOpenPrice
*           [5] = OrderClosePrice
*           [6] = orderHighestPrice
*           [7] = orderLowestPrice
*           [8] = orderCloseProfit
*           [9] = orderHighestProfit
*           [10] = orderLowestProfit
*           [11] = orderCommission
*           [12] = orderSwap
*/
//-----------------------------------------------
void deinitTradeLogger()
{
   if(fileOK)
   {
      for(int i=0;i<OrdersHistoryTotal();i++)
      {
         if(OrderSelect(i,SELECT_BY_POS, MODE_HISTORY) && OrderMagicNumber()==EAUniqueID)
         {
            for(int j=0; j<nrLoggedTrades; j++)
            {
               if(tradeData[j][0]==OrderTicket())
               {
                  Print("TradeLogger: Adding closing data for ", OrderTicket());
                  tradeData[j][2] = OrderCloseTime();
                  
                  tradeData[j][5] = OrderClosePrice();
                  tradeData[j][6] = NormalizeDouble(MathMax(OrderClosePrice(),tradeData[j][6]),Digits);
                  tradeData[j][7] = NormalizeDouble(MathMin(OrderClosePrice(),tradeData[j][7]),Digits);
                  
                  tradeData[j][8] = OrderProfit();
                  tradeData[j][9] = NormalizeDouble(MathMax(OrderProfit(),tradeData[j][9]),2);
                  tradeData[j][10] = NormalizeDouble(MathMin(OrderProfit(),tradeData[j][10]),2);
                  
                  tradeData[j][12] = OrderSwap();
                  
                  string loggedType = "OP_SELL";
                  if(tradeData[j][3] == OP_BUY)
                     loggedType = "OP_BUY";
                  FileWrite(handle,tradeData[j][0],TimeToStr(tradeData[j][1]),TimeToStr(tradeData[j][2]),loggedType,tradeData[j][4],tradeData[j][5],tradeData[j][6],tradeData[j][7],
                              tradeData[j][8],tradeData[j][9],tradeData[j][10],tradeData[j][11],tradeData[j][12],tradeData[j][13]);
               }
            }
         }
      }
      Print("TradeLogger: Closing file: ", fileName);      
      FileClose(handle);              
   }
}