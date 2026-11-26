# BotGold AI — Mise à jour A + B + C + D

## Contenu
- `index.html` — Dashboard v1.1
  - **A** Stats live depuis `/stats` (badge API Live, refresh 15s)
  - **C** Bouton **Historique API** → charge GET `/decisions?limit=50`
  - **D** Mini stats sous le champ URL + horodatage dernière décision
- `BotGold_AI.mq5` — EA v2.30
  - **B** POST enrichi (price, risk_percent, score, reason, source=ea)
  - URL Railway préremplie
  - InpPostToApi = true par défaut

## Upload dashboard
1. GitHub → botgold-ai-saas → Upload files
2. Remplace `index.html`
3. Commit → recharge https://raw.githack.com/wiigi0266-boop/botgold-ai-saas/main/index.html
4. Vérifie badge **API Live** + mini stats

## EA MT5
1. Copie `BotGold_AI.mq5` dans `MQL5/Experts/`
2. Compile (F7)
3. Options → Expert Advisors → coche **Autoriser WebRequest** et ajoute :
   `https://botgold-ai-saas-production.up.railway.app`
4. Attache sur XAUUSD M5/M15
5. Inputs : InpPostToApi = true, URL déjà remplie

## Vérif
- Dashboard : https://botgold-ai-saas-production.up.railway.app/stats
- Après trades/skips EA → `source: ea` dans GET /decisions
