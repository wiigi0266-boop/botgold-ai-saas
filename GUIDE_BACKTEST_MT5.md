# Guide Backtest & Test Démo — BotGold AI v2

Objectif : valider l’EA sur **compte démo** avant toute idée de réel.

## 1. Prérequis (PC)

- MetaTrader 5 installé
- Compte **démo** broker (XAUUSD disponible, hedging ou net)
- Fichier `BotGold_AI.mq5` (v2.00) compilé sans erreur

## 2. Installation rapide

1. `Fichier → Ouvrir le dossier de données`
2. Copier `BotGold_AI.mq5` dans `MQL5/Experts/`
3. MetaEditor → ouvrir le fichier → **Compile (F7)**
4. Vérifier : 0 error, 0 warning (ou warnings mineurs acceptables)

## 3. Paramètres recommandés (premier test)

| Paramètre | Valeur test | Pourquoi |
|-----------|-------------|---------|
| InpRiskPercent | 0.5 | Risque faible en démo |
| InpMinContextScore | 58 | Défaut v2 |
| InpMaxTradesPerDay | 3 | Limite R04 |
| InpSkipExtremeFear | true | Filtre anti-foule |
| InpFearGreedProxy | 18 | Aligné dashboard |
| InpUseSessionFilter | true | 7h–21h UTC |
| InpSL_ATR_Mult | 1.5 | Stop ATR |
| InpTP_ATR_Mult | 2.2 | TP ATR |
| InpUseTrailing | true | R03 |

## 4. Stratégie Tester (backtest historique)

1. MT5 → **Stratégie Tester** (Ctrl+R)
2. Expert : `BotGold_AI`
3. Symbole : **XAUUSD**
4. Période : **M5**
5. Dates : 3 à 6 mois récents (ex. derniers 90 jours)
6. Modèle : **1 minute OHLC** (compromis vitesse / réalisme) ou **Every tick** si tu as le temps
7. Dépôt initial : 10 000
8. Levier : celui de ton broker démo (ex. 1:100)
9. Cocher **Visual mode** pour le premier run court

### Ce qu’il faut observer

- Nombre de trades faible (normal : R04 skip beaucoup)
- Pas de martingale (taille de lot stable / proportionnelle au risque)
- Une seule position à la fois (R02)
- Stops qui ne s’élargissent jamais (R03)
- Beaucoup de lignes `SKIP` dans l’onglet Experts

### Résultats “sains” (indicatif)

- Peu de trades (ex. 10–40 sur 3 mois selon marché)
- Ratio SKIP >> TRADE
- Drawdown contrôlé si risque 0.5–1 %
- Pas d’explosion de lots

> Le proxy Fear & Greed de l’EA est **local (RSI)** : il ne reproduit pas l’API alternative.me du dashboard. En live, le comportement sera proche mais pas identique.

## 5. Test live démo (recommandé après backtest)

1. Graphique **XAUUSD M5**
2. Glisser l’EA → cocher **Autoriser le trading algorithmique**
3. AutoTrading **ON** (barre d’outils)
4. Laisser tourner **plusieurs sessions** (Londres / NY)
5. Onglet **Experts** : suivre `SKIP — …` et éventuels `TRADE BUY/SELL`

### Checklist journalière démo

- [ ] Spread XAUUSD raisonnable à l’ouverture
- [ ] Pas plus de 3 trades / jour
- [ ] Commentaire graphique cohérent (SKIP ou position)
- [ ] Capital démo évolue sans comportement aberrant

## 6. Erreurs fréquentes

| Symptôme | Cause probable | Action |
|----------|----------------|--------|
| EA ne trade jamais | Score min trop haut / Extreme Fear proxy / hors session | Baisser temporairement InpMinContextScore à 45, désactiver session filter |
| “symbole non supporté” | Nom broker différent (GOLD, XAUUSDm…) | InpOnlyXAUUSD = false ou renommer symbole |
| Ordres rejetés | Filling mode / stops level | trade.SetTypeFillingBySymbol déjà en place ; vérifier stops level broker |
| Compile error Trade.mqh | Include path MT5 | Utiliser MetaEditor du même MT5 |

## 7. Passage éventuel au réel

Uniquement si :
1. Backtest compréhensible (pas de miracle)
2. ≥ 2 semaines démo live sans comportement dangereux
3. Risque ≤ 0.5–1 % par trade
4. Tu acceptes les pertes

**Disclaimer** : prototype éducatif. Performances passées ≠ futures. Trading = risque de perte totale.
