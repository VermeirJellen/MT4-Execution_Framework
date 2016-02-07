//+------------------------------------------------------------------+
//|                                                       Inform.mqh |
//|                                                   Vermeir Jellen |
//|                                           jellenvermeir@gmail.com|
//+------------------------------------------------------------------+
#property copyright "Vermeir Jellen"
//---------------- Variables for Inform.mqh -------------------------|
color messageColor;       // Color of the current message line
string messageArray[30];  // Array that holds the last 30 information messages

extern string print_info = "*** Print EA and trading info at runtime ***";
extern bool printInfo = true;

extern string debugInfo = "*** Print EA and trading info during backtesting ***";
extern bool printDebugInfo = true;
//-------------------------------------------------------------------|

//-------------------------------------------------------------------------
// Function that displays graphical messages on the screen.
//-------------------------------------------------------------------------
void inform(int messageNr, int number=0, double value=0.0, string explicitMessage="")
{  
   if(IsTesting())
   {
      if(messageNr!=0 && explicitMessage=="" && printDebugInfo)
         Print(getMessage(messageNr,number,value));
      if(messageNr!=0 && explicitMessage!="" && printDebugInfo)
         Print(explicitMessage);
      return;
   }

   int    windowNr;                    // Indicator window number
   string message;                     // Message line
   static int    messageTime;          // Last publication time of the message
   static int    messageCounter;       // Graphical messages counter

   windowNr = WindowFind("Information");  // Searching for indicator window number
   if (windowNr < 0)
   {
      if(messageNr!=0 && explicitMessage=="" && printInfo)
         Print(getMessage(messageNr,number,value));
      if(messageNr!=0 && explicitMessage!="" && printInfo)
         Print(explicitMessage);
      return;
   }
//--------------------------------------------------
   if (messageNr==0)  // This happens at every tick (or bar) in START, make messages gray if longer than 15 secs ago.
   {
      if (messageTime==0) return;        // If it is gray already
      if (GetTickCount()-messageTime>15000)// The color has become updated within 15 sec
      {
         for(int i=0;i<=29; i++)      // Color lines with gray
         {
            if(messageArray[i]!="")
               ObjectSet(messageArray[i], OBJPROP_COLOR, Gray);
         }
         messageTime=0;                  // Flag: All lines are gray
         WindowRedraw();                 // Redrawing objects
      }
      return;                          
   }
//-----------------------------------------------------   
   if (messageNr==-1)                 //delete the messages at DEINIT
   {
      for(i=0; i<=29; i++)             // By object indexes
      {
         if(messageArray[i]!="")
            ObjectDelete(messageArray[i]);   // Deletion of object
      }
      return;                                // Exit the function
   }
 //--------------------------------------------------------  

   messageCounter++;                    // Graphical messages counter
   messageTime=GetTickCount();           // Last publication time 
   messageColor=Lime;
   message=explicitMessage;
   if(explicitMessage=="")
      message = getMessage(messageNr, number, value);
  
   if(messageArray[29]!="")
      ObjectDelete(messageArray[29]);      // Deleting 29th (upper) object
   for(i=29; i>=1; i--)                 // Cycle for array indexes ..
   {                                 // .. of graphical objects
      messageArray[i]=messageArray[i-1];// Raising objects:
      if(messageArray[i]!="")
         ObjectSet(messageArray[i], OBJPROP_YDISTANCE, 2+15*i);
   }
   
   messageArray[0]="Inform_"+messageCounter+"_"+Symbol(); // Object name
   ObjectCreate (messageArray[0], OBJ_LABEL, windowNr, 0, 0);// Creating
   ObjectSet    (messageArray[0], OBJPROP_CORNER, 3);  // Corner
   ObjectSet    (messageArray[0], OBJPROP_XDISTANCE, 450);// Axis ?
   ObjectSet    (messageArray[0], OBJPROP_YDISTANCE, 2);  // Axis Y
   ObjectSetText(messageArray[0], message, 10, "Courier New", messageColor);
   WindowRedraw();  
                     
   return;
}
//-------------------------------------------------------------------------
string getMessage(int messageNumber, int number, double value) //return the displayed messsage string.
{
   string message;
   switch(messageNumber)
   {
      case 1:
         message="Closed order Buy  " + number;
         PlaySound("Close_order.wav");                         break;
      case 2:
         message="Closed order Sell " + number;
         PlaySound("Close_order.wav");                         break;
      case 3:
         message="Deleted pending order " + number;
         PlaySound("Close_order.wav");                         break;
      case 4:
         message="Opened order Buy " + number;
         PlaySound("Ok.wav");                                  break;
      case 5:
         message="Opened order Sell " + number;
         PlaySound("Ok.wav");                                  break;
      case 6:
         message="Placed pending order " + number;
         PlaySound("Ok.wav");                                  break;
      case 7:
         message="Order "+number+" modified into the market one";
         PlaySound("Transform.wav");                           break;
      case 8:
         message="Reopened order "+ number;                  break;
         PlaySound("Bulk.wav");
      case 9:
         message="Partly closed order "+ number;
         PlaySound("Close_order.wav");                         break;
      case 10:
         message="Broker: new minimum distance: "+ number;
         PlaySound("Inform.wav");                              break;
      case 11:
         if(number==0)
            message="Not enough money for "+DoubleToStr(value,3) + " lots";
         if(number==1)
            message="Required lotsize (" + DoubleToStr(value,3) + ") is too small";
         if(number==2)
            message="Required lotsize (" + DoubleToStr(value,3) + ") is too large"; 
         messageColor=Red;
         PlaySound("Oops.wav");                                break;
      case 12:
         message="Trying to close order " + number;
         PlaySound("expert.wav");                              break;
      case 13:
         if (number==OP_BUY || number==OP_SELL)
            message="Trying to open market order " + number;
         else
            message="Trying to open Pending order";
         PlaySound("expert.wav");                              break;
      case 14:
         message="Invalid password for live trading. EA does not function.";
         messageColor=Red;
         PlaySound("Oops.wav");                                break;
      case 15:
         switch(number)                 // Going to the error number
         {
            case 0  : message="Logical error. Contact strategycoder@gmail.com";                 break;
            case 4  : message="Trade server is busy. Retrying..";                               break;
            case 129: message="Wrong price. Retrying..";                                        break;
            case 135: message="Price changed. Retrying..";                                      break;
            case 136: message="No prices. Awaiting a new tick..";                               break;
            case 137: message="Broker is busy. Retrying..";                                     break;
            case 138: message="Requote. Retrying..";                                            break;
            case 146: message="Trading subsystem is busy. Retrying.. ";                         break;
            case 6 :  message="No connection to the server (check connection). Retrying..";     break;
            case 128: message="Trade timeout (check connection). Retrying..";                   break;
            case 2:   message="Critical: Common error.";                                        break;
            case 5 :  message="Critical: Old version of the terminal.";                         break;
            case 145: message="Critical: Order is to close to market price.";                   break;
            case 64:  message="Critical: Account is blocked.";                                  break;
            case 133: message="Critical: Trading is prohibited";                                break;
            case 8 :  message="Critical: Too frequent requests";                                break;
            case 7 :  message="Critical: Not enough rights to trade";                           break;
            case 148: message="Critical Too many open and/or pending orders";                   break;
            case 141: message="Critical: Too many requests";                                    break;
            case 999: message="Critical: Too many retrys";                                      break;
            default:  message="Critical error occurred " + number;   //Other errors
         }
         messageColor=Red;
         PlaySound("Error.wav");                                    break; 
      case 16:
         message="Extern variable risk must be greater than 0 and smaller than 100. EA does not function.";
         messageColor=Red;
         PlaySound("Oops.wav"); break;
      case 17:
         message="Fixed lotsize must be greater than the minmal lotsize. EA does not function.";
         messageColor=Red;
         PlaySound("Oops.wav"); break;
      case 18:
         message="extern variable freeMargin must be greater than 0 and smaller or equal to 100 when modevolume == 2. EA does not function.";
         messageColor=Red;
         PlaySound("Oops.wav"); break;
      case 19:
         message="Trying to modify order " + number;
         PlaySound("expert.wav"); break;
      case 20:
         message="Expert succesfully initialized! Start execution at next tick..";
         PlaySound("expert.wav"); break;
      case 21:
         message="Price difference between the current Bid/Ask price and the openingprice for the pending is to small!";
         PlaySound("Oops.wav"); break;
      case 22:
         message="trying to delete pending order" + number;
         PlaySound("expert.wav"); break;
      case 23:
         message="Critical! Order " + number + " could not be removed (No SL/TP placed!)";
         PlaySound("Error.wav");
      case 24:
         message="Fixed lotsize must be smaller than the maximal lotsize. EA does not function.";
         messageColor=Red;
         PlaySound("Oops.wav"); break;
      case 25:
         message="Multiple options for volume control at the same time. EA does not function";
         messageColor=Red;
         PlaySound("Oops.wav"); break;
      case 26:
         message="Distance between price and pending price too small";
         messageColor=Red;
         PlaySound("Oops.wav"); break;
      case 27:
         message="Unable to add SL/TP for order " + number + ": Trying to delete order..";
         messageColor=Red;
         PlaySound("Oops.wav"); break;
      case 28:
         message="Broker: new freezelevel: "+ number;
         PlaySound("Inform.wav");                              break;
      case -1:
         message="Deinit";
         messageColor=Red;
         PlaySound("Expert.wav"); break;
      default:
         message="default "+ messageNumber;
         messageColor=Red;
         PlaySound("Bzrrr.wav");
   }
   return(message);  
}

void initInformation()
{
   for(int i=0;i<30;i++)
   {
      messageArray[i]="";
   }
}