//+------------------------------------------------------------------+
//|                                                  BotGold_AI.mq5  |
//|                     BotGold AI — Anti-Martingale Contextuel      |
//|                     XAUUSD | MT5 | Règles R01-R05                 |
//+------------------------------------------------------------------+
#property copyright "BotGold AI"
#property link      "https://github.com/wiigi0266-boop/botgold-ai-saas"
#property version   "1.00"
#property description "EA anti-martingale contextuel XAUUSD"
#property description "R01 Aucun Martingale | R02 Aucun Grid"
#property description "R03 Stop jamais élargi | R04 Droit de ne rien faire"
#property description "R05 Exécution locale uniquement"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Inputs
input group "=== Gestion du risque ==="
input double   InpRiskPercent     = 1.0;      // Risque par trade (%)
input double   InpMaxSpreadPoints = 35;       // Spread max autorisé (points)
input int      InpMagic           = 20261122; // Magic number

input group "=== Stops & Trailing ==="
input double   InpSL_ATR_Mult     = 1.5;      // Stop Loss = ATR × multiplicateur
input double   InpTP_ATR_Mult     = 2.0;      // Take Profit = ATR × multiplicateur
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
input int      InpMinContextScore = 55;       // Score minimum pour trader (0-100)
input int      InpMaxTradesPerDay = 3;        // Max trades / jour (0 = illimité)

input group "=== Filtres ==="
input bool     InpSkipExtremeFear = true;     // Skip si Fear & Greed proxy extrême
input int      InpFearGreedProxy  = 20;       // Seuil Extreme Fear (simulation locale)
input bool     InpOnlyXAUUSD      = true;     // Restreindre à XAUUSD

//--- Globals
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;

int handleATR_M5, handleATR_H1;
int handleRSI_M5, handleRSI_M15, handleRSI_H1;
int handleMA_H4_Fast, handleMA_H4_Slow;

datetime lastBarTime = 0;
int      tradesToday = 0;
datetime lastDay     = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpOnlyXAUUSD && _Symbol != "XAUUSD" && StringFind(_Symbol, "XAU") < 0 && StringFind(_Symbol, "GOLD") < 0)
   {
      Print("BotGold AI : symbole non supporté (", _Symbol, "). Utilisez XAUUSD.");
      return INIT_FAILED;
   }

   if(!symInfo.Name(_Symbol))
   {
      Print("BotGold AI : impossible de charger le symbole.");
      return INIT_FAILED;
   }
   symInfo.RefreshRates();

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(20);
   trade.SetTypeFillingBySymbol(_Symbol);

   // Handles
   handleATR_M5     = iATR(_Symbol, InpTF_Fast, InpATR_Period);
   handleATR_H1     = iATR(_Symbol, InpTF_Slow, InpATR_Period);
   handleRSI_M5     = iRSI(_Symbol, InpTF_Fast, InpRSI_Period, PRICE_CLOSE);
   handleRSI_M15    = iRSI(_Symbol, InpTF_Mid,  InpRSI_Period, PRICE_CLOSE);
   handleRSI_H1     = iRSI(_Symbol, InpTF_Slow, InpRSI_Period, PRICE_CLOSE);
   handleMA_H4_Fast = iMA(_Symbol, InpTF_Trend, 20, 0, MODE_EMA, PRICE_CLOSE);
   handleMA_H4_Slow = iMA(_Symbol, InpTF_Trend, 50, 0, MODE_EMA, PRICE_CLOSE);

   if(handleATR_M5 == INVALID_HANDLE || handleATR_H1 == INVALID_HANDLE ||
      handleRSI_M5 == INVALID_HANDLE || handleRSI_M15 == INVALID_HANDLE ||
      handleRSI_H1 == INVALID_HANDLE || handleMA_H4_Fast == INVALID_HANDLE ||
      handleMA_H4_Slow == INVALID_HANDLE)
   {
      Print("BotGold AI : échec création des indicateurs.");
      return INIT_FAILED;
   }

   Print("BotGold AI v1.00 initialisé — Anti-Martingale | Risque ", InpRiskPercent, "%");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(handleATR_M5);
   IndicatorRelease(handleATR_H1);
   IndicatorRelease(handleRSI_M5);
   IndicatorRelease(handleRSI_M15);
   IndicatorRelease(handleRSI_H1);
   IndicatorRelease(handleMA_H4_Fast);
   IndicatorRelease(handleMA_H4_Slow);
}

