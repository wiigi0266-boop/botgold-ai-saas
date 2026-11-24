# BotGold AI — Expert Advisor MT5 (v2.10)

EA anti-martingale contextuel pour **XAUUSD**.

## Nouveauté v2.10

Export CSV automatique des décisions SKIP / TRADE :
- Fichier : `Common/Files/BotGold_tester.csv`
- Colonnes : datetime, action, direction, symbol, score, price, lot, sl, tp, reason
- Paramètre : `InpWriteCsv = true` (défaut)

Ouvrir le dossier : MT5 → Fichier → Ouvrir le dossier de données → `Common/Files/`

## Installation

1. Copier `BotGold_AI.mq5` dans `MQL5/Experts/`
2. MetaEditor → Compile (F7)
3. Attacher sur **XAUUSD M5** en **démo**
4. AutoTrading ON

## Paramètres clés

| Paramètre | Défaut | Rôle |
|-----------|--------|------|
| InpRiskPercent | 1.0 | Risque % |
| InpMinContextScore | 58 | Seuil R04 |
| InpMaxTradesPerDay | 3 | Limite journalière |
| InpSkipExtremeFear | true | Filtre fear |
| InpWriteCsv | true | Log CSV |
| InpVerboseLog | true | Onglet Experts |

## Les 5 règles

R01 Aucun martingale · R02 Aucun grid · R03 Stop jamais élargi · R04 Droit de ne rien faire · R05 Exécution locale

## Disclaimer

Prototype éducatif. Testez en démo. Trading = risque de perte.
