# BotGold AI — Expert Advisor MT5 (v2.20)

EA anti-martingale contextuel **XAUUSD** + lien dashboard (B).

## v2.20 — Lien Dashboard ↔ EA

1. **Fichier signal** `Common/Files/BotGold_signal.txt`
   - `RUN` | `PAUSE` | `FORCE_SKIP`
2. **POST API** optionnel vers `/decisions` (WebRequest live)
3. CSV `BotGold_tester.csv` (v2.10+)

Voir `GUIDE_LIEN_DASHBOARD_EA.md`.

## Installation

1. `BotGold_AI.mq5` → `MQL5/Experts/` → Compile (F7)
2. Graphique XAUUSD M5 démo → attacher l’EA
3. AutoTrading ON
4. (API) Options → Expert Advisors → autoriser l’URL de l’API

## Paramètres B

| Paramètre | Défaut | Rôle |
|-----------|--------|------|
| InpUseSignalFile | true | Lire signal fichier |
| InpSignalFile | BotGold_signal.txt | Nom du fichier |
| InpPostToApi | false | Envoyer vers API |
| InpApiUrl | (vide) | Base URL API |
| InpWriteCsv | true | Log CSV |

## Règles R01–R05

Inchangées. Le signal web ne peut **pas** forcer un BUY/SELL — seulement pause / skip / run.
