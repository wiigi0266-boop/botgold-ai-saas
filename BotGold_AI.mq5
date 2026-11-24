//+------------------------------------------------------------------+
//|                                                  BotGold_AI.mq5  |
//|                     BotGold AI v2.10 — Anti-Martingale Contextuel|
//|                     XAUUSD | MT5 | Règles R01-R05                 |
//+------------------------------------------------------------------+
#property copyright "BotGold AI"
#property link      "https://github.com/wiigi0266-boop/botgold-ai-saas"
#property version   "2.10"
#property description "EA anti-martingale contextuel XAUUSD v2"
#property description "R01 Aucun Martingale | R02 Aucun Grid"
#property description "R03 Stop jamais élargi | R04 Droit de ne rien faire"
#property description "R05 Exécution locale uniquement"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Inputs
input group "=== Gestion du risque ==="
input double   InpRiskPercent     = 1.0;      // Risque par trade (%)
input double   InpMaxSpreadPoints = 40;       // Spread max autorisé (points)
input int      InpMagic           = 20261123; // Magic number
input int      InpMaxTradesPerDay = 3;        // Max trades / jour (0 = illimité)

input group "=== Stops & Trailing (R03) ==="
input double   InpSL_ATR_Mult     = 1.5;      // Stop Loss = ATR × mult
input double   InpTP_ATR_Mult     = 2.2;      // Take Profit = ATR × mult
input double   InpBE_ATR_Mult     = 1.0;      // Break-even après ATR × mult
input double   InpTrail_ATR_Mult  = 0.8;      // Trailing distance = ATR × mult
input bool     InpUseTrailing     = true;     // Activer trailing + BE

input group "=== Contexte multi-timeframe ==="
input ENUM_TIMEFRAMES InpTF_Fast  = PERIOD_M5;
input ENUM_TIMEFRAMES InpTF_Mid   = PERIOD_M15;
input ENUM_TIMEFRAMES InpTF_Slow  = PERIOD_H1;
input ENUM_TIMEFRAMES InpTF_Trend = PERIOD_H4;
input int      InpATR_Period      = 14;
input int      InpRSI_Period      = 14;
input int      InpMinContextScore = 58;       // Score minimum pour trader (0-100)

input group "=== Filtres anti-foule (R04) ==="
input bool     InpSkipExtremeFear = true;     // Skip fort en Extreme Fear
input int      InpFearGreedProxy  = 18;       // Seuil Extreme Fear (proxy RSI)
input bool     InpSkipExtremeGreed= true;     // Skip fort en Extreme Greed
input int      InpGreedProxy      = 82;       // Seuil Extreme Greed
input bool     InpUseSessionFilter= true;     // Filtrer heures calmes
input int      InpSessionStartHour= 7;        // Début session (UTC+0 approx)
input int      InpSessionEndHour  = 21;       // Fin session

input group "=== Divers ==="
input bool     InpOnlyXAUUSD      = true;     // Restreindre à XAUUSD / GOLD
input bool     InpVerboseLog      = true;     // Logs détaillés Experts
input bool     InpWriteCsv        = true;     // Export CSV backtest/live (Common/Files)

//--- Globals
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;

int handleATR_H1;
int handleRSI_M5, handleRSI_M15, handleRSI_H1, handleRSI_H4;
int handleMA_H4_Fast, handleMA_H4_Slow;

datetime lastBarTime = 0;
int      tradesToday = 0;
datetime lastDay     = 0;
string   lastSkipReason = "";
string   csvFileName = "BotGold_tester.csv";
bool     csvHeaderDone = false;

