# BotGold AI — Premium SaaS Trading Dashboard

Plateforme SaaS professionnelle reproduisant la stratégie **anti-martingale contextuelle** (XAUUSD / MT5).

![Status](https://img.shields.io/badge/status-prototype-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

## Contenu du dépôt

```
botgold-ai-saas/
├── dashboard/
│   └── index.html              # Dashboard premium (mobile-first)
├── mql5/
│   ├── BotGold_AI.mq5          # Expert Advisor MT5
│   └── README_EA.md            # Guide installation EA
├── docs/
│   ├── CAHIER_DES_CHARGES.md   # Spécifications techniques
│   └── Cahier_des_Charges_BotGold_AI.pdf
└── README.md
```

## Démarrage rapide (Dashboard)

1. Ouvre `dashboard/index.html` dans Chrome / Firefox / Safari  
2. Le Fear & Greed se charge via API publique  
3. Appuie sur le bouton **éclair** pour lancer une analyse  

Fonctionne sur mobile Android.

## Expert Advisor MQL5

Voir [`mql5/README_EA.md`](mql5/README_EA.md).

1. Copier `BotGold_AI.mq5` dans `MQL5/Experts/`
2. Compiler (F7) dans MetaEditor
3. Attacher sur graphique **XAUUSD M5** en compte **démo**

## Les 5 règles inviolables

| Code | Règle |
|------|--------|
| R01 | Aucun Martingale — sizing ATR + risque % uniquement |
| R02 | Aucun Grid — une seule position à la fois |
| R03 | Stop jamais élargi — trailing + break-even seulement |
| R04 | Droit de ne rien faire — skip si contexte insuffisant |
| R05 | Exécution locale — aucun mot de passe cloud |

## Fonctionnalités dashboard

- Fear & Greed Index réel (API alternative.me) + historique 14j  
- Sentiment Or / News-Social corrélés  
- Graphique style TradingView (chandeliers / ligne / area)  
- Moteur de décision multi-TF + filtre anti-foule  
- Journal des décisions (SKIP / TRADE)  
- Paramètres de risque (capital + %)  
- UI mobile-first premium  

## Disclaimer

Prototype **éducatif**. Aucun ordre réel n’est envoyé depuis le dashboard.  
Le trading à effet de levier comporte un risque de perte totale du capital.  
Testez toujours l’EA en compte démo avant toute utilisation réelle.

## Licence

MIT