//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   // Reset compteur journalier
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
   if(today != lastDay)
   {
      lastDay = today;
      tradesToday = 0;
   }

   // R03 : gestion trailing / break-even uniquement (jamais élargir le stop)
   ManageOpenPosition();

   // Nouvelle bougie M5 uniquement
   datetime barTime = iTime(_Symbol, InpTF_Fast, 0);
   if(barTime == lastBarTime) return;
   lastBarTime = barTime;

   // R02 : une seule position à la fois
   if(CountOurPositions() > 0) return;

   // Limite journalière
   if(InpMaxTradesPerDay > 0 && tradesToday >= InpMaxTradesPerDay)
   {
      Comment("BotGold AI | SKIP — limite journalière atteinte (", tradesToday, ")");
      return;
   }

   // Analyse contextuelle
   int score = 0;
   int direction = 0; // 1 = buy, -1 = sell, 0 = neutre
   string reason = "";

   if(!EvaluateContext(score, direction, reason))
   {
      Comment("BotGold AI | SKIP — ", reason, " | Score=", score);
      return;
   }

   // R04 : droit de ne rien faire
   if(score < InpMinContextScore || direction == 0)
   {
      Comment("BotGold AI | SKIP — contexte insuffisant (score=", score, " < ", InpMinContextScore, ")");
      return;
   }

   // Spread
   if(!symInfo.RefreshRates()) return;
   double spreadPts = (symInfo.Ask() - symInfo.Bid()) / symInfo.Point();
   if(spreadPts > InpMaxSpreadPoints)
   {
      Comment("BotGold AI | SKIP — spread trop large (", DoubleToString(spreadPts, 1), " pts)");
      return;
   }

   // Ouverture
   if(OpenTrade(direction, score, reason))
      tradesToday++;
}

//+------------------------------------------------------------------+
//| Évaluation multi-timeframe + score de contexte                   |
//+------------------------------------------------------------------+
bool EvaluateContext(int &score, int &direction, string &reason)
{
   score = 0;
   direction = 0;
   reason = "";

   double rsiM5[2], rsiM15[2], rsiH1[2];
   double maFast[2], maSlow[2];
   double atrH1[1];

   if(CopyBuffer(handleRSI_M5,  0, 0, 2, rsiM5)  < 2) return false;
   if(CopyBuffer(handleRSI_M15, 0, 0, 2, rsiM15) < 2) return false;
   if(CopyBuffer(handleRSI_H1,  0, 0, 2, rsiH1)  < 2) return false;
   if(CopyBuffer(handleMA_H4_Fast, 0, 0, 2, maFast) < 2) return false;
   if(CopyBuffer(handleMA_H4_Slow, 0, 0, 2, maSlow) < 2) return false;
   if(CopyBuffer(handleATR_H1, 0, 0, 1, atrH1) < 1) return false;

   // Tendance H4
   bool bullTrend = maFast[0] > maSlow[0];
   bool bearTrend = maFast[0] < maSlow[0];

   if(bullTrend) score += 25;
   else if(bearTrend) score += 25;
   else { reason = "pas de tendance H4 claire"; return true; }

   // Alignement RSI multi-TF
   int bullVotes = 0, bearVotes = 0;

   if(rsiM5[0]  < 35) bullVotes++; else if(rsiM5[0]  > 65) bearVotes++;
   if(rsiM15[0] < 40) bullVotes++; else if(rsiM15[0] > 60) bearVotes++;
   if(rsiH1[0]  < 45) bullVotes++; else if(rsiH1[0]  > 55) bearVotes++;

   if(bullTrend && bullVotes >= 2) { direction = 1;  score += 20 + bullVotes * 8; }
   else if(bearTrend && bearVotes >= 2) { direction = -1; score += 20 + bearVotes * 8; }
   else if(bullTrend && rsiM5[0] < 45 && rsiM15[0] < 50) { direction = 1; score += 15; }
   else if(bearTrend && rsiM5[0] > 55 && rsiM15[0] > 50) { direction = -1; score += 15; }
   else
   {
      reason = "RSI multi-TF non alignés avec la tendance";
      score += 10;
      return true;
   }

   // Momentum (croisement RSI M5)
   if(direction == 1 && rsiM5[0] > rsiM5[1]) score += 10;
   if(direction == -1 && rsiM5[0] < rsiM5[1]) score += 10;

   // Volatilité saine
   double atrPct = atrH1[0] / symInfo.Bid() * 100.0;
   if(atrPct > 0.15 && atrPct < 1.2) score += 10;
   else if(atrPct >= 1.2) { reason = "volatilité excessive"; score = MathMin(score, 40); }

   // Proxy Fear & Greed local (simplifié — en production brancher une API)
   // Ici on utilise un proxy basé sur RSI extrême multi-TF
   double avgRSI = (rsiM5[0] + rsiM15[0] + rsiH1[0]) / 3.0;
   int fgProxy = (int)MathMax(5, MathMin(95, avgRSI)); // approximation grossière

   if(InpSkipExtremeFear && fgProxy <= InpFearGreedProxy)
   {
      reason = "proxy Extreme Fear (RSI moyen=" + DoubleToString(avgRSI, 1) + ")";
      score = MathMin(score, 35);
      direction = 0;
      return true;
   }

   score = MathMax(0, MathMin(100, score));
   reason = (direction == 1 ? "Achat" : "Vente") + " | score=" + IntegerToString(score);
   return true;
}

