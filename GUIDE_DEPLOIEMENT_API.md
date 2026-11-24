# Guide déploiement API BotGold — Railway & Render

Backend FastAPI : historisation SKIP / TRADE.

Fichiers nécessaires (dossier `backend/`) :
- `main.py`
- `requirements.txt`

---

## Option 1 — Railway (recommandé, simple)

### Étapes

1. Crée un compte sur [https://railway.app](https://railway.app)
2. **New Project** → **Deploy from GitHub repo**
3. Autorise Railway → choisis `botgold-ai-saas`
4. **Root Directory** : `backend` (important si les fichiers sont dans `/backend`)
   - Si `main.py` est à la racine du repo, laisse Root Directory vide
5. Railway détecte Python. Ajoute si besoin la **Start Command** :
   ```bash
   uvicorn main:app --host 0.0.0.0 --port $PORT
   ```
6. Variables (optionnel) :
   - `BOTGOLD_DB` = `/data/botgold.db` (si volume persistant)
7. **Deploy** → attends le build
8. Onglet **Settings → Networking → Generate Domain**
9. URL du type : `https://botgold-api-production-xxxx.up.railway.app`

### Test

```
https://TON-URL.up.railway.app/health
→ {"status":"ok", ...}

https://TON-URL.up.railway.app/docs
→ Swagger interactif
```

### Brancher le dashboard

Sur le téléphone, ouvre le dashboard → console Chrome (si possible) ou via un petit bookmark :

```js
localStorage.setItem('botgold_api_url', 'https://TON-URL.up.railway.app')
```

Puis relance une analyse : les décisions partent vers l’API (en plus du localStorage).

---

## Option 2 — Render

1. Compte sur [https://render.com](https://render.com)
2. **New → Web Service**
3. Connecte le repo GitHub `botgold-ai-saas`
4. Paramètres :
   - **Root Directory** : `backend`
   - **Runtime** : Python 3
   - **Build Command** : `pip install -r requirements.txt`
   - **Start Command** : `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Instance **Free** suffit pour tester
6. Create Web Service → URL `https://xxx.onrender.com`

> Note free tier : l’app s’endort après inactivité (~15 min). Le premier appel peut être lent.

---

## Structure repo idéale pour le déploiement

```
botgold-ai-saas/
├── backend/
│   ├── main.py
│   └── requirements.txt
├── index.html
├── BotGold_AI.mq5
└── ...
```

Si chez toi les fichiers backend sont encore à la racine, deux solutions :
- Créer le dossier `backend/` sur GitHub et y mettre `main.py` + `requirements.txt`
- Ou déployer avec Root Directory = `/` et Start Command inchangée

---

## Endpoints utiles

| Méthode | Chemin | Usage |
|---------|--------|--------|
| GET | `/health` | Ping |
| GET | `/docs` | Documentation |
| POST | `/decisions` | Enregistrer |
| GET | `/decisions` | Historique |
| GET | `/stats` | SKIP vs TRADE |

### Exemple curl

```bash
curl -X POST https://TON-URL/decisions \
  -H "Content-Type: application/json" \
  -d '{"action":"SKIP","fg_score":11,"reason":"Extreme Fear R04","source":"dashboard"}'
```

---

## Dépannage

| Problème | Solution |
|----------|----------|
| Build fail `uvicorn not found` | Vérifier `requirements.txt` contient `uvicorn[standard]` |
| 404 sur `/` | Normal si tu n’as pas ouvert `/health` ou `/docs` |
| CORS | Déjà ouvert (`allow_origins=["*"]`) dans `main.py` |
| DB perdue au redeploy | Ajouter un volume persistant (Railway) ou passer plus tard à Postgres |

---

## Suite possible

- Auth simple (clé API dans header)
- Postgres à la place de SQLite
- Webhook depuis l’EA MT5 (WebRequest) vers `/decisions`
