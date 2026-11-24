# BotGold AI — SaaS Dashboard + EA MT5

Anti-martingale contextuel XAUUSD · Règles R01–R05 · Sentiment Fear & Greed

## Contenu

| Fichier | Description |
|---------|-------------|
| `index.html` | Dashboard premium (mobile, localStorage, API optionnelle) |
| `BotGold_AI.mq5` | EA MT5 **v2.20** (CSV + signal fichier + POST API) |
| `README_EA.md` | Installation EA |
| `BotGold_signal.example.txt` | Exemple signal `RUN` / `PAUSE` / `FORCE_SKIP` |
| `main.py` | Backend FastAPI (historique décisions) |
| `requirements.txt` | Dépendances Python |
| `GUIDE_*.md` | Backtest, logs, déploiement API, lien dashboard↔EA |

## Liens utiles

- Dashboard (raw) : https://raw.githack.com/wiigi0266-boop/botgold-ai-saas/main/index.html
- Repo : https://github.com/wiigi0266-boop/botgold-ai-saas

## Démarrage rapide

**Dashboard** — ouvrir `index.html`  
**EA** — compiler dans MetaEditor, attacher sur XAUUSD M5 démo  
**API** — `uvicorn main:app --host 0.0.0.0 --port $PORT`

## Les 5 règles

R01 Aucun martingale · R02 Aucun grid · R03 Stop jamais élargi · R04 Droit de ne rien faire · R05 Exécution locale

## Disclaimer

Prototype éducatif. Aucun ordre réel depuis le dashboard. Trading = risque de perte.
