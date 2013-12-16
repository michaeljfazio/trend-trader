//+------------------------------------------------------------------+
//|                                                 Trend Trader.mq4 |
//|                                    Copyright 2013, Michael Fazio |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, Michael Fazio"
#property link      ""

static int    MAGIC_NUMBER = 13052013;
static double ATR_MULTIPLIER = 2.0;

// Parameters optimized for:
//    EUR/USD (Daily)
//    EUR/AUD (Daily)
//    XAG/USD (Daily)
//    XAU/USD (Daily)

extern int     TradePeriod       = 20;
extern int     AtrPeriod         = 10;

double TradeHigh;
double TradeLow;
double Atr;
double DollarRisk;
double DollarVolatility;
int    TotalLong;
int    TotalShort;
int    LastTrade;

int init() {
  LastTrade = 0;  
}

int start() {
  CalculateGlobals();
  DetectOpenSignal();
  AdjustStopLosses();
  return(0);
}

void CalculateGlobals() {

  TradeHigh         = iHigh(Symbol(), Period(), iHighest(Symbol(), Period(), MODE_HIGH, TradePeriod, 1));
  TradeLow          = iLow(Symbol(), Period(), iLowest(Symbol(), Period(), MODE_LOW, TradePeriod, 1));
  Atr               = iATR(Symbol(), Period(), AtrPeriod, 1); // N Value
  DollarRisk        = AccountFreeMargin() * 0.01; 
  DollarVolatility  = Atr / MarketInfo(Symbol(), MODE_POINT);
  
  // Calculate open trades.
  TotalLong = 0;
  TotalShort = 0;
  int OrderCount = OrdersTotal();
  for(int i = OrderCount - 1; i >= 0; i--) {
    OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
    if(OrderMagicNumber() == MAGIC_NUMBER && OrderSymbol() == Symbol()) {
      if(OrderType() == OP_BUY)  { TotalLong++; }
      if(OrderType() == OP_SELL) { TotalShort++; }    
    }
  }
 
}

void DetectOpenSignal() {
  if(LastTrade == Time[0]) {
    return;
  }

  int Ticket;
  if(Ask >= TradeHigh && TotalLong < 1) {
    Ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(), Ask, 3, 0, 0, "TREND TRADER", MAGIC_NUMBER, 0, CLR_NONE); 
    if(Ticket > 0) {
      if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES)) {
        Print("BUY order opened : " , OrderOpenPrice());
        SendNotification(Symbol()+ " " + Period()+ " Trend Trader BUY @ " + OrderOpenPrice());
      }
    } else {
      Print("Error opening BUY order : ",GetLastError());
    }
  }
  
  if(Bid <= TradeLow && TotalShort < 1) { 
    Ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(), Bid, 3, 0, 0, "TREND TRADER", MAGIC_NUMBER, 0, CLR_NONE);
    if(Ticket > 0) {
      if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES)) { 
        Print("SELL order opened : " , OrderOpenPrice());
        SendNotification(Symbol()+ " " + Period()+ " Trend Trader SELL @ " + OrderOpenPrice());
      }
    } else {
      Print("Error opening SELL order : ",GetLastError());
    }
  }
 
  if(Ticket > 0) { LastTrade = Time[0]; } 
  return;
}

void AdjustStopLosses() {
  int Ticket;
  int OrderCount = OrdersTotal();
  for(int i = OrderCount - 1; i >= 0; i--) {
    OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
    if(OrderMagicNumber() == MAGIC_NUMBER && OrderSymbol() == Symbol()) {
      double NewStopLoss;
      double CurrentStopLoss = OrderStopLoss();
      if(OrderType() == OP_BUY) { 
         NewStopLoss = Ask - ATR_MULTIPLIER * Atr; 
         if(CurrentStopLoss != 0) {
           NewStopLoss = MathMax(NewStopLoss, CurrentStopLoss);
         }
      }
      if(OrderType() == OP_SELL) { 
         NewStopLoss = Bid + ATR_MULTIPLIER * Atr; 
         if(CurrentStopLoss != 0) {
           NewStopLoss = MathMin(NewStopLoss, CurrentStopLoss);
         }
      }
      if(CurrentStopLoss != NewStopLoss) {
         Ticket = OrderModify(OrderTicket(), 0, NormalizeDouble(NewStopLoss, Digits), 0, 0, CLR_NONE);
         if(Ticket > 0) {
           if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Order stop modified to : ", OrderStopLoss());
         } else {
           Print("Error modifying order stop : ",GetLastError());
         }
      }
    }
  }
}

double LotsOptimized() {
   double UnitLotSize  = NormalizeDouble(DollarRisk / DollarVolatility, Digits);
   UnitLotSize = MathMax(UnitLotSize, MarketInfo(Symbol(), MODE_MINLOT));
   return(UnitLotSize);
}