# BotGold AI — Premium SaaS Trading Dashboard

Plateforme SaaS anti-martingale contextuelle (XAUUSD / MT5).

## Contenu

```
botgold-ai-saas/
├── index.html              # Dashboard premium (mobile-first)
├── BotGold_AI.mq5          # Expert Advisor MT5 v2
├── README_EA.md
├── backend/                # API FastAPI (historique décisions)
│   ├── main.py
│   ├── requirements.txt
│   └── README.md
├── CAHIER_DES_CHARGES.md
└── README.md
```

## Dashboard

Ouvre `index.html` ou :
**https://raw.githack.com/wiigi0266-boop/botgold-ai-saas/main/index.html**

- Fear & Greed réel (API alternative.me)
- Journal persistant (localStorage)
- Envoi optionnel vers l’API backend

### Brancher l’API (optionnel)

Dans la console navigateur :
```js
localStorage.setItem('botgold_api_url', 'https://ton-api.railway.app')
```

## EA MQL5

Voir `README_EA.md` — compiler dans MetaEditor, attacher sur XAUUSD M5 démo.

## Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

## Les 5 règles

| Code | Règle |
|------|--------|
| R01 | Aucun Martingale |
| R02 | Aucun Grid |
| R03 | Stop jamais élargi |
| R04 | Droit de ne rien faire |
| R05 | Exécution locale MT5 |

## Disclaimer

Prototype éducatif. Aucun ordre réel depuis le dashboard. Trading = risque de perte.
