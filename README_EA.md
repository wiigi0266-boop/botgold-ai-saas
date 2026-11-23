# BotGold AI — Expert Advisor MQL5

EA Advisor anti-martingale contextuel pour **XAUUSD** (MetaTrader 5).

## Les 5 règles intégrées

| Code | Règle | Implémentation |
|------|-------|----------------|
| **R01** | Aucun Martingale | Taille = ATR × risque % uniquement (`CalcLotSize`) |
| **R02** | Aucun Grid | Une seule position à la fois (`CountOurPositions`) |
| **R03** | Stop jamais élargi | Trailing + Break-even uniquement (`ManageOpenPosition`) |
| **R04** | Droit de ne rien faire | Score contexte < seuil → SKIP (`EvaluateContext`) |
| **R05** | Exécution locale | Tourne uniquement dans le MT5 de l’utilisateur |

## Installation

1. Ouvre MetaTrader 5
2. `Fichier` → `Ouvrir le dossier de données`
3. Copie `BotGold_AI.mq5` dans `MQL5/Experts/`
4. Dans MT5 : `Navigateur` → clic droit `Experts` → `Actualiser`
5. Compile (F7 dans MetaEditor)
6. Glisse l’EA sur un graphique **XAUUSD** (M5 recommandé)

## Paramètres principaux

- **InpRiskPercent** : risque par trade (défaut 1 %)
- **InpMinContextScore** : score minimum pour ouvrir (défaut 55)
- **InpSL_ATR_Mult / InpTP_ATR_Mult** : stops basés sur ATR H1
- **InpUseTrailing** : break-even + trailing (jamais élargir le SL)
- **InpMaxTradesPerDay** : limite de fréquence

## Fonctionnement

1. Nouvelle bougie M5
2. Calcul score multi-TF (M5 / M15 / H1 / H4)
3. Si score ≥ seuil et direction claire → calcul lot ATR + risque %
4. Ouverture avec SL/TP fixes
5. Gestion : BE puis trailing (R03)

## Avertissement

Prototype éducatif. Testez d’abord en **compte démo**.  
Le trading à effet de levier comporte un risque de perte totale du capital.
