# BotGold AI — Expert Advisor MT5 (v2.00)

EA anti-martingale contextuel pour **XAUUSD** (MetaTrader 5).

## Installation

1. Ouvre MetaTrader 5 sur PC
2. Menu **Fichier → Ouvrir le dossier de données**
3. Place `BotGold_AI.mq5` dans `MQL5/Experts/`
4. Dans MetaEditor : ouvre le fichier → **Compile** (F7)
5. Sur un graphique **XAUUSD M5** : glisse l’EA depuis le Navigateur
6. Autorise le trading automatisé (bouton AutoTrading)
7. **Compte démo uniquement** pour les premiers tests

## Paramètres principaux

| Paramètre | Défaut | Description |
|-----------|--------|-------------|
| InpRiskPercent | 1.0 | Risque par trade en % du capital |
| InpMinContextScore | 58 | Score minimum pour ouvrir (R04) |
| InpMaxTradesPerDay | 3 | Limite journalière |
| InpSkipExtremeFear | true | Skip fort en Extreme Fear |
| InpFearGreedProxy | 18 | Seuil proxy Fear |
| InpUseSessionFilter | true | Filtre horaires (7h–21h UTC) |
| InpSL_ATR_Mult | 1.5 | Stop = ATR × 1.5 |
| InpTP_ATR_Mult | 2.2 | TP = ATR × 2.2 |

## Les 5 règles

- **R01** — Aucun martingale : lot = risque % / distance SL (ATR)
- **R02** — Aucun grid : une seule position à la fois
- **R03** — Stop jamais élargi : break-even + trailing uniquement
- **R04** — Droit de ne rien faire : skip si score < seuil ou Extreme Fear/Greed
- **R05** — Exécution locale : aucun cloud / mot de passe distant

## Journal

Onglet **Experts** dans MT5 :
- SKIP — Extreme Fear proxy → filtre anti-foule
- TRADE BUY/SELL | Lot=... | Score=... → entrée prise

## Disclaimer

Prototype éducatif. Testez toujours en **démo**.