//+------------------------------------------------------------------+
int OnInit()
{
   if(InpOnlyXAUUSD)
   {
      string s = _Symbol;
      if(s != "XAUUSD" && StringFind(s, "XAU") < 0 && StringFind(s, "GOLD") < 0)
      {
         Print("BotGold AI : symbole non supporté (", s, "). Utilisez XAUUSD.");
         return INIT_FAILED;
      }
   }

   if(!symInfo.Name(_Symbol))
   {
      Print("BotGold AI : impossible de charger le symbole.");
      return INIT_FAILED;
   }
   symInfo.RefreshRates();

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFillingBySymbol(_Symbol);

   handleATR_H1     = iATR(_Symbol, InpTF_Slow, InpATR_Period);
   handleRSI_M5     = iRSI(_Symbol, InpTF_Fast,  InpRSI_Period, PRICE_CLOSE);
   handleRSI_M15    = iRSI(_Symbol, InpTF_Mid,   InpRSI_Period, PRICE_CLOSE);
   handleRSI_H1     = iRSI(_Symbol, InpTF_Slow,  InpRSI_Period, PRICE_CLOSE);
   handleRSI_H4     = iRSI(_Symbol, InpTF_Trend, InpRSI_Period, PRICE_CLOSE);
   handleMA_H4_Fast = iMA(_Symbol, InpTF_Trend, 20, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_H4_Slow = iMA(_Symbol, InpTF_Trend, 50, 0, MODE_EMA, PRICE_CLOSE);

   if(handleATR_H1 == INVALID_HANDLE || handleRSI_M5 == INVALID_HANDLE ||
      handleRSI_M15 == INVALID_HANDLE || handleRSI_H1 == INVALID_HANDLE ||
      handleRSI_H4 == INVALID_HANDLE || handleMA_H4_Fast == INVALID_HANDLE ||
      handleMA_H4_Slow == INVALID_HANDLE)
   {
      Print("BotGold AI : échec création des indicateurs.");
      return INIT_FAILED;
   }

   Print("════════════════════════════════════════");
   Print("BotGold AI v2.10 initialisé");
   Print("R01 Aucun Martingale | R02 Aucun Grid");
   Print("R03 Stop jamais élargi | R04 Droit de ne rien faire");
   Print("R05 Exécution locale | Risque ", InpRiskPercent, "%");
   Print("Score min: ", InpMinContextScore, " | Max trades/j: ", InpMaxTradesPerDay);
   if(InpWriteCsv)
      Print("CSV log: Common/Files/", csvFileName);
   Print("════════════════════════════════════════");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(handleATR_H1);
   IndicatorRelease(handleRSI_M5);
   IndicatorRelease(handleRSI_M15);
   IndicatorRelease(handleRSI_H1);
   IndicatorRelease(handleRSI_H4);
   IndicatorRelease(handleMA_H4_Fast);
   IndicatorRelease(handleMA_H4_Slow);
   Comment("");
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Reset journalier
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
   if(today != lastDay)
   {
      lastDay = today;
      tradesToday = 0;
      if(InpVerboseLog) Print("BotGold AI | Nouveau jour — compteur trades remis à 0");
   }

   // R03 : trailing / BE seulement (jamais élargir le stop)
   ManageOpenPosition();

   // Nouvelle bougie M5 uniquement
   datetime barTime = iTime(_Symbol, InpTF_Fast, 0);
   if(barTime == lastBarTime) return;
   lastBarTime = barTime;

   // R02 : une seule position
   if(CountOurPositions() > 0)
   {
      Comment("BotGold AI | Position ouverte — gestion R03 active");
      return;
   }

   // Limite journalière
   if(InpMaxTradesPerDay > 0 && tradesToday >= InpMaxTradesPerDay)
   {
      LogSkip("Limite journalière atteinte (" + IntegerToString(tradesToday) + ")");
      return;
   }

   // Filtre session
   if(InpUseSessionFilter)
   {
      int hour = dt.hour;
      if(hour < InpSessionStartHour || hour >= InpSessionEndHour)
      {
         LogSkip("Hors session (" + IntegerToString(hour) + "h UTC)");
         return;
      }
   }

   // Analyse contextuelle
   int score = 0;
   int direction = 0; // 1=buy, -1=sell
   string reason = "";

   if(!EvaluateContext(score, direction, reason))
   {
      LogSkip(reason + " | Score=" + IntegerToString(score));
      return;
   }

   // R04
   if(score < InpMinContextScore || direction == 0)
   {
      LogSkip("Contexte insuffisant (score=" + IntegerToString(score) +
              " < " + IntegerToString(InpMinContextScore) + ") — " + reason);
      return;
   }

   // Spread
   if(!symInfo.RefreshRates()) return;
   double spreadPts = (symInfo.Ask() - symInfo.Bid()) / symInfo.Point();
   if(spreadPts > InpMaxSpreadPoints)
   {
      LogSkip("Spread trop large (" + DoubleToString(spreadPts, 1) + " pts)");
      return;
   }

   // Ouverture
   if(OpenTrade(direction, score, reason))
      tradesToday++;
}

//+------------------------------------------------------------------+
//| Score de contexte multi-TF (aligné avec le dashboard web)        |
//+------------------------------------------------------------------+
bool EvaluateContext(int &score, int &direction, string &reason)
{
   score = 0;
   direction = 0;
   reason = "";

   double rsiM5[2], rsiM15[2], rsiH1[2], rsiH4[2];
   double maFast[2], maSlow[2];
   double atrH1[1];

   if(CopyBuffer(handleRSI_M5,  0, 0, 2, rsiM5)  < 2) return false;
   if(CopyBuffer(handleRSI_M15, 0, 0, 2, rsiM15) < 2) return false;
   if(CopyBuffer(handleRSI_H1,  0, 0, 2, rsiH1)  < 2) return false;
   if(CopyBuffer(handleRSI_H4,  0, 0, 2, rsiH4)  < 2) return false;
   if(CopyBuffer(handleMA_H4_Fast, 0, 0, 2, maFast) < 2) return false;
   if(CopyBuffer(handleMA_H4_Slow, 0, 0, 2, maSlow) < 2) return false;
   if(CopyBuffer(handleATR_H1, 0, 0, 1, atrH1) < 1) return false;

   // --- Proxy Fear & Greed (moyenne RSI multi-TF, inversée en zone extrême)
   double avgRSI = (rsiM5[0] + rsiM15[0] + rsiH1[0] + rsiH4[0]) / 4.0;
   int fgProxy = (int)MathMax(1, MathMin(99, avgRSI));

   // Extreme Fear → skip quasi systématique (sauf exception très forte)
   if(InpSkipExtremeFear && fgProxy <= InpFearGreedProxy)
   {
      bool exceptionBuy = (rsiH4[0] < 28 && rsiH1[0] < 32 && maFast[0] > maSlow[0]);
      if(!exceptionBuy)
      {
         score = (int)(fgProxy * 1.5);
         reason = "Extreme Fear proxy (" + IntegerToString(fgProxy) + ") — filtre anti-foule R04";
         return true;
      }
      // Exception rare : survente extrême + tendance H4 encore haussière
      score = 70;
      direction = 1;
      reason = "Exception Extreme Fear + RSI H4 survente + tendance H4 haussière";
      return true;
   }

   // Extreme Greed → skip quasi systématique
   if(InpSkipExtremeGreed && fgProxy >= InpGreedProxy)
   {
      bool exceptionSell = (rsiH4[0] > 72 && rsiH1[0] > 68 && maFast[0] < maSlow[0]);
      if(!exceptionSell)
      {
         score = (int)((100 - fgProxy) * 1.5);
         reason = "Extreme Greed proxy (" + IntegerToString(fgProxy) + ") — filtre anti-foule R04";
         return true;
      }
      score = 70;
      direction = -1;
      reason = "Exception Extreme Greed + RSI H4 surachat + tendance H4 baissière";
      return true;
   }

   // --- Tendance H4
   bool bullTrend = maFast[0] > maSlow[0];
   bool bearTrend = maFast[0] < maSlow[0];

   if(bullTrend) score += 22;
   else if(bearTrend) score += 22;
   else
   {
      reason = "Pas de tendance H4 claire (EMA20≈EMA50)";
      return true;
   }

   // --- Alignement RSI (votes)
   int bullVotes = 0, bearVotes = 0;
   if(rsiM5[0]  < 38) bullVotes++; else if(rsiM5[0]  > 62) bearVotes++;
   if(rsiM15[0] < 42) bullVotes++; else if(rsiM15[0] > 58) bearVotes++;
   if(rsiH1[0]  < 45) bullVotes++; else if(rsiH1[0]  > 55) bearVotes++;
   if(rsiH4[0]  < 48) bullVotes++; else if(rsiH4[0]  > 52) bearVotes++;

   if(bullTrend && bullVotes >= 3)
   {
      direction = 1;
      score += 18 + bullVotes * 6;
   }
   else if(bearTrend && bearVotes >= 3)
   {
      direction = -1;
      score += 18 + bearVotes * 6;
   }
   else if(bullTrend && bullVotes >= 2 && rsiH1[0] < 50)
   {
      direction = 1;
      score += 12 + bullVotes * 4;
   }
   else if(bearTrend && bearVotes >= 2 && rsiH1[0] > 50)
   {
      direction = -1;
      score += 12 + bearVotes * 4;
   }
   else
   {
      reason = "RSI multi-TF non alignés avec tendance H4 (bull=" +
               IntegerToString(bullVotes) + " bear=" + IntegerToString(bearVotes) + ")";
      score += 8;
      return true;
   }

   // Momentum court terme
   if(direction == 1  && rsiM5[0] > rsiM5[1]) score += 8;
   if(direction == -1 && rsiM5[0] < rsiM5[1]) score += 8;

   // Volatilité saine (ATR H1 en % du prix)
   double atrPct = atrH1[0] / symInfo.Bid() * 100.0;
   if(atrPct > 0.12 && atrPct < 1.0) score += 10;
   else if(atrPct >= 1.0)
   {
      reason = "Volatilité excessive (ATR " + DoubleToString(atrPct, 2) + "%)";
      score = MathMin(score, 45);
      return true;
   }
   else score += 3; // très calme

   // Bonus zone RSI saine (pas extrême)
   if(rsiH1[0] > 35 && rsiH1[0] < 65) score += 6;

   score = MathMin(98, score);
   reason = (direction == 1 ? "BUY" : "SELL") +
            " | Align RSI | F&G proxy=" + IntegerToString(fgProxy) +
            " | ATR%=" + DoubleToString(atrPct, 2);
   return true;
}

//+------------------------------------------------------------------+
//| R01 — Sizing ATR + risque % (jamais martingale)                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
   if(slDistance <= 0) return 0.01;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * InpRiskPercent / 100.0;

   double tickSize  = symInfo.TickSize();
   double tickValue = symInfo.TickValue();
   double point     = symInfo.Point();

   if(tickSize <= 0 || tickValue <= 0 || point <= 0) return 0.01;

   double moneyPerPoint = tickValue / tickSize * point;
   if(moneyPerPoint <= 0) return 0.01;

   double lots = riskMoney / (slDistance / point * moneyPerPoint);

   double minLot  = symInfo.LotsMin();
   double maxLot  = symInfo.LotsMax();
   double lotStep = symInfo.LotsStep();

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
bool OpenTrade(int direction, int score, string reason)
{
   double atr[1];
   if(CopyBuffer(handleATR_H1, 0, 0, 1, atr) < 1) return false;

   double atrVal = atr[0];
   if(atrVal <= 0) return false;

   if(!symInfo.RefreshRates()) return false;

   double price, sl, tp;
   ENUM_ORDER_TYPE orderType;

   if(direction == 1)
   {
      orderType = ORDER_TYPE_BUY;
      price = symInfo.Ask();
      sl = price - atrVal * InpSL_ATR_Mult;
      tp = price + atrVal * InpTP_ATR_Mult;
   }
   else
   {
      orderType = ORDER_TYPE_SELL;
      price = symInfo.Bid();
      sl = price + atrVal * InpSL_ATR_Mult;
      tp = price - atrVal * InpTP_ATR_Mult;
   }

   double slDist = MathAbs(price - sl);
   double lots = CalculateLotSize(slDist);
   if(lots < symInfo.LotsMin()) return false;

   string comment = StringFormat("BG v2 s=%d", score);

   bool ok = false;
   if(orderType == ORDER_TYPE_BUY)
      ok = trade.Buy(lots, _Symbol, price, sl, tp, comment);
   else
      ok = trade.Sell(lots, _Symbol, price, sl, tp, comment);

   if(ok)
   {
      string dir = (direction == 1 ? "BUY" : "SELL");
      Print("BotGold AI | TRADE ", dir,
            " | Lot=", DoubleToString(lots, 2),
            " | SL=", DoubleToString(sl, _Digits),
            " | TP=", DoubleToString(tp, _Digits),
            " | Score=", score,
            " | ", reason);
      Comment("BotGold AI | TRADE ", dir,
              " score=", score, " lot=", DoubleToString(lots, 2));
      WriteCsvDecision("TRADE", dir, score, reason, lots, sl, tp);
   }
   else
   {
      Print("BotGold AI | Échec ordre : ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
   }
   return ok;
}

//+------------------------------------------------------------------+
//| R03 — Trailing + Break-even uniquement (stop jamais élargi)      |
//+------------------------------------------------------------------+
void ManageOpenPosition()
{
   if(!InpUseTrailing) return;

   double atr[1];
   if(CopyBuffer(handleATR_H1, 0, 0, 1, atr) < 1) return;
   double atrVal = atr[0];
   if(atrVal <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol() != _Symbol) continue;
      if(posInfo.Magic() != InpMagic) continue;

      double openPrice = posInfo.PriceOpen();
      double currentSL = posInfo.StopLoss();
      double currentTP = posInfo.TakeProfit();
      long   type      = posInfo.PositionType();
      ulong  ticket    = posInfo.Ticket();

      if(!symInfo.RefreshRates()) continue;

      if(type == POSITION_TYPE_BUY)
      {
         double bid = symInfo.Bid();
         double profitDist = bid - openPrice;

         // Break-even
         if(profitDist >= atrVal * InpBE_ATR_Mult)
         {
            double newSL = openPrice + symInfo.Point() * 10;
            if(currentSL < newSL)
               trade.PositionModify(ticket, newSL, currentTP);
         }

         // Trailing
         double trailSL = bid - atrVal * InpTrail_ATR_Mult;
         if(trailSL > currentSL && trailSL < bid)
            trade.PositionModify(ticket, trailSL, currentTP);
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double ask = symInfo.Ask();
         double profitDist = openPrice - ask;

         if(profitDist >= atrVal * InpBE_ATR_Mult)
         {
            double newSL = openPrice - symInfo.Point() * 10;
            if(currentSL == 0 || currentSL > newSL)
               trade.PositionModify(ticket, newSL, currentTP);
         }

         double trailSL = ask + atrVal * InpTrail_ATR_Mult;
         if((currentSL == 0 || trailSL < currentSL) && trailSL > ask)
            trade.PositionModify(ticket, trailSL, currentTP);
      }
   }
}

//+------------------------------------------------------------------+
int CountOurPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagic)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
void WriteCsvDecision(string action, string direction, int score, string reason, double lot, double sl, double tp)
{
   if(!InpWriteCsv) return;
   int h = FileOpen(csvFileName, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ';');
   if(h == INVALID_HANDLE)
   {
      // créer
      h = FileOpen(csvFileName, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ';');
      if(h == INVALID_HANDLE)
      {
         if(InpVerboseLog) Print("BotGold AI | CSV open failed: ", GetLastError());
         return;
      }
      FileWrite(h, "datetime", "action", "direction", "symbol", "score", "price", "lot", "sl", "tp", "reason");
      csvHeaderDone = true;
   }
   else
   {
      // aller en fin de fichier
      FileSeek(h, 0, SEEK_END);
      if(!csvHeaderDone && FileTell(h) == 0)
      {
         FileWrite(h, "datetime", "action", "direction", "symbol", "score", "price", "lot", "sl", "tp", "reason");
         csvHeaderDone = true;
      }
      else csvHeaderDone = true;
   }
   double px = 0;
   if(symInfo.RefreshRates()) px = (direction == "SELL" ? symInfo.Bid() : symInfo.Ask());
   if(px == 0) px = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   FileWrite(h,
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
      action,
      direction,
      _Symbol,
      IntegerToString(score),
      DoubleToString(px, _Digits),
      DoubleToString(lot, 2),
      DoubleToString(sl, _Digits),
      DoubleToString(tp, _Digits),
      reason
   );
   FileClose(h);
}

void LogSkip(string msg)
{
   if(msg == lastSkipReason) // éviter spam Comment
   {
      Comment("BotGold AI | SKIP — ", msg);
      return;
   }
   lastSkipReason = msg;
   Comment("BotGold AI | SKIP — ", msg);
   if(InpVerboseLog)
      Print("BotGold AI | SKIP — ", msg);
   WriteCsvDecision("SKIP", "", 0, msg, 0, 0, 0);
}
//+------------------------------------------------------------------+