//+------------------------------------------------------------------+
//| Calcul de la taille de position (R01 — ATR + risque %)           |
//+------------------------------------------------------------------+
double CalcLotSize(double slDistancePrice)
{
   if(slDistancePrice <= 0) return 0;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * InpRiskPercent / 100.0;

   double tickSize  = symInfo.TickSize();
   double tickValue = symInfo.TickValue();
   double point     = symInfo.Point();

   if(tickSize <= 0 || tickValue <= 0 || point <= 0) return 0;

   double ticks = slDistancePrice / tickSize;
   if(ticks <= 0) return 0;

   double lot = riskMoney / (ticks * tickValue);

   double minLot  = symInfo.LotsMin();
   double maxLot  = symInfo.LotsMax();
   double lotStep = symInfo.LotsStep();

   lot = MathFloor(lot / lotStep) * lotStep;
   lot = MathMax(minLot, MathMin(maxLot, lot));

   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Ouverture d'ordre (R01 + R02)                                    |
//+------------------------------------------------------------------+
bool OpenTrade(int direction, int score, string reason)
{
   double atr[1];
   if(CopyBuffer(handleATR_H1, 0, 0, 1, atr) < 1) return false;

   double atrVal = atr[0];
   if(atrVal <= 0) return false;

   if(!symInfo.RefreshRates()) return false;

   double price, sl, tp;
   double slDist = atrVal * InpSL_ATR_Mult;
   double tpDist = atrVal * InpTP_ATR_Mult;

   if(direction == 1)
   {
      price = symInfo.Ask();
      sl    = price - slDist;
      tp    = price + tpDist;
   }
   else
   {
      price = symInfo.Bid();
      sl    = price + slDist;
      tp    = price - tpDist;
   }

   double lots = CalcLotSize(slDist);
   if(lots <= 0)
   {
      Print("BotGold AI : lot calculé invalide");
      return false;
   }

   string comment = StringFormat("BotGold AI | %s | score=%d", direction == 1 ? "BUY" : "SELL", score);

   bool ok = false;
   if(direction == 1)
      ok = trade.Buy(lots, _Symbol, price, sl, tp, comment);
   else
      ok = trade.Sell(lots, _Symbol, price, sl, tp, comment);

   if(ok)
   {
      Print("BotGold AI | ORDRE OUVERT | ", comment, " | lots=", lots,
            " | SL=", DoubleToString(sl, (int)symInfo.Digits()),
            " | TP=", DoubleToString(tp, (int)symInfo.Digits()));
      Comment("BotGold AI | ", comment);
   }
   else
   {
      Print("BotGold AI | Échec ordre | err=", GetLastError(), " | ", trade.ResultRetcodeDescription());
   }

   return ok;
}

//+------------------------------------------------------------------+
//| Gestion position ouverte — trailing + BE uniquement (R03)        |
//+------------------------------------------------------------------+
void ManageOpenPosition()
{
   if(!InpUseTrailing) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagic) continue;

      double atr[1];
      if(CopyBuffer(handleATR_H1, 0, 0, 1, atr) < 1) continue;
      double atrVal = atr[0];
      if(atrVal <= 0) continue;

      if(!symInfo.RefreshRates()) continue;

      double openPrice = posInfo.PriceOpen();
      double currentSL = posInfo.StopLoss();
      double currentTP = posInfo.TakeProfit();
      long   type      = posInfo.PositionType();
      ulong  ticket    = posInfo.Ticket();

      double beTrigger = atrVal * InpBE_ATR_Mult;
      double trailDist = atrVal * InpTrail_ATR_Mult;
      double newSL     = currentSL;

      if(type == POSITION_TYPE_BUY)
      {
         double bid = symInfo.Bid();
         double profitPts = bid - openPrice;

         // Break-even
         if(profitPts >= beTrigger)
         {
            double beSL = openPrice + symInfo.Point() * 5; // léger buffer
            if(currentSL < beSL) newSL = beSL;
         }

         // Trailing
         if(profitPts >= beTrigger)
         {
            double trailSL = bid - trailDist;
            if(trailSL > newSL && trailSL > openPrice)
               newSL = trailSL;
         }

         // R03 : ne jamais élargir (newSL doit être >= currentSL)
         if(newSL > currentSL + symInfo.Point())
            trade.PositionModify(ticket, newSL, currentTP);
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double ask = symInfo.Ask();
         double profitPts = openPrice - ask;

         if(profitPts >= beTrigger)
         {
            double beSL = openPrice - symInfo.Point() * 5;
            if(currentSL > beSL || currentSL == 0) newSL = beSL;
         }

         if(profitPts >= beTrigger)
         {
            double trailSL = ask + trailDist;
            if((trailSL < newSL || newSL == 0) && trailSL < openPrice)
               newSL = trailSL;
         }

         if(newSL < currentSL - symInfo.Point() || currentSL == 0)
            if(newSL > 0)
               trade.PositionModify(ticket, newSL, currentTP);
      }
   }
}

//+------------------------------------------------------------------+
//| Nombre de positions de cet EA                                    |
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
