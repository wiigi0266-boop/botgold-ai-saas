# BotGold AI — Backend API

API minimale pour historiser les décisions **SKIP / TRADE**.

## Lancer en local (PC)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

- Docs interactives : http://127.0.0.1:8000/docs  
- Health : http://127.0.0.1:8000/health  

## Endpoints

| Méthode | Chemin | Description |
|---------|--------|-------------|
| GET | `/health` | Statut |
| POST | `/decisions` | Enregistrer une décision |
| GET | `/decisions` | Liste (filtres `action`, `source`) |
| GET | `/stats` | Totaux SKIP / TRADE |
| DELETE | `/decisions` | Effacer (dev) |

## Exemple POST

```json
{
  "action": "SKIP",
  "symbol": "XAUUSD",
  "fg_score": 11,
  "score": 38,
  "reason": "Extreme Fear — filtre anti-foule R04",
  "rule_hit": "R04",
  "source": "dashboard"
}
```

## Déploiement

Compatible Railway, Render, Fly.io, Vercel (serverless adapter), ou VPS.

Variable optionnelle : `BOTGOLD_DB` (chemin fichier SQLite).
