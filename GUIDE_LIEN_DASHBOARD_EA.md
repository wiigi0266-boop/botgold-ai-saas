# B — Lien Dashboard ↔ EA (BotGold AI v2.20)

Deux canaux complémentaires, sans cloud obligatoire pour le trading (R05).

```
┌─────────────┐     localStorage      ┌──────────────┐
│  Dashboard  │ ───────────────────►  │  Navigateur  │
│  (web)      │                       └──────────────┘
└──────┬──────┘
       │ POST /decisions (optionnel)
       ▼
┌─────────────┐
│  API FastAPI│  ◄── WebRequest POST (optionnel, EA live)
│  main.py    │
└─────────────┘
       ▲
       │ source: "ea" | "dashboard"
┌──────┴──────┐     Common/Files/
│  EA MT5     │ ◄── BotGold_signal.txt  (PAUSE | FORCE_SKIP | RUN)
│  v2.20      │ ──► BotGold_tester.csv
└─────────────┘
```

## 1. Fichier signal (contrôle depuis l’extérieur)

**Fichier** : `Common/Files/BotGold_signal.txt`  
(MT5 → Fichier → Ouvrir le dossier de données → `Common/Files/`)

**Contenu** (une seule ligne, majuscules) :

| Contenu | Effet |
|---------|--------|
| `RUN` | Trading normal (défaut si fichier absent) |
| `PAUSE` | Aucune nouvelle entrée (trailing R03 continue) |
| `FORCE_SKIP` | Skip forcé à chaque barre M5 + log CSV |

### Exemple

Crée un fichier texte :

```text
PAUSE
```

Sauvegarde sous `BotGold_signal.txt` dans `Common/Files/`.  
L’EA lit le fichier à chaque tick ; repasse à `RUN` pour reprendre.

Utile pour : pause manuelle, bridge depuis un script, ou futur bouton dashboard qui écrit ce fichier via un agent local.

## 2. API partagée (historique unifié)

### Côté dashboard

```js
localStorage.setItem('botgold_api_url', 'https://TON-URL.up.railway.app')
```

Chaque **Analyser** envoie un POST `/decisions` si l’URL est définie.

### Côté EA (live uniquement, pas en Strategy Tester)

Paramètres EA :

| Paramètre | Valeur |
|-----------|--------|
| InpPostToApi | true |
| InpApiUrl | `https://TON-URL.up.railway.app` (sans `/` final) |

**Autoriser l’URL dans MT5** :

1. Outils → Options → Expert Advisors  
2. Cocher **Autoriser WebRequest pour les URL listées**  
3. Ajouter exactement l’URL de base (ex. `https://xxx.up.railway.app`)

Vérifier : `GET /stats` doit montrer des `source: "ea"` et `"dashboard"`.

## 3. CSV local (toujours disponible)

`Common/Files/BotGold_tester.csv` — SKIP et TRADE de l’EA, même sans API.

## 4. Ce que le lien ne fait pas (volontairement)

- Le dashboard **n’envoie pas d’ordres** au broker (R05, sécurité)
- L’EA **n’exécute pas** un signal BUY/SELL venant du web (évite le piratage)
- Seuls **PAUSE / FORCE_SKIP / RUN** sont acceptés depuis le fichier signal

Architecture **consultation + frein d’urgence**, pas de trading télécommandé.

## 5. Checklist activation B

- [ ] `main.py` déployé ou testé en local (`/health` OK)
- [ ] Dashboard : `botgold_api_url` renseigné
- [ ] EA v2.20 compilé
- [ ] `InpUseSignalFile = true`
- [ ] (Option) `InpPostToApi = true` + URL autorisée dans MT5
- [ ] Test : écrire `PAUSE` → Comment graphique = pause
- [ ] Test : `RUN` → reprise

## Disclaimer

Prototype éducatif. Toute connexion réseau (WebRequest) doit rester sous ton contrôle. Ne place jamais de mot de passe broker dans le dashboard ou l’API.
