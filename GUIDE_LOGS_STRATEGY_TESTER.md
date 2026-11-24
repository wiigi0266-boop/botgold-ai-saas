# Explorer les logs Strategy Tester — BotGold AI v2

## Où regarder dans MT5

| Onglet | Contenu |
|--------|---------|
| **Journal** | Messages système MT5 (connexion, ticks, erreurs terminal) |
| **Experts** | Tout ce que l’EA écrit avec `Print()` / `LogSkip` / erreurs trade |
| **Results** | Tableau des ordres (si des trades ont été pris) |
| **Graph** | Courbe d’équité + deals sur le graphique (mode visuel) |
| **Report** | Rapport HTML exportable |

Pendant un test : bas de la fenêtre Strategy Tester → onglets **Journal** / **Experts**.

---

## Activer les logs utiles

1. Strategy Tester → **Settings** (engrenage) ou propriétés de l’EA  
2. Cocher **InpVerboseLog = true** (défaut v2)  
3. Mode **Visual** pour voir `Comment()` sur le graphique en direct  
4. Après le run : clic droit dans **Experts** → **Open** pour le fichier `.log`

Fichiers logs MT5 (PC) :
```
[Dossier données MT5]/Logs\YYYYMMDD.log
[Dossier données MT5]\Tester\logs\
```

`Fichier → Ouvrir le dossier de données` pour y accéder.

---

## Messages BotGold à reconnaître

### Démarrage (normal)
```
BotGold AI v2.00 initialisé
R01 Aucun Martingale | R02 Aucun Grid
R03 Stop jamais élargi | R04 Droit de ne rien faire
R05 Exécution locale | Risque 1.0%
Score min: 58 | Max trades/j: 3
```

### SKIP (attendu souvent)
```
BotGold AI | SKIP — Extreme Fear proxy (12) — filtre anti-foule R04
BotGold AI | SKIP — Contexte insuffisant (score=41 < 58) — ...
BotGold AI | SKIP — RSI multi-TF non alignés avec tendance H4 ...
BotGold AI | SKIP — Hors session (3h UTC)
BotGold AI | SKIP — Limite journalière atteinte (3)
BotGold AI | SKIP — Spread trop large (52.0 pts)
BotGold AI | SKIP — Volatilité excessive (ATR 1.15%)
```

### TRADE (rare si filtres stricts)
```
BotGold AI | TRADE BUY | Lot=0.08 | SL=2610.20 | TP=2645.10 | Score=72 | BUY | Align RSI | F&G proxy=44 | ATR%=0.31
BotGold AI | TRADE SELL | Lot=0.05 | ...
```

### Erreurs à surveiller
```
BotGold AI | Échec ordre : 10016 Invalid stops
BotGold AI | Échec ordre : 10030 Unsupported filling mode
BotGold AI : symbole non supporté (EURUSD)
BotGold AI : échec création des indicateurs
```

---

## Méthode d’exploration (pas à pas)

### 1. Run court visuel
- Dates : 5–10 jours récents  
- Visual mode **ON**  
- Vitesse moyenne  
- Observer le **Comment** en haut à gauche du graphique : `SKIP — …` ou `TRADE …`

### 2. Filtrer dans Experts
- Après le test, onglet **Experts**  
- Chercher (Ctrl+F) : `TRADE` → compter les entrées  
- Chercher : `SKIP` → voir les raisons dominantes  
- Chercher : `Échec` → corriger broker / stops / filling

### 3. Lire le ratio SKIP / TRADE
Comportement **sain** BotGold :
- Beaucoup de SKIP (R04 + Extreme Fear proxy)
- Peu de TRADE (ex. quelques unités sur des semaines)
- Aucune série de lots croissants (pas de martingale)

Comportement **suspect** :
- 0 log Experts → EA pas chargé / mauvais symbole / compile error  
- Que des échecs d’ordre → stops level ou filling mode  
- Trades en boucle chaque barre → bug (ne doit pas arriver en v2)

### 4. Export pour analyse
1. Strategy Tester → **Results** → clic droit → **Save as Report** (HTML)  
2. Ou copier les lignes Experts dans un fichier texte  
3. Compter :
   - lignes `TRADE BUY` / `TRADE SELL`
   - lignes `SKIP — Extreme Fear`
   - lignes `Contexte insuffisant`

### 5. Rapport HTML — colonnes clés
- **Profit** / **Drawdown**
- **Total trades** (doit rester bas)
- **Average profit / average loss**
- Pas de colonne “lot martingale” : lots doivent rester cohérents avec le risque %

---

## Interprétation rapide

| Ce que tu vois | Signification |
|----------------|---------------|
| SKIP Extreme Fear en boucle | Normal en marché stressé (proxy RSI bas) |
| Score toujours < 58 | Marché sans alignement multi-TF ; R04 travaille |
| TRADE puis BE/trailing | R03 actif (regarde modifications de SL dans Results) |
| Hors session | Filtre 7h–21h UTC ; élargir ou désactiver pour test 24h |
| Spread trop large | Tester sur période liquidité Londres/NY |

---

## Astuce : log fichier dédié (option avancée)

Pour un dump plus propre en backtest, on peut ajouter plus tard :
```mql5
int h = FileOpen("BotGold_tester.csv", FILE_WRITE|FILE_CSV|FILE_COMMON, ';');
FileWrite(h, TimeToString(TimeCurrent()), action, score, reason);
FileClose(h);
```
Fichier dans `Common\Files\BotGold_tester.csv`.

---

## Checklist “logs OK”

- [ ] Bannière v2.00 à l’init  
- [ ] Alternance SKIP avec raisons lisibles  
- [ ] Si TRADE : une ligne claire Lot / SL / TP / Score  
- [ ] Pas d’erreur 10016/10030 en masse  
- [ ] Results : nombre de deals ≈ nombre de lignes TRADE  
- [ ] InpVerboseLog = true pour le diagnostic  

**Disclaimer** : le proxy Fear & Greed du tester est basé RSI, pas l’API alternative.me du dashboard.
